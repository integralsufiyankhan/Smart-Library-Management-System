<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="DB.DBDatabaseConnection" %>
<%
    // ---------- SESSION CHECK ----------
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=2");
        return;
    }

    String adminName = (String) session.getAttribute("adminName");
    if (adminName == null) adminName = "Admin";

    String search = request.getParameter("book_number");
    if (search == null) search = "";
    search = search.trim();

    // Result variables
    boolean searched = !search.isEmpty();
    boolean bookFound = false;
    boolean hasActiveLoans = false;

    String bNum = "", bTitle = "", bAuthor = "";
    int bTotal = 0, bAvail = 0, bIssued = 0;

    // List of members holding this book
    java.util.List<String[]> holders = new java.util.ArrayList<String[]>();

    String errMsg = "";

    if (searched) {
        try {
            DBDatabaseConnection db = new DBDatabaseConnection();

            // ---------- FETCH BOOK ----------
            db.pstmt = db.con.prepareStatement(
                "SELECT book_number, title, author, total_copies, available_copies " +
                "FROM books WHERE book_number = ? OR title LIKE ? LIMIT 1");
            db.pstmt.setString(1, search);
            db.pstmt.setString(2, "%" + search + "%");
            db.rst = db.pstmt.executeQuery();

            if (db.rst.next()) {
                bookFound = true;
                bNum   = db.rst.getString("book_number");
                bTitle = db.rst.getString("title");
                bAuthor = db.rst.getString("author");
                bTotal = db.rst.getInt("total_copies");
                bAvail = db.rst.getInt("available_copies");
                bIssued = bTotal - bAvail;

                // ---------- FETCH HOLDERS (active loans) ----------
                PreparedStatement ps2 = db.con.prepareStatement(
                    "SELECT m.member_id, m.name, m.email, br.issue_date, br.due_date " +
                    "FROM borrowing_records br " +
                    "JOIN members m ON br.member_id = m.member_id " +
                    "WHERE br.book_number = ? AND br.return_date IS NULL " +
                    "ORDER BY br.issue_date");
                ps2.setString(1, bNum);
                ResultSet rs2 = ps2.executeQuery();

                java.time.LocalDate today = java.time.LocalDate.now();

                while (rs2.next()) {
                    hasActiveLoans = true;
                    java.sql.Date dueSql = rs2.getDate("due_date");
                    java.time.LocalDate due = dueSql.toLocalDate();
                    long overdueDays = 0;
                    if (today.isAfter(due)) {
                        overdueDays = java.time.temporal.ChronoUnit.DAYS.between(due, today);
                    }

                    holders.add(new String[]{
                        rs2.getString("member_id"),
                        rs2.getString("name"),
                        rs2.getString("email"),
                        rs2.getDate("issue_date").toString(),
                        dueSql.toString(),
                        String.valueOf(overdueDays)
                    });
                }
            }
            db.con.close();
        } catch (Exception e) {
            errMsg = e.getMessage();
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Check Availability - Library Management System</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Segoe UI', Tahoma, Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding-bottom: 40px;
        }

        /* ---------- NAVBAR ---------- */
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
        .nav-right span {
            color: #4a3f8f;
            font-size: 14px;
            font-weight: 600;
        }
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

        /* ---------- CONTAINER ---------- */
        .container {
            max-width: 750px;
            margin: 0 auto;
            padding: 0 20px;
        }

        .card {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 15px 50px rgba(0,0,0,0.25);
            overflow: hidden;
        }

        .card-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            padding: 25px 30px;
            text-align: center;
        }
        .card-header h2 { font-size: 22px; margin-bottom: 5px; }
        .card-header p { font-size: 13px; opacity: 0.9; }

        /* ---------- SEARCH FORM ---------- */
        .search-form {
            padding: 25px 30px;
            background: #f9f9ff;
            border-bottom: 1px solid #e0e0ea;
            display: flex;
            gap: 10px;
        }
        .search-form input {
            flex: 1;
            padding: 12px 16px;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            font-size: 15px;
            transition: 0.3s;
            background: #fff;
        }
        .search-form input:focus {
            border-color: #667eea;
            outline: none;
            box-shadow: 0 0 0 4px rgba(102,126,234,0.15);
        }
        .search-form button {
            padding: 12px 26px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            border: none;
            border-radius: 10px;
            font-weight: 700;
            font-size: 14px;
            cursor: pointer;
            transition: 0.3s;
        }
        .search-form button:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 18px rgba(102,126,234,0.4);
        }

        /* ---------- RESULT BOX ---------- */
        .result { padding: 25px 30px 30px; }

        .book-header {
            display: flex;
            gap: 20px;
            align-items: center;
            padding: 20px;
            border-radius: 12px;
            background: linear-gradient(135deg, #f9f9ff 0%, #eef1ff 100%);
            border: 2px solid #e0e0ea;
            margin-bottom: 20px;
        }
        .book-icon {
            width: 70px;
            height: 70px;
            border-radius: 12px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 34px;
            flex-shrink: 0;
        }
        .book-info h3 {
            color: #4a3f8f;
            font-size: 20px;
            margin-bottom: 5px;
        }
        .book-info p {
            color: #666;
            font-size: 14px;
            margin-bottom: 3px;
        }
        .book-info .book-num {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 15px;
            background: #4a3f8f;
            color: #fff;
            font-size: 12px;
            font-weight: 700;
            margin-bottom: 8px;
        }

        /* ---------- STATS GRID ---------- */
        .stats {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 12px;
            margin-bottom: 20px;
        }
        .stat {
            text-align: center;
            padding: 18px 10px;
            border-radius: 12px;
            background: #f9f9ff;
            border: 2px solid #e0e0ea;
            transition: 0.3s;
        }
        .stat .num {
            font-size: 26px;
            font-weight: 800;
            margin-bottom: 4px;
        }
        .stat .lbl {
            font-size: 11px;
            color: #777;
            text-transform: uppercase;
            letter-spacing: 1px;
            font-weight: 700;
        }
        .stat.total .num { color: #4a3f8f; }
        .stat.issued .num { color: #e74c3c; }
        .stat.avail .num { color: #27ae60; }

        .status-badge {
            display: inline-block;
            padding: 10px 22px;
            border-radius: 30px;
            font-weight: 700;
            font-size: 14px;
            margin-bottom: 20px;
        }
        .status-badge.ok   { background: #d4edda; color: #155724; }
        .status-badge.low  { background: #fff3cd; color: #856404; }
        .status-badge.out  { background: #f8d7da; color: #721c24; }

        /* ---------- TABLE ---------- */
        .table-title {
            font-size: 14px;
            color: #4a3f8f;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 10px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
            border-radius: 10px;
            overflow: hidden;
        }
        thead th {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            padding: 12px 12px;
            text-align: left;
            font-weight: 600;
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        tbody td {
            padding: 12px;
            border-bottom: 1px solid #eee;
        }
        tbody tr:hover { background: #f9f9ff; }

        .badge {
            padding: 3px 10px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 700;
        }
        .badge-ok   { background: #d4edda; color: #155724; }
        .badge-over { background: #f8d7da; color: #721c24; }

        /* ---------- EMPTY / NOT FOUND ---------- */
        .empty {
            padding: 50px 30px;
            text-align: center;
            color: #888;
        }
        .empty .icon { font-size: 60px; margin-bottom: 15px; }
        .empty h3 { color: #4a3f8f; margin-bottom: 8px; }
        .empty p { font-size: 14px; }

        .notfound {
            padding: 40px 30px;
            text-align: center;
            background: #fff5f5;
            border-top: 3px solid #e74c3c;
        }
        .notfound .icon { font-size: 50px; margin-bottom: 12px; }
        .notfound h3 { color: #c0392b; margin-bottom: 5px; font-size: 18px; }
        .notfound p { color: #721c24; font-size: 14px; }

        .err-msg {
            padding: 15px 20px;
            background: #f8d7da;
            color: #721c24;
            border-radius: 10px;
            margin: 20px 30px;
            font-weight: 600;
            font-size: 14px;
            border-left: 5px solid #dc3545;
        }
    </style>
</head>
<body>

    <!-- NAVBAR -->
    <div class="navbar">
        <h1>📚 Library Management System</h1>
        <div class="nav-right">
            <span>👤 <%= adminName %></span>
            <a href="index.html" class="nav-btn home">🏠 Home</a>
            <a href="logout.jsp" class="nav-btn logout">Logout</a>
        </div>
    </div>

    <!-- MAIN CARD -->
    <div class="container">
        <div class="card">
            <div class="card-header">
                <h2>🔍 Check Availability</h2>
                <p>Search a book by its number or title</p>
            </div>

            <!-- SEARCH FORM -->
            <form class="search-form" action="checkAvailability.jsp" method="get">
                <input type="text" name="book_number"
                       placeholder="🔍 Enter Book Number (e.g. BK001) or Title"
                       value="<%= search %>" required>
                <button type="submit">Check</button>
            </form>

            <% if (!errMsg.isEmpty()) { %>
                <div class="err-msg">Error: <%= errMsg %></div>
            <% } %>

            <!-- RESULT -->
            <%
                if (searched && bookFound) {
                    String statusClass, statusText;
                    if (bAvail == 0) {
                        statusClass = "out";
                        statusText  = "❌ OUT OF STOCK — All copies issued";
                    } else if (bAvail <= 1) {
                        statusClass = "low";
                        statusText  = "⚠️ LOW STOCK — Only " + bAvail + " copy left";
                    } else {
                        statusClass = "ok";
                        statusText  = "✅ AVAILABLE — " + bAvail + " copies on shelf";
                    }
            %>
                <div class="result">

                    <div class="status-badge <%= statusClass %>"><%= statusText %></div>

                    <!-- BOOK HEADER -->
                    <div class="book-header">
                        <div class="book-icon">📖</div>
                        <div class="book-info">
                            <span class="book-num"><%= bNum %></span>
                            <h3><%= bTitle %></h3>
                            <p>✍️ By <%= bAuthor %></p>
                        </div>
                    </div>

                    <!-- STATS -->
                    <div class="stats">
                        <div class="stat total">
                            <div class="num"><%= bTotal %></div>
                            <div class="lbl">Total Copies</div>
                        </div>
                        <div class="stat issued">
                            <div class="num"><%= bIssued %></div>
                            <div class="lbl">Issued</div>
                        </div>
                        <div class="stat avail">
                            <div class="num"><%= bAvail %></div>
                            <div class="lbl">Available</div>
                        </div>
                    </div>

                    <!-- HOLDERS TABLE -->
                    <% if (hasActiveLoans) { %>
                        <div class="table-title">👥 Currently Held By (<%= holders.size() %> member<%= holders.size() > 1 ? "s" : "" %>)</div>
                        <table>
                            <thead>
                                <tr>
                                    <th>Member ID</th>
                                    <th>Name</th>
                                    <th>Email</th>
                                    <th>Issued On</th>
                                    <th>Due Date</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                            <% for (String[] h : holders) {
                                 long od = Long.parseLong(h[5]);
                                 boolean isOver = od > 0;
                            %>
                                <tr>
                                    <td><strong><%= h[0] %></strong></td>
                                    <td><%= h[1] %></td>
                                    <td><%= h[2] %></td>
                                    <td><%= h[3] %></td>
                                    <td><%= h[4] %></td>
                                    <td>
                                        <% if (isOver) { %>
                                            <span class="badge badge-over">Overdue by <%= od %>d</span>
                                        <% } else { %>
                                            <span class="badge badge-ok">On Time</span>
                                        <% } %>
                                    </td>
                                </tr>
                            <% } %>
                            </tbody>
                        </table>
                    <% } else { %>
                        <div style="text-align:center;padding:25px;background:#f0fff4;border-radius:10px;color:#1e8449;font-weight:600;font-size:14px;">
                            🎉 No active loans — all copies are on the shelf!
                        </div>
                    <% } %>
                </div>

            <% } else if (searched && !bookFound) { %>
                <div class="notfound">
                    <div class="icon">❌</div>
                    <h3>No Book Found</h3>
                    <p>Koi book nahi mili "<strong><%= search %></strong>" ke liye.</p>
                    <p style="margin-top:10px;color:#888;font-size:13px;">
                        Book Number ya Title sahi se likha hai? Check karo.
                    </p>
                </div>
            <% } else { %>
                <div class="empty">
                    <div class="icon">🔍</div>
                    <h3>Search a Book</h3>
                    <p>Book Number (e.g. <strong>BK001</strong>) ya Title (e.g. <strong>Java</strong>) daalo.</p>
                </div>
            <% } %>

        </div>
    </div>

</body>
</html>