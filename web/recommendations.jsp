<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="DB.DBDatabaseConnection" %>
<%
    // ---------- SESSION CHECK ----------
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=2");
        return;
    }

    String adminName = (String) session.getAttribute("adminName");
    if (adminName == null) adminName = "Admin";

    // Selected member
    String member_id = request.getParameter("member_id");
    if (member_id == null) member_id = "";
    member_id = member_id.trim();

    // Member info
    String memberName = "";
    boolean memberFound = false;

    // Recommendation buckets
    List<String[]> collaborative = new ArrayList<String[]>();
    List<String[]> contentBased  = new ArrayList<String[]>();
    List<String[]> popular       = new ArrayList<String[]>();

    // ---------- FETCH MEMBER ----------
    if (!member_id.isEmpty()) {
        try {
            DBDatabaseConnection db = new DBDatabaseConnection();
            db.pstmt = db.con.prepareStatement("SELECT name FROM members WHERE member_id = ?");
            db.pstmt.setString(1, member_id);
            db.rst = db.pstmt.executeQuery();
            if (db.rst.next()) {
                memberFound = true;
                memberName = db.rst.getString("name");
            }
            db.con.close();
        } catch (Exception e) { }
    }

    // ---------- FETCH RECOMMENDATIONS ----------
    if (memberFound) {
        try {
            DBDatabaseConnection db = new DBDatabaseConnection();

            // ---------- 1. GET MEMBER'S BORROWED BOOKS ----------
            Set<String> myBooks = new HashSet<String>();
            Set<String> myCategories = new HashSet<String>();

            PreparedStatement ps1 = db.con.prepareStatement(
                "SELECT DISTINCT br.book_number, b.category " +
                "FROM borrowing_records br " +
                "JOIN books b ON br.book_number = b.book_number " +
                "WHERE br.member_id = ?");
            ps1.setString(1, member_id);
            ResultSet rs1 = ps1.executeQuery();
            while (rs1.next()) {
                myBooks.add(rs1.getString("book_number"));
                String cat = rs1.getString("category");
                if (cat != null && !cat.isEmpty()) myCategories.add(cat);
            }

            // ---------- 2. COLLABORATIVE FILTERING ----------
            if (!myBooks.isEmpty()) {
                StringBuilder inClause = new StringBuilder();
                for (int i = 0; i < myBooks.size(); i++) {
                    if (i > 0) inClause.append(",");
                    inClause.append("?");
                }

                String similarSql = 
                    "SELECT br.member_id, COUNT(*) AS common " +
                    "FROM borrowing_records br " +
                    "WHERE br.book_number IN (" + inClause + ") " +
                    "  AND br.member_id != ? " +
                    "GROUP BY br.member_id " +
                    "HAVING common >= 1 " +
                    "ORDER BY common DESC LIMIT 5";

                PreparedStatement psSim = db.con.prepareStatement(similarSql);
                int idxSim = 1;
                for (String b : myBooks) psSim.setString(idxSim++, b);
                psSim.setString(idxSim, member_id);

                List<String> similarMembers = new ArrayList<String>();
                ResultSet rsSim = psSim.executeQuery();
                while (rsSim.next()) {
                    similarMembers.add(rsSim.getString("member_id"));
                }

                // Step B: Get books those similar members borrowed (that I haven't)
                if (!similarMembers.isEmpty()) {
                    StringBuilder simIn = new StringBuilder();
                    for (int i = 0; i < similarMembers.size(); i++) {
                        if (i > 0) simIn.append(",");
                        simIn.append("?");
                    }
                    StringBuilder notIn = new StringBuilder();
                    for (int i = 0; i < myBooks.size(); i++) {
                        if (i > 0) notIn.append(",");
                        notIn.append("?");
                    }

                    String collabSql = 
                        "SELECT b.book_number, b.title, b.author, b.avg_rating, b.category, " +
                        "       COUNT(*) AS freq " +
                        "FROM borrowing_records br " +
                        "JOIN books b ON br.book_number = b.book_number " +
                        "WHERE br.member_id IN (" + simIn + ") " +
                        "  AND br.book_number NOT IN (" + notIn + ") " +
                        "GROUP BY b.book_number, b.title, b.author, b.avg_rating, b.category " +
                        "ORDER BY freq DESC, b.avg_rating DESC LIMIT 6";

                    PreparedStatement psCol = db.con.prepareStatement(collabSql);
                    int idxCol = 1;
                    for (String sm : similarMembers) psCol.setString(idxCol++, sm);
                    for (String mb : myBooks) psCol.setString(idxCol++, mb);

                    ResultSet rsCol = psCol.executeQuery();
                    while (rsCol.next()) {
                        collaborative.add(new String[]{
                            rsCol.getString("book_number"),
                            rsCol.getString("title"),
                            rsCol.getString("author"),
                            String.valueOf(rsCol.getDouble("avg_rating")),
                            rsCol.getString("category") == null ? "General" : rsCol.getString("category"),
                            "Users with similar taste borrowed this"
                        });
                    }
                }
            }

            // ---------- 3. CONTENT-BASED (Same category) ----------
            if (!myCategories.isEmpty()) {
                StringBuilder catIn = new StringBuilder();
                for (int i = 0; i < myCategories.size(); i++) {
                    if (i > 0) catIn.append(",");
                    catIn.append("?");
                }
                StringBuilder notIn = new StringBuilder();
                if (!myBooks.isEmpty()) {
                    for (int i = 0; i < myBooks.size(); i++) {
                        if (i > 0) notIn.append(",");
                        notIn.append("?");
                    }
                }

                String contentSql = 
                    "SELECT book_number, title, author, avg_rating, category " +
                    "FROM books " +
                    "WHERE category IN (" + catIn + ") ";

                if (!myBooks.isEmpty()) {
                    contentSql += " AND book_number NOT IN (" + notIn + ") ";
                }
                contentSql += " ORDER BY avg_rating DESC, RAND() LIMIT 6";

                PreparedStatement psCont = db.con.prepareStatement(contentSql);
                int idxCont = 1;
                for (String c : myCategories) psCont.setString(idxCont++, c);
                if (!myBooks.isEmpty()) {
                    for (String b : myBooks) psCont.setString(idxCont++, b);
                }

                ResultSet rsCont = psCont.executeQuery();
                while (rsCont.next()) {
                    String cat = rsCont.getString("category");
                    contentBased.add(new String[]{
                        rsCont.getString("book_number"),
                        rsCont.getString("title"),
                        rsCont.getString("author"),
                        String.valueOf(rsCont.getDouble("avg_rating")),
                        cat == null ? "General" : cat,
                        "Because you like " + (cat == null ? "similar" : cat) + " books"
                    });
                }
            }

            // ---------- 4. POPULAR BOOKS (Fallback) ----------
            String popularSql = 
                "SELECT b.book_number, b.title, b.author, b.avg_rating, b.category, " +
                "       COUNT(br.record_id) AS borrows " +
                "FROM books b " +
                "LEFT JOIN borrowing_records br ON b.book_number = br.book_number " +
                "GROUP BY b.book_number, b.title, b.author, b.avg_rating, b.category " +
                "ORDER BY borrows DESC, b.avg_rating DESC " +
                "LIMIT 6";

            ResultSet rsPop = db.con.createStatement().executeQuery(popularSql);
            while (rsPop.next()) {
                int borrows = rsPop.getInt("borrows");
                popular.add(new String[]{
                    rsPop.getString("book_number"),
                    rsPop.getString("title"),
                    rsPop.getString("author"),
                    String.valueOf(rsPop.getDouble("avg_rating")),
                    rsPop.getString("category") == null ? "General" : rsPop.getString("category"),
                    borrows + " time" + (borrows != 1 ? "s" : "") + " borrowed"
                });
            }

            db.con.close();
        } catch (Exception e) {
            out.println("<div style='padding:20px;background:#f8d7da;color:#721c24;border-radius:10px;margin-bottom:20px;'>Error: " + e.getMessage() + "</div>");
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Recommendations - Library Management System</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Segoe UI', Tahoma, Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding-bottom: 40px;
        }

        .navbar {
            background: rgba(255,255,255,0.97);
            padding: 15px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 2px 15px rgba(0,0,0,0.15);
            margin-bottom: 30px;
        }
        .navbar h1 { font-size: 20px; color: #4a3f8f; }
        .nav-right { display: flex; gap: 10px; align-items: center; }
        .nav-right span { color: #4a3f8f; font-size: 14px; font-weight: 600; }
        .nav-btn {
            padding: 8px 18px;
            border-radius: 20px;
            text-decoration: none;
            font-size: 14px;
            font-weight: 600;
            transition: 0.3s;
            color: #fff;
        }
        .nav-btn.home { background: #667eea; }
        .nav-btn.home:hover { background: #4a3f8f; }
        .nav-btn.logout { background: #e74c3c; }
        .nav-btn.logout:hover { background: #c0392b; }

        .container { max-width: 1200px; margin: 0 auto; padding: 0 20px; }

        .select-card {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 15px 50px rgba(0,0,0,0.25);
            overflow: hidden;
            margin-bottom: 25px;
        }
        .select-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            padding: 25px 30px;
        }
        .select-header h2 { font-size: 22px; margin-bottom: 5px; }
        .select-header p { font-size: 13px; opacity: 0.9; }
        .select-body { padding: 25px 30px; }
        .select-form {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        .select-form select {
            flex: 1;
            min-width: 250px;
            padding: 12px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            font-size: 15px;
            background: #f9f9ff;
            transition: 0.3s;
        }
        .select-form select:focus {
            border-color: #667eea;
            outline: none;
            background: #fff;
            box-shadow: 0 0 0 4px rgba(102,126,234,0.1);
        }
        .btn-primary {
            padding: 12px 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            border: none;
            border-radius: 10px;
            font-weight: 700;
            font-size: 15px;
            cursor: pointer;
            transition: 0.3s;
        }
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 20px rgba(102,126,234,0.4);
        }

        .member-hero {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 15px 50px rgba(0,0,0,0.25);
            padding: 25px 30px;
            margin-bottom: 25px;
            display: flex;
            align-items: center;
            gap: 20px;
        }
        .member-avatar {
            width: 70px;
            height: 70px;
            border-radius: 50%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 30px;
            font-weight: 800;
            box-shadow: 0 8px 25px rgba(102,126,234,0.4);
        }
        .member-hero h2 { color: #4a3f8f; font-size: 22px; margin-bottom: 4px; }
        .member-hero p { color: #666; font-size: 14px; }

        .section-card {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 15px 50px rgba(0,0,0,0.25);
            overflow: hidden;
            margin-bottom: 25px;
        }
        .section-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            padding: 20px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 10px;
        }
        .section-header h2 { font-size: 18px; }
        .section-header .badge {
            background: rgba(255,255,255,0.25);
            padding: 4px 14px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 700;
        }
        .section-header.collab {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
        }
        .section-header.content {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        }
        .section-header.popular {
            background: linear-gradient(135deg, #fa709a 0%, #fee140 100%);
        }

        .rec-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 15px;
            padding: 25px 30px;
        }

        .rec-card {
            background: #f9f9ff;
            border: 2px solid #e0e0ea;
            border-radius: 12px;
            padding: 18px;
            text-decoration: none;
            transition: 0.3s;
            display: block;
            position: relative;
            overflow: hidden;
        }
        .rec-card:hover {
            border-color: #667eea;
            transform: translateY(-4px);
            box-shadow: 0 12px 30px rgba(102,126,234,0.25);
            background: #fff;
        }

        .rec-card .book-icon {
            font-size: 34px;
            margin-bottom: 10px;
        }
        .rec-card .rec-title {
            font-size: 15px;
            font-weight: 700;
            color: #4a3f8f;
            margin-bottom: 5px;
            line-height: 1.3;
        }
        .rec-card .rec-author {
            font-size: 12px;
            color: #888;
            margin-bottom: 8px;
        }
        .rec-card .rec-stars {
            color: #f39c12;
            font-size: 13px;
            letter-spacing: 1px;
            margin-bottom: 8px;
        }
        .rec-card .rec-stars .empty { color: #ddd; }

        .cat-badge {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 12px;
            font-size: 10px;
            font-weight: 700;
            background: #eef1ff;
            color: #4a3f8f;
            border: 1px solid #c5cae9;
            margin-bottom: 8px;
        }
        .cat-Programming { background: #dbeafe; color: #1e40af; border-color: #93c5fd; }
        .cat-Fiction { background: #fce7f3; color: #9d174d; border-color: #f9a8d4; }
        .cat-Biography { background: #fef3c7; color: #92400e; border-color: #fcd34d; }
        .cat-NonFiction { background: #e0f2fe; color: #075985; border-color: #7dd3fc; }
        .cat-SelfHelp { background: #d1fae5; color: #065f46; border-color: #6ee7b7; }
        .cat-General { background: #ede9fe; color: #5b21b6; border-color: #c4b5fd; }

        .rec-reason {
            font-size: 11px;
            color: #666;
            background: #fff8e1;
            padding: 6px 10px;
            border-radius: 6px;
            border-left: 3px solid #f39c12;
            margin-top: 10px;
            font-style: italic;
            line-height: 1.4;
        }
        .rec-card.popular .rec-reason {
            background: #fff3e0;
            border-left-color: #e67e22;
        }
        .rec-card.collab .rec-reason {
            background: #fce4ec;
            border-left-color: #e91e63;
        }

        .empty-msg {
            padding: 40px 30px;
            text-align: center;
            color: #888;
        }
        .empty-msg .icon { font-size: 50px; margin-bottom: 10px; }
        .empty-msg h3 { color: #4a3f8f; margin-bottom: 6px; }
        .empty-msg p { font-size: 13px; }

        .no-member {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 15px 50px rgba(0,0,0,0.25);
            padding: 60px 30px;
            text-align: center;
        }
        .no-member .icon { font-size: 70px; margin-bottom: 15px; }
        .no-member h2 { color: #4a3f8f; margin-bottom: 8px; }
        .no-member p { color: #666; font-size: 14px; }
    </style>
</head>
<body>

    <div class="navbar">
        <h1>📚 Library Management System</h1>
        <div class="nav-right">
            <span>👤 <%= adminName %></span>
            <a href="index.html" class="nav-btn home">🏠 Home</a>
            <a href="logout.jsp" class="nav-btn logout">Logout</a>
        </div>
    </div>

    <div class="container">

        <!-- MEMBER SELECTOR -->
        <div class="select-card">
            <div class="select-header">
                <h2>🎯 Book Recommendations</h2>
                <p>Personalized suggestions based on borrowing history</p>
            </div>
            <div class="select-body">
                <form class="select-form" action="recommendations.jsp" method="get">
                    <select name="member_id" required>
                        <option value="">-- Select a Member --</option>
                        <%
                            try {
                                DBDatabaseConnection dbSel = new DBDatabaseConnection();
                                dbSel.rst = dbSel.con.createStatement().executeQuery(
                                    "SELECT member_id, name FROM members ORDER BY name");
                                while (dbSel.rst.next()) {
                                    String mid = dbSel.rst.getString("member_id");
                                    String mn = dbSel.rst.getString("name");
                        %>
                            <option value="<%= mid %>" <%= mid.equals(member_id) ? "selected" : "" %>>
                                <%= mn %> (<%= mid %>)
                            </option>
                        <%
                                }
                                dbSel.con.close();
                            } catch (Exception e) { }
                        %>
                    </select>
                    <button type="submit" class="btn-primary">Get Recommendations →</button>
                </form>
            </div>
        </div>

        <% if (!memberFound) { %>
            <div class="no-member">
                <div class="icon">🎯</div>
                <h2>Select a Member</h2>
                <p>Upar dropdown se koi member select karo aur personalized recommendations dekho.</p>
            </div>
        <% } else {
            String initial = memberName != null && !memberName.isEmpty()
                             ? memberName.substring(0, 1).toUpperCase() : "?";
        %>

            <!-- MEMBER HERO -->
            <div class="member-hero">
                <div class="member-avatar"><%= initial %></div>
                <div>
                    <h2><%= memberName %></h2>
                    <p>🆔 <%= member_id %> · Personalized recommendations below</p>
                </div>
            </div>

            <!-- 1. COLLABORATIVE -->
            <div class="section-card">
                <div class="section-header collab">
                    <h2>🎯 Collaborative Recommendations</h2>
                    <span class="badge"><%= collaborative.size() %> books</span>
                </div>
                <% if (collaborative.isEmpty()) { %>
                    <div class="empty-msg">
                        <div class="icon">🤝</div>
                        <h3>Not Enough Data</h3>
                        <p>Is member ke liye abhi collaborative recommendations nahi hain. Jab ye aur books lega, recommendations aayengi.</p>
                    </div>
                <% } else { %>
                    <div class="rec-grid">
                        <% for (String[] r : collaborative) {
                            double rr = Double.parseDouble(r[3]);
                            int fullStars = (int) Math.round(rr);
                            StringBuilder rStars = new StringBuilder();
                            for (int s = 1; s <= 5; s++) rStars.append(s <= fullStars ? "★" : "<span class='empty'>★</span>");
                            String catClass = "cat-" + r[4].replace("-", "").replace(" ", "");
                        %>
                            <a href="bookDetails.jsp?book_number=<%= r[0] %>" class="rec-card collab">
                                <div class="book-icon">📚</div>
                                <div class="rec-title"><%= r[1] %></div>
                                <div class="rec-author">✍️ <%= r[2] %></div>
                                <span class="cat-badge <%= catClass %>"><%= r[4] %></span>
                                <div class="rec-stars"><%= rStars.toString() %></div>
                                <div class="rec-reason">🎯 <%= r[5] %></div>
                            </a>
                        <% } %>
                    </div>
                <% } %>
            </div>

            <!-- 2. CONTENT-BASED -->
            <div class="section-card">
                <div class="section-header content">
                    <h2>📂 Based on Your Interests</h2>
                    <span class="badge"><%= contentBased.size() %> books</span>
                </div>
                <% if (contentBased.isEmpty()) { %>
                    <div class="empty-msg">
                        <div class="icon">📂</div>
                        <h3>No Category Matches</h3>
                        <p>Is member ki borrowed categories ke hisaab se koi book nahi mili.</p>
                    </div>
                <% } else { %>
                    <div class="rec-grid">
                        <% for (String[] r : contentBased) {
                            double rr = Double.parseDouble(r[3]);
                            int fullStars = (int) Math.round(rr);
                            StringBuilder rStars = new StringBuilder();
                            for (int s = 1; s <= 5; s++) rStars.append(s <= fullStars ? "★" : "<span class='empty'>★</span>");
                            String catClass = "cat-" + r[4].replace("-", "").replace(" ", "");
                        %>
                            <a href="bookDetails.jsp?book_number=<%= r[0] %>" class="rec-card">
                                <div class="book-icon">📖</div>
                                <div class="rec-title"><%= r[1] %></div>
                                <div class="rec-author">✍️ <%= r[2] %></div>
                                <span class="cat-badge <%= catClass %>"><%= r[4] %></span>
                                <div class="rec-stars"><%= rStars.toString() %></div>
                                <div class="rec-reason">📂 <%= r[5] %></div>
                            </a>
                        <% } %>
                    </div>
                <% } %>
            </div>

        <% } %>

        <!-- 3. POPULAR BOOKS -->
        <div class="section-card">
            <div class="section-header popular">
                <h2>🔥 Trending / Popular Books</h2>
                <span class="badge">Most borrowed</span>
            </div>
            <% if (popular.isEmpty()) { %>
                <div class="empty-msg">
                    <div class="icon">📭</div>
                    <h3>No Books Yet</h3>
                    <p>Abhi tak koi book borrow nahi hui.</p>
                </div>
            <% } else { %>
                <div class="rec-grid">
                    <% for (String[] r : popular) {
                        double rr = Double.parseDouble(r[3]);
                        int fullStars = (int) Math.round(rr);
                        StringBuilder rStars = new StringBuilder();
                        for (int s = 1; s <= 5; s++) rStars.append(s <= fullStars ? "★" : "<span class='empty'>★</span>");
                        String catClass = "cat-" + r[4].replace("-", "").replace(" ", "");
                    %>
                        <a href="bookDetails.jsp?book_number=<%= r[0] %>" class="rec-card popular">
                            <div class="book-icon">🔥</div>
                            <div class="rec-title"><%= r[1] %></div>
                            <div class="rec-author">✍️ <%= r[2] %></div>
                            <span class="cat-badge <%= catClass %>"><%= r[4] %></span>
                            <div class="rec-stars"><%= rStars.toString() %></div>
                            <div class="rec-reason">🔥 <%= r[5] %></div>
                        </a>
                    <% } %>
                </div>
            <% } %>
        </div>

    </div>

</body>
</html>