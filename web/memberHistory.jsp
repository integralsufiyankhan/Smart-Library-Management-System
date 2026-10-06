<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.temporal.ChronoUnit" %>
<%@ page import="DB.DBDatabaseConnection" %>
<%
    // ---------- SESSION CHECK ----------
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=2");
        return;
    }

    String adminName = (String) session.getAttribute("adminName");
    if (adminName == null) adminName = "Admin";

    // ---------- MEMBER ID ----------
    String member_id = request.getParameter("member_id");
    if (member_id == null || member_id.trim().isEmpty()) {
        response.sendRedirect("listMembers.jsp");
        return;
    }
    member_id = member_id.trim();

    LocalDate today = LocalDate.now();

    // Member info
    String mName = "", mEmail = "";
    boolean memberFound = false;

    // Stats
    int totalLoans = 0;
    int activeLoans = 0;
    int returnedLoans = 0;
    int overdueLoans = 0;
    double totalFines = 0;

    // ---------- FETCH MEMBER INFO ----------
    try {
        DBDatabaseConnection db = new DBDatabaseConnection();
        db.pstmt = db.con.prepareStatement("SELECT name, email FROM members WHERE member_id = ?");
        db.pstmt.setString(1, member_id);
        db.rst = db.pstmt.executeQuery();
        if (db.rst.next()) {
            memberFound = true;
            mName = db.rst.getString("name");
            mEmail = db.rst.getString("email");
        }
        db.con.close();
    } catch (Exception e) { }

    if (!memberFound) {
        response.sendRedirect("listMembers.jsp?msg=notfound");
        return;
    }

    String initial = mName != null && !mName.isEmpty() ? mName.substring(0, 1).toUpperCase() : "?";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Member History - Library Management System</title>
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
        .nav-btn.back { background: #3498db; }
        .nav-btn.back:hover { background: #2980b9; }
        .nav-btn.logout { background: #e74c3c; }
        .nav-btn.logout:hover { background: #c0392b; }

        /* ---------- CONTAINER ---------- */
        .container {
            max-width: 1150px;
            margin: 0 auto;
            padding: 0 20px;
        }

        /* ---------- MEMBER PROFILE CARD ---------- */
        .profile-card {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 15px 50px rgba(0,0,0,0.25);
            overflow: hidden;
            margin-bottom: 25px;
        }
        .profile-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            padding: 30px;
            display: flex;
            align-items: center;
            gap: 25px;
            flex-wrap: wrap;
        }
        .big-avatar {
            width: 90px;
            height: 90px;
            border-radius: 50%;
            background: rgba(255,255,255,0.25);
            border: 3px solid rgba(255,255,255,0.6);
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 800;
            font-size: 38px;
            flex-shrink: 0;
            box-shadow: 0 8px 25px rgba(0,0,0,0.2);
        }
        .profile-info { flex: 1; min-width: 200px; }
        .profile-info h2 {
            font-size: 26px;
            margin-bottom: 8px;
        }
        .profile-info p {
            font-size: 14px;
            opacity: 0.9;
            margin-bottom: 4px;
        }
        .profile-info .mid-badge {
            display: inline-block;
            background: rgba(255,255,255,0.25);
            padding: 4px 14px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 700;
            margin-bottom: 8px;
            letter-spacing: 0.5px;
        }

        /* ---------- STATS GRID ---------- */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
            margin-bottom: 25px;
        }
        .stat-card {
            background: #fff;
            border-radius: 14px;
            padding: 20px;
            box-shadow: 0 8px 25px rgba(0,0,0,0.12);
            border-left: 5px solid #667eea;
            transition: 0.3s;
        }
        .stat-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 12px 30px rgba(0,0,0,0.18);
        }
        .stat-card .icon {
            font-size: 24px;
            margin-bottom: 6px;
        }
        .stat-card .num {
            font-size: 30px;
            font-weight: 800;
            color: #4a3f8f;
            line-height: 1;
            margin-bottom: 5px;
        }
        .stat-card .lbl {
            font-size: 11px;
            color: #777;
            text-transform: uppercase;
            letter-spacing: 1px;
            font-weight: 700;
        }
        .stat-card.active   { border-left-color: #3498db; }
        .stat-card.active .num   { color: #2980b9; }
        .stat-card.returned { border-left-color: #27ae60; }
        .stat-card.returned .num { color: #1e8449; }
        .stat-card.overdue  { border-left-color: #e74c3c; }
        .stat-card.overdue .num  { color: #c0392b; }
        .stat-card.fine     { border-left-color: #f39c12; }
        .stat-card.fine .num     { color: #b9770e; }

        /* ---------- TABLE CARD ---------- */
        .table-card {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 15px 50px rgba(0,0,0,0.25);
            overflow: hidden;
        }
        .table-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            padding: 20px 30px;
        }
        .table-header h3 { font-size: 18px; margin-bottom: 3px; }
        .table-header p { font-size: 13px; opacity: 0.9; }

        .table-wrap { padding: 20px 30px 30px; overflow-x: auto; }

        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
        }
        thead th {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            padding: 13px 12px;
            text-align: left;
            font-weight: 600;
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        thead th:first-child { border-radius: 10px 0 0 0; }
        thead th:last-child  { border-radius: 0 10px 0 0; }

        tbody td {
            padding: 13px 12px;
            border-bottom: 1px solid #eee;
            color: #333;
        }
        tbody tr:hover { background: #f9f9ff; }
        tbody tr:last-child td { border-bottom: none; }

        .badge {
            padding: 4px 11px;
            border-radius: 15px;
            font-size: 11px;
            font-weight: 700;
            display: inline-block;
        }
        .badge-active   { background: #cce5ff; color: #004085; }
        .badge-returned { background: #d4edda; color: #155724; }
        .badge-overdue  { background: #f8d7da; color: #721c24; }
        .badge-fine     { background: #fff3cd; color: #856404; }

        /* ---------- EMPTY ---------- */
        .empty {
            padding: 50px 30px;
            text-align: center;
            color: #888;
        }
        .empty .icon { font-size: 60px; margin-bottom: 15px; }
        .empty h3 { color: #4a3f8f; margin-bottom: 8px; }
        .empty p { font-size: 14px; margin-bottom: 20px; }
        .empty a {
            display: inline-block;
            padding: 12px 25px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            text-decoration: none;
            border-radius: 10px;
            font-weight: 600;
        }
    </style>
</head>
<body>

    <!-- NAVBAR -->
    <div class="navbar">
        <h1>📚 Library Management System</h1>
        <div class="nav-right">
            <span>👤 <%= adminName %></span>
            <a href="listMembers.jsp" class="nav-btn back">⬅ Members</a>
            <a href="index.html" class="nav-btn home">🏠 Home</a>
            <a href="logout.jsp" class="nav-btn logout">Logout</a>
        </div>
    </div>

    <div class="container">

        <!-- MEMBER PROFILE CARD -->
        <div class="profile-card">
            <div class="profile-header">
                <div class="big-avatar"><%= initial %></div>
                <div class="profile-info">
                    <span class="mid-badge">🆔 <%= member_id %></span>
                    <h2><%= mName %></h2>
                    <p>📧 <%= mEmail %></p>
                </div>
            </div>
        </div>

        <%
            // ---------- FETCH HISTORY + STATS ----------
            java.util.List<String[]> history = new java.util.ArrayList<String[]>();
            try {
                DBDatabaseConnection db = new DBDatabaseConnection();

                String sql =
                    "SELECT br.record_id, br.book_number, b.title AS book_title, b.author, " +
                    "       br.issue_date, br.due_date, br.return_date " +
                    "FROM borrowing_records br " +
                    "JOIN books b ON br.book_number = b.book_number " +
                    "WHERE br.member_id = ? " +
                    "ORDER BY br.record_id DESC";
                db.pstmt = db.con.prepareStatement(sql);
                db.pstmt.setString(1, member_id);
                db.rst = db.pstmt.executeQuery();

                while (db.rst.next()) {
                    totalLoans++;

                    java.sql.Date issueSql  = db.rst.getDate("issue_date");
                    java.sql.Date dueSql    = db.rst.getDate("due_date");
                    java.sql.Date returnSql = db.rst.getDate("return_date");

                    LocalDate issue = issueSql.toLocalDate();
                    LocalDate due   = dueSql.toLocalDate();
                    LocalDate returned = returnSql != null ? returnSql.toLocalDate() : null;

                    String statusClass;
                    String statusText;
                    long daysDiff;

                    if (returned == null) {
                        if (today.isAfter(due)) {
                            daysDiff = ChronoUnit.DAYS.between(due, today);
                            overdueLoans++;
                            totalFines += daysDiff * 1.0;
                            statusClass = "badge-overdue";
                            statusText = "⚠️ Overdue (" + daysDiff + "d)";
                        } else {
                            daysDiff = ChronoUnit.DAYS.between(today, due);
                            activeLoans++;
                            statusClass = "badge-active";
                            statusText = "📖 Active (" + daysDiff + "d left)";
                        }
                    } else {
                        if (returned.isAfter(due)) {
                            daysDiff = ChronoUnit.DAYS.between(due, returned);
                            totalFines += daysDiff * 1.0;
                            statusClass = "badge-fine";
                            statusText = "⚠️ Late (" + daysDiff + "d)";
                        } else {
                            statusClass = "badge-returned";
                            statusText = "✅ Returned";
                        }
                        returnedLoans++;
                    }

                    history.add(new String[]{
                        String.valueOf(db.rst.getInt("record_id")),
                        db.rst.getString("book_number"),
                        db.rst.getString("book_title"),
                        db.rst.getString("author"),
                        issue.toString(),
                        due.toString(),
                        returned == null ? "—" : returned.toString(),
                        statusClass,
                        statusText
                    });
                }
                db.con.close();
            } catch (Exception e) {
                out.println("<div style='padding:20px;background:#f8d7da;color:#721c24;border-radius:10px;margin-bottom:20px;'>Error: " + e.getMessage() + "</div>");
            }
        %>

        <!-- STATS GRID -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="icon">📚</div>
                <div class="num"><%= totalLoans %></div>
                <div class="lbl">Total Loans</div>
            </div>
            <div class="stat-card active">
                <div class="icon">📖</div>
                <div class="num"><%= activeLoans %></div>
                <div class="lbl">Active Now</div>
            </div>
            <div class="stat-card returned">
                <div class="icon">✅</div>
                <div class="num"><%= returnedLoans %></div>
                <div class="lbl">Returned</div>
            </div>
            <div class="stat-card overdue">
                <div class="icon">⚠️</div>
                <div class="num"><%= overdueLoans %></div>
                <div class="lbl">Overdue</div>
            </div>
            <div class="stat-card fine">
                <div class="icon">💰</div>
                <div class="num">₹<%= String.format("%.0f", totalFines) %></div>
                <div class="lbl">Total Fines</div>
            </div>
        </div>

        <!-- HISTORY TABLE -->
        <div class="table-card">
            <div class="table-header">
                <h3>📜 Borrowing History</h3>
                <p>Complete record of all books borrowed by this member</p>
            </div>

            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Record ID</th>
                            <th>Book</th>
                            <th>Author</th>
                            <th>Issue Date</th>
                            <th>Due Date</th>
                            <th>Return Date</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        if (history.isEmpty()) {
                    %>
                        <tr>
                            <td colspan="8">
                                <div class="empty">
                                    <div class="icon">📭</div>
                                    <h3>No History</h3>
                                    <p>Is member ne abhi tak koi book nahi li.</p>
                                    <a href="issueBook.jsp">📤 Issue a Book</a>
                                </div>
                            </td>
                        </tr>
                    <%
                        } else {
                            int i = 0;
                            for (String[] row : history) {
                                i++;
                    %>
                        <tr>
                            <td><%= i %></td>
                            <td><strong>#<%= row[0] %></strong></td>
                            <td>
                                <strong><%= row[2] %></strong><br>
                                <span style="font-size:11px;color:#888;"><%= row[1] %></span>
                            </td>
                            <td><%= row[3] %></td>
                            <td><%= row[4] %></td>
                            <td><%= row[5] %></td>
                            <td><%= row[6] %></td>
                            <td><span class="badge <%= row[7] %>"><%= row[8] %></span></td>
                        </tr>
                    <%
                            }
                        }
                    %>
                    </tbody>
                </table>
            </div>
        </div>

    </div>

</body>
</html>