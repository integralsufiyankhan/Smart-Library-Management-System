<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="DB.DBDatabaseConnection" %>
<%!
    public String highlightText(String text, String q) {
        if (text == null || q == null || q.trim().isEmpty()) return text;
        String[] words = q.toLowerCase().split("\\s+");
        String result = text;
        for (int w = 0; w < words.length; w++) {
            String word = words[w];
            if (word.length() < 2) continue;
            String lower = result.toLowerCase();
            int idx = lower.indexOf(word);
            while (idx >= 0) {
                String before = result.substring(0, idx);
                String match = result.substring(idx, idx + word.length());
                String after = result.substring(idx + word.length());
                result = before + "<mark>" + match + "</mark>" + after;
                lower = result.toLowerCase();
                idx = lower.indexOf(word, idx + word.length() + 13);
            }
        }
        return result;
    }
%>
<%
    // ---------- SESSION CHECK ----------
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=2");
        return;
    }

    String adminName = (String) session.getAttribute("adminName");
    if (adminName == null) adminName = "Admin";

    String query = request.getParameter("q");
    if (query == null) query = "";
    query = query.trim();

    String member_id = request.getParameter("member_id");
    if (member_id == null) member_id = "";
    member_id = member_id.trim();

    String categoryFilter = request.getParameter("category");
    if (categoryFilter == null) categoryFilter = "All";

    List<String[]> results = new ArrayList<String[]>();
    int resultCount = 0;
    long searchTime = 0;
    String memberName = "";

    // ---------- FETCH SELECTED MEMBER NAME ----------
    if (!member_id.isEmpty()) {
        try {
            DBDatabaseConnection dbM = new DBDatabaseConnection();
            dbM.pstmt = dbM.con.prepareStatement("SELECT name FROM members WHERE member_id = ?");
            dbM.pstmt.setString(1, member_id);
            dbM.rst = dbM.pstmt.executeQuery();
            if (dbM.rst.next()) memberName = dbM.rst.getString("name");
            dbM.con.close();
        } catch (Exception e) { }
    }

    // ---------- PERFORM SEARCH ----------
    if (!query.isEmpty()) {
        long startTime = System.currentTimeMillis();
        try {
            DBDatabaseConnection db = new DBDatabaseConnection();

            String[] words = query.toLowerCase().split("\\s+");

            StringBuilder sql = new StringBuilder();
            sql.append("SELECT book_number, title, author, category, avg_rating, ");
            sql.append("       total_copies, available_copies, ");

            StringBuilder scorePart = new StringBuilder("(");
            boolean firstScore = true;
            for (int i = 0; i < words.length; i++) {
                if (words[i].length() < 2) continue;
                if (!firstScore) scorePart.append(" + ");
                firstScore = false;
                scorePart.append("(CASE WHEN LOWER(title) LIKE ? THEN 10 ELSE 0 END)");
                scorePart.append(" + (CASE WHEN LOWER(author) LIKE ? THEN 6 ELSE 0 END)");
                scorePart.append(" + (CASE WHEN LOWER(description) LIKE ? THEN 2 ELSE 0 END)");
                scorePart.append(" + (CASE WHEN LOWER(title) = ? THEN 15 ELSE 0 END)");
            }
            scorePart.append(")");
            sql.append(scorePart.toString()).append(" AS score ");
            sql.append("FROM books WHERE 1=1 ");

            sql.append(" AND (");
            boolean firstWhere = true;
            for (int i = 0; i < words.length; i++) {
                if (words[i].length() < 2) continue;
                if (!firstWhere) sql.append(" OR ");
                firstWhere = false;
                sql.append("LOWER(title) LIKE ? OR LOWER(author) LIKE ? OR LOWER(description) LIKE ?");
            }
            sql.append(") ");

            if (!"All".equals(categoryFilter)) {
                sql.append(" AND category = ? ");
            }

            sql.append("ORDER BY score DESC, avg_rating DESC LIMIT 30");

            db.pstmt = db.con.prepareStatement(sql.toString());

            int idx = 1;
            for (int i = 0; i < words.length; i++) {
                if (words[i].length() < 2) continue;
                String like = "%" + words[i] + "%";
                db.pstmt.setString(idx++, like);
                db.pstmt.setString(idx++, like);
                db.pstmt.setString(idx++, like);
                db.pstmt.setString(idx++, words[i]);
            }
            for (int i = 0; i < words.length; i++) {
                if (words[i].length() < 2) continue;
                String like = "%" + words[i] + "%";
                db.pstmt.setString(idx++, like);
                db.pstmt.setString(idx++, like);
                db.pstmt.setString(idx++, like);
            }
            if (!"All".equals(categoryFilter)) {
                db.pstmt.setString(idx++, categoryFilter);
            }

            db.rst = db.pstmt.executeQuery();
            while (db.rst.next()) {
                results.add(new String[]{
                    db.rst.getString("book_number"),
                    db.rst.getString("title"),
                    db.rst.getString("author"),
                    db.rst.getString("category") == null ? "General" : db.rst.getString("category"),
                    String.valueOf(db.rst.getDouble("avg_rating")),
                    String.valueOf(db.rst.getInt("available_copies")),
                    String.valueOf(db.rst.getInt("total_copies")),
                    String.valueOf(db.rst.getDouble("score"))
                });
            }
            resultCount = results.size();

            // ---------- SAVE TO SEARCH HISTORY ----------
            if (!member_id.isEmpty()) {
                try {
                    PreparedStatement psH = db.con.prepareStatement(
                        "INSERT INTO search_history (member_id, query, result_count) VALUES (?, ?, ?)");
                    psH.setString(1, member_id);
                    psH.setString(2, query);
                    psH.setInt(3, resultCount);
                    psH.executeUpdate();
                } catch (Exception e) { }
            }

            db.con.close();
        } catch (Exception e) {
            out.println("<div style='padding:20px;background:#f8d7da;color:#721c24;border-radius:10px;margin-bottom:20px;'>Search Error: " + e.getMessage() + "</div>");
        }
        searchTime = System.currentTimeMillis() - startTime;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Smart Search - Library Management System</title>
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
        .nav-btn.hist { background: #f39c12; }
        .nav-btn.hist:hover { background: #e67e22; }
        .nav-btn.logout { background: #e74c3c; }
        .nav-btn.logout:hover { background: #c0392b; }

        .container { max-width: 1100px; margin: 0 auto; padding: 0 20px; }

        .search-hero {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 15px 50px rgba(0,0,0,0.25);
            overflow: hidden;
            margin-bottom: 25px;
        }
        .search-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            padding: 30px;
            text-align: center;
        }
        .search-header h2 { font-size: 28px; margin-bottom: 8px; letter-spacing: 0.5px; }
        .search-header p { font-size: 14px; opacity: 0.9; }

        .search-body { padding: 25px 30px; }

        .member-strip {
            background: #f0f4ff;
            border-left: 4px solid #667eea;
            padding: 12px 18px;
            border-radius: 10px;
            margin-bottom: 18px;
            display: flex;
            gap: 12px;
            align-items: center;
            flex-wrap: wrap;
        }
        .member-strip label {
            font-weight: 700;
            font-size: 13px;
            color: #4a3f8f;
            white-space: nowrap;
        }
        .member-strip select {
            flex: 1;
            min-width: 240px;
            padding: 10px 14px;
            border: 2px solid #c5cae9;
            border-radius: 10px;
            font-size: 14px;
            background: #fff;
            transition: 0.3s;
            cursor: pointer;
        }
        .member-strip select:focus {
            border-color: #667eea;
            outline: none;
            box-shadow: 0 0 0 4px rgba(102,126,234,0.15);
        }
        .member-strip .info-icon {
            font-size: 12px;
            color: #666;
            font-style: italic;
        }
        .member-strip .active-tag {
            background: #27ae60;
            color: #fff;
            padding: 4px 12px;
            border-radius: 15px;
            font-size: 12px;
            font-weight: 700;
        }

        .search-form { display: flex; gap: 10px; margin-bottom: 15px; flex-wrap: wrap; }
        .search-form .big-input {
            flex: 1;
            min-width: 280px;
            padding: 15px 20px;
            border: 2px solid #e0e0e0;
            border-radius: 12px;
            font-size: 16px;
            background: #f9f9ff;
            transition: 0.3s;
        }
        .search-form .big-input:focus {
            border-color: #667eea;
            outline: none;
            background: #fff;
            box-shadow: 0 0 0 4px rgba(102,126,234,0.15);
        }
        .search-form .btn-search {
            padding: 15px 35px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            border: none;
            border-radius: 12px;
            font-weight: 700;
            font-size: 16px;
            cursor: pointer;
            transition: 0.3s;
        }
        .search-form .btn-search:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 20px rgba(102,126,234,0.4);
        }

        .search-filters { display: flex; gap: 10px; flex-wrap: wrap; align-items: center; }
        .search-filters select {
            padding: 10px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            font-size: 14px;
            background: #fff;
            transition: 0.3s;
        }
        .search-filters select:focus { border-color: #667eea; outline: none; }
        .search-filters .hint-icon { font-size: 12px; color: #888; margin-left: auto; }

        .suggestions {
            margin-top: 15px;
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
            align-items: center;
        }
        .suggestions .lbl {
            font-size: 12px;
            color: #888;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-right: 5px;
        }
        .suggestion-tag {
            padding: 6px 14px;
            background: #eef1ff;
            color: #4a3f8f;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            text-decoration: none;
            transition: 0.3s;
            border: 1px solid #c5cae9;
        }
        .suggestion-tag:hover { background: #667eea; color: #fff; border-color: #667eea; }

        .results-header {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 15px 50px rgba(0,0,0,0.2);
            padding: 20px 30px;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 10px;
        }
        .results-header .info { font-size: 14px; color: #4a3f8f; font-weight: 600; }
        .results-header .info strong { color: #667eea; font-size: 18px; }
        .results-header .time-badge {
            background: #eef1ff;
            color: #4a3f8f;
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 700;
        }
        .results-header .btn-history {
            background: #f39c12;
            color: #fff;
            padding: 8px 18px;
            border-radius: 20px;
            text-decoration: none;
            font-size: 13px;
            font-weight: 700;
            transition: 0.3s;
        }
        .results-header .btn-history:hover { background: #e67e22; }

        .result-card {
            background: #fff;
            border-radius: 14px;
            box-shadow: 0 8px 25px rgba(0,0,0,0.12);
            padding: 22px 25px;
            margin-bottom: 15px;
            transition: 0.3s;
            border-left: 5px solid #667eea;
            display: flex;
            gap: 20px;
            align-items: flex-start;
        }
        .result-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 12px 35px rgba(102,126,234,0.2);
        }
        .result-rank {
            flex-shrink: 0;
            width: 50px;
            height: 50px;
            border-radius: 12px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 800;
            font-size: 18px;
            box-shadow: 0 6px 15px rgba(102,126,234,0.35);
        }
        .result-body { flex: 1; min-width: 0; }
        .result-title {
            font-size: 18px;
            color: #4a3f8f;
            font-weight: 700;
            margin-bottom: 6px;
            text-decoration: none;
            display: block;
            line-height: 1.3;
        }
        .result-title:hover { color: #667eea; }
        .result-author { font-size: 13px; color: #888; margin-bottom: 10px; }
        .result-badges { display: flex; gap: 8px; flex-wrap: wrap; align-items: center; margin-bottom: 10px; }

        .cat-badge {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 700;
            background: #eef1ff;
            color: #4a3f8f;
            border: 1px solid #c5cae9;
        }
        .cat-Programming { background: #dbeafe; color: #1e40af; border-color: #93c5fd; }
        .cat-Fiction { background: #fce7f3; color: #9d174d; border-color: #f9a8d4; }
        .cat-Biography { background: #fef3c7; color: #92400e; border-color: #fcd34d; }
        .cat-NonFiction { background: #e0f2fe; color: #075985; border-color: #7dd3fc; }
        .cat-SelfHelp { background: #d1fae5; color: #065f46; border-color: #6ee7b7; }
        .cat-General { background: #ede9fe; color: #5b21b6; border-color: #c4b5fd; }

        .stars { color: #f39c12; font-size: 13px; letter-spacing: 1px; }
        .stars .empty { color: #ddd; }
        .rating-num { font-size: 12px; color: #666; font-weight: 700; margin-left: 4px; }

        .stock-badge {
            padding: 3px 10px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 700;
        }
        .stock-ok   { background: #d4edda; color: #155724; }
        .stock-low  { background: #fff3cd; color: #856404; }
        .stock-out  { background: #f8d7da; color: #721c24; }

        .score-bar-wrap {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-top: 8px;
            font-size: 11px;
            color: #888;
        }
        .score-bar {
            flex: 1;
            height: 5px;
            background: #eee;
            border-radius: 3px;
            overflow: hidden;
        }
        .score-fill {
            height: 100%;
            background: linear-gradient(90deg, #667eea, #764ba2);
            border-radius: 3px;
        }

        mark {
            background: #fff3cd;
            color: #856404;
            padding: 0 3px;
            border-radius: 3px;
            font-weight: 700;
        }

        .no-results {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 15px 50px rgba(0,0,0,0.2);
            padding: 60px 30px;
            text-align: center;
        }
        .no-results .icon { font-size: 70px; margin-bottom: 15px; }
        .no-results h2 { color: #4a3f8f; margin-bottom: 8px; font-size: 22px; }
        .no-results p { color: #666; font-size: 14px; margin-bottom: 8px; }
        .no-results .tip {
            color: #888;
            font-size: 13px;
            background: #f9f9ff;
            padding: 12px 20px;
            border-radius: 10px;
            display: inline-block;
            margin-top: 15px;
            border-left: 4px solid #667eea;
        }

        .welcome-state {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 15px 50px rgba(0,0,0,0.2);
            padding: 60px 30px;
            text-align: center;
        }
        .welcome-state .icon { font-size: 80px; margin-bottom: 15px; }
        .welcome-state h2 { color: #4a3f8f; margin-bottom: 8px; }
        .welcome-state p { color: #666; font-size: 14px; }
    </style>
</head>
<body>

    <div class="navbar">
        <h1>📚 Library Management System</h1>
        <div class="nav-right">
            <span>👤 <%= adminName %></span>
            <a href="searchHistory.jsp" class="nav-btn hist">🕓 History</a>
            <a href="index.html" class="nav-btn home">🏠 Home</a>
            <a href="logout.jsp" class="nav-btn logout">Logout</a>
        </div>
    </div>

    <div class="container">

        <div class="search-hero">
            <div class="search-header">
                <h2>🔍 Smart Book Search</h2>
                <p>Search across titles, authors &amp; descriptions — with weighted ranking</p>
            </div>
            <div class="search-body">

                <!-- MEMBER STRIP -->
                <div class="member-strip">
                    <label>👤 Searching as:</label>
                    <select id="memberSelect" onchange="updateMember(this.value)">
                        <option value="">-- Guest (not tracked) --</option>
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
                    <% if (!member_id.isEmpty()) { %>
                        <span class="active-tag">✅ Tracking <%= memberName %></span>
                    <% } else { %>
                        <span class="info-icon">💡 Member select karoge to search history me save hogi</span>
                    <% } %>
                </div>

                <!-- SEARCH FORM -->
                <form class="search-form" action="searchBooks.jsp" method="get" id="searchForm">
                    <input type="hidden" name="member_id" id="memberIdField" value="<%= member_id %>">
                    <input type="text" name="q" class="big-input"
                           placeholder="🔍 Search books, authors, topics..."
                           value="<%= query %>" required autofocus>
                    <button type="submit" class="btn-search">Search →</button>
                </form>

                <div class="search-filters">
                    <form action="searchBooks.jsp" method="get" style="display:flex; gap:10px; align-items:center; flex:1; flex-wrap:wrap;">
                        <input type="hidden" name="q" value="<%= query %>">
                        <input type="hidden" name="member_id" value="<%= member_id %>">
                        <select name="category" onchange="this.form.submit();">
                            <option value="All" <%= "All".equals(categoryFilter) ? "selected" : "" %>>All Categories</option>
                            <option value="Programming" <%= "Programming".equals(categoryFilter) ? "selected" : "" %>>Programming</option>
                            <option value="Fiction" <%= "Fiction".equals(categoryFilter) ? "selected" : "" %>>Fiction</option>
                            <option value="Non-Fiction" <%= "Non-Fiction".equals(categoryFilter) ? "selected" : "" %>>Non-Fiction</option>
                            <option value="Biography" <%= "Biography".equals(categoryFilter) ? "selected" : "" %>>Biography</option>
                            <option value="Self-Help" <%= "Self-Help".equals(categoryFilter) ? "selected" : "" %>>Self-Help</option>
                            <option value="Science" <%= "Science".equals(categoryFilter) ? "selected" : "" %>>Science</option>
                            <option value="History" <%= "History".equals(categoryFilter) ? "selected" : "" %>>History</option>
                            <option value="Indian Authors" <%= "Indian Authors".equals(categoryFilter) ? "selected" : "" %>>Indian Authors</option>
                            <option value="Children" <%= "Children".equals(categoryFilter) ? "selected" : "" %>>Children</option>
                            <option value="General" <%= "General".equals(categoryFilter) ? "selected" : "" %>>General</option>
                        </select>
                        <span class="hint-icon">💡 Weighted ranking: title > author > description</span>
                    </form>
                </div>

                <div class="suggestions">
                    <span class="lbl">Try:</span>
                    <a href="javascript:quickSearch('java')" class="suggestion-tag">java</a>
                    <a href="javascript:quickSearch('programming')" class="suggestion-tag">programming</a>
                    <a href="javascript:quickSearch('code')" class="suggestion-tag">code</a>
                    <a href="javascript:quickSearch('kalam')" class="suggestion-tag">kalam</a>
                    <a href="javascript:quickSearch('habits')" class="suggestion-tag">habits</a>
                    <a href="javascript:quickSearch('book')" class="suggestion-tag">book</a>
                </div>
            </div>
        </div>

        <% if (query.isEmpty()) { %>
            <div class="welcome-state">
                <div class="icon">🔍</div>
                <h2>Search Books</h2>
                <p>Upar search box me kuch type karo — title, author ya description.</p>
            </div>
        <% } else if (resultCount == 0) { %>
            <div class="no-results">
                <div class="icon">📭</div>
                <h2>No Results Found</h2>
                <p>"<strong><%= query %></strong>" ke liye koi book nahi mili.</p>
                <div class="tip">
                    💡 <strong>Try:</strong> Different keywords, spelling check, or remove category filter
                </div>
            </div>
        <% } else {
            double maxScore = 1.0;
            for (int i = 0; i < results.size(); i++) {
                double sc = Double.parseDouble(results.get(i)[7]);
                if (sc > maxScore) maxScore = sc;
            }
        %>

            <div class="results-header">
                <div class="info">
                    Found <strong><%= resultCount %></strong> result<%= resultCount != 1 ? "s" : "" %>
                    for "<%= query %>"
                    <% if (!"All".equals(categoryFilter)) { %>
                        in <strong><%= categoryFilter %></strong>
                    <% } %>
                    <% if (!member_id.isEmpty()) { %>
                        · tracked for <strong><%= memberName %></strong> ✅
                    <% } %>
                </div>
                <div style="display:flex;gap:10px;align-items:center;flex-wrap:wrap;">
                    <span class="time-badge">⚡ <%= searchTime %> ms</span>
                    <a href="searchHistory.jsp" class="btn-history">🕓 View History</a>
                </div>
            </div>

            <%
                int rank = 0;
                for (int r = 0; r < results.size(); r++) {
                    String[] row = results.get(r);
                    rank++;
                    String bNum = row[0];
                    String bTitle = row[1];
                    String bAuthor = row[2];
                    String bCat = row[3];
                    double bRating = Double.parseDouble(row[4]);
                    int bAvail = Integer.parseInt(row[5]);
                    int bTotal = Integer.parseInt(row[6]);
                    double bScore = Double.parseDouble(row[7]);

                    int fullStars = (int) Math.round(bRating);
                    StringBuilder stars = new StringBuilder();
                    for (int s = 1; s <= 5; s++) {
                        stars.append(s <= fullStars ? "★" : "<span class='empty'>★</span>");
                    }
                    String catClass = "cat-" + bCat.replace("-", "").replace(" ", "");
                    String stockClass, stockText;
                    if (bAvail == 0) { stockClass = "stock-out"; stockText = "Out of Stock"; }
                    else if (bAvail <= 1) { stockClass = "stock-low"; stockText = "Low Stock"; }
                    else { stockClass = "stock-ok"; stockText = "Available"; }

                    double scorePct = (bScore / maxScore) * 100;
            %>
                <div class="result-card">
                    <div class="result-rank">#<%= rank %></div>
                    <div class="result-body">
                        <a href="bookDetails.jsp?book_number=<%= bNum %>" class="result-title">
                            <%= highlightText(bTitle, query) %>
                        </a>
                        <div class="result-author">
                            ✍️ by <%= highlightText(bAuthor, query) %>
                            <span style="color:#bbb;margin-left:8px;">·</span>
                            <span style="color:#999;font-size:12px;margin-left:8px;"><%= bNum %></span>
                        </div>
                        <div class="result-badges">
                            <span class="cat-badge <%= catClass %>"><%= bCat %></span>
                            <span class="stars"><%= stars.toString() %></span>
                            <% if (bRating > 0) { %>
                                <span class="rating-num"><%= String.format("%.1f", bRating) %></span>
                            <% } %>
                            <span class="stock-badge <%= stockClass %>"><%= stockText %> (<%= bAvail %>/<%= bTotal %>)</span>
                        </div>
                        <div class="score-bar-wrap">
                            <span>Relevance:</span>
                            <div class="score-bar">
                                <div class="score-fill" style="width:<%= String.format("%.0f", scorePct) %>%"></div>
                            </div>
                            <span><%= String.format("%.1f", bScore) %></span>
                        </div>
                    </div>
                </div>
            <% } %>
        <% } %>

    </div>

    <script>
        // Update member_id in the form when dropdown changes
        function updateMember(val) {
            document.getElementById('memberIdField').value = val;
            // Auto-submit if already searched
            <% if (!query.isEmpty()) { %>
                document.getElementById('searchForm').submit();
            <% } %>
        }

        // Quick search with current member
        function quickSearch(q) {
            var m = document.getElementById('memberIdField').value;
            window.location.href = 'searchBooks.jsp?q=' + encodeURIComponent(q) + '&member_id=' + m;
        }
    </script>

</body>
</html>