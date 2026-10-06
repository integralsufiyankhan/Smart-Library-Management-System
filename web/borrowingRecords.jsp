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

    // ---------- FILTERS ----------
    String filter = request.getParameter("filter");
    if (filter == null || filter.trim().isEmpty()) filter = "all"; // all | active | returned | overdue

    String search = request.getParameter("search");
    if (search == null) search = "";
    search = search.trim();

    LocalDate today = LocalDate.now();

    // ---------- STATS ----------
    int statTotal = 0;
    int statActive = 0;
    int statReturned = 0;
    int statOverdue = 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Borrowing Records - Library Management System</title>
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
            max-width: 1250px;
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
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
        }
        .card-header h2 { font-size: 22px; margin-bottom: 5px; }
        .card-header p { font-size: 13px; opacity: 0.9; }

        .header-actions { display: flex; gap: 10px; }
        .btn-issue {
            background: #fff;
            color: #4a3f8f;
            padding: 10px 20px;
            border-radius: 25px;
            text-decoration: none;
            font-weight: 700;
            font-size: 14px;
            transition: 0.3s;
            box-shadow: 0 4px 15px rgba(0,0,0,0.15);
        }
        .btn-issue:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(0,0,0,0.25);
        }

        /* ---------- FILTER TABS ---------- */
        .filters {
            display: flex;
            gap: 8px;
            padding: 20px 30px;
            background: #f9f9ff;
            border-bottom: 1px solid #e0e0ea;
            overflow-x: auto;
            flex-wrap: wrap;
        }
        .filter-tab {
            padding: 9px 20px;
            border-radius: 25px;
            text-decoration: none;
            font-weight: 700;
            font-size: 13px;
            background: #eef1ff;
            color: #4a3f8f;
            transition: 0.3s;
            white-space: nowrap;
            border: 2px solid transparent;
        }
        .filter-tab:hover {
            background: #dde3ff;
        }
        .filter-tab.active {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            border-color: #4a3f8f;
        }
        .filter-tab .count {
            display: inline-block;
            background: rgba(255,255,255,0.3);
            padding: 1px 8px;
            border-radius: 10px;
            margin-left: 5px;
            font-size: 11px;
        }
        .filter-tab:not(.active) .count {
            background: #4a3f8f;
            color: #fff;
        }

        /* ---------- SEARCH ---------- */
        .search-bar {
            padding: 15px 30px;
            background: #fff;
            border-bottom: 1px solid #e0e0ea;
            display: flex;
            gap: 10px;
        }
        .search-bar input {
            flex: 1;
            padding: 11px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            font-size: 14px;
            transition: 0.3s;
        }
        .search-bar input:focus {
            border-color: #667eea;
            outline: none;
            box-shadow: 0 0 0 4px rgba(102,126,234,0.1);
        }
        .search-bar button {
            padding: 11px 25px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            border: none;
            border-radius: 10px;
            font-weight: 600;
            font-size: 14px;
            cursor: pointer;
            transition: 0.3s;
        }
        .search-bar button:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 15px rgba(102,126,234,0.4);
        }
        .search-bar a {
            padding: 11px 20px;
            background: #f0f0f5;
            color: #4a3f8f;
            border-radius: 10px;
            text-decoration: none;
            font-weight: 600;
            font-size: 14px;
            display: flex;
            align-items: center;
        }
        .search-bar a:hover { background: #e0e0ea; }

        /* ---------- TABLE ---------- */
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

        .member-cell {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .avatar-sm {
            width: 28px;
            height: 28px;
            border-radius: 50%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            font-size: 12px;
            flex-shrink: 0;
        }

        .btn-icon {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 7px;
            text-decoration: none;
            font-size: 11px;
            font-weight: 600;
            transition: 0.3s;
        }
        .btn-hist { background: #cce5ff; color: #004085; }
        .btn-hist:hover { background: #99caff; }

        /* ---------- EMPTY ---------- */
        .empty {
            padding: 60px 30px;
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
            <a href="index.html" class="nav-btn home">🏠 Home</a>
            <a href="logout.jsp" class="nav-btn logout">Logout</a>
        </div>
    </div>

    <!-- MAIN CARD -->
    <div class="container">
        <div class="card">
            <div class="card-header">
                <div>
                    <h2>📋 Borrowing Records</h2>
                    <p>Complete history of every book issued & returned</p>
                </div>
                <div class="header-actions">
                    <a href="issueBook.jsp" class="btn-issue">📤 Issue Book</a>
                </div>
            </div>

            <%
                // ---------- COMPUTE STATS (once) ----------
                try {
                    DBDatabaseConnection dbStats = new DBDatabaseConnection();

                    // Total
                    dbStats.rst = dbStats.con.createStatement().executeQuery(
                        "SELECT COUNT(*) AS c FROM borrowing_records");
                    if (dbStats.rst.next()) statTotal = dbStats.rst.getInt("c");

                    // Active
                    dbStats.rst = dbStats.con.createStatement().executeQuery(
                        "SELECT COUNT(*) AS c FROM borrowing_records WHERE return_date IS NULL");
                    if (dbStats.rst.next()) statActive = dbStats.rst.getInt("c");

                    // Returned
                    dbStats.rst = dbStats.con.createStatement().executeQuery(
                        "SELECT COUNT(*) AS c FROM borrowing_records WHERE return_date IS NOT NULL");
                    if (dbStats.rst.next()) statReturned = dbStats.rst.getInt("c");

                    // Overdue (active & due_date < today)
                    PreparedStatement psOv = dbStats.con.prepareStatement(
                        "SELECT COUNT(*) AS c FROM borrowing_records " +
                        "WHERE return_date IS NULL AND due_date < ?");
                    psOv.setDate(1, java.sql.Date.valueOf(today));
                    dbStats.rst = psOv.executeQuery();
                    if (dbStats.rst.next()) statOverdue = dbStats.rst.getInt("c");

                    dbStats.con.close();
                } catch (Exception e) { /* ignore stats error */ }
            %>

            <!-- FILTER TABS -->
            <div class="filters">
                <a href="borrowingRecords.jsp?filter=all" class="filter-tab <%= "all".equals(filter) ? "active" : "" %>">
                    📚 All <span class="count"><%= statTotal %></span>
                </a>
                <a href="borrowingRecords.jsp?filter=active" class="filter-tab <%= "active".equals(filter) ? "active" : "" %>">
                    📖 Active <span class="count"><%= statActive %></span>
                </a>
                <a href="borrowingRecords.jsp?filter=returned" class="filter-tab <%= "returned".equals(filter) ? "active" : "" %>">
                    ✅ Returned <span class="count"><%= statReturned %></span>
                </a>
                <a href="borrowingRecords.jsp?filter=overdue" class="filter-tab <%= "overdue".equals(filter) ? "active" : "" %>">
                    ⚠️ Overdue <span class="count"><%= statOverdue %></span>
                </a>
            </div>

            <!-- SEARCH -->
            <form class="search-bar" action="borrowingRecords.jsp" method="get">
                <input type="hidden" name="filter" value="<%= filter %>">
                <input type="text" name="search"
                       placeholder="🔍 Search by member ID, name or book number..."
                       value="<%= search %>">
                <button type="submit">Search</button>
                <% if (!search.isEmpty()) { %>
                    <a href="borrowingRecords.jsp?filter=<%= filter %>">✖ Clear</a>
                <% } %>
            </form>

            <%
                int rows = 0;
                boolean hasRows = false;
            %>

            <!-- TABLE -->
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Record ID</th>
                            <th>Member</th>
                            <th>Book</th>
                            <th>Issue Date</th>
                            <th>Due Date</th>
                            <th>Return Date</th>
                            <th>Status</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        try {
                            DBDatabaseConnection db = new DBDatabaseConnection();

                            // Build WHERE clause based on filter + search
                            StringBuilder where = new StringBuilder(" WHERE 1=1 ");
                            if ("active".equals(filter)) {
                                where.append(" AND br.return_date IS NULL ");
                            } else if ("returned".equals(filter)) {
                                where.append(" AND br.return_date IS NOT NULL ");
                            } else if ("overdue".equals(filter)) {
                                where.append(" AND br.return_date IS NULL AND br.due_date < ? ");
                            }
                            boolean useSearch = !search.isEmpty();
                            if (useSearch) {
                                where.append(" AND (m.member_id LIKE ? OR m.name LIKE ? OR b.book_number LIKE ? OR b.title LIKE ?) ");
                            }

                            String sql =
                                "SELECT br.record_id, br.member_id, m.name AS member_name, " +
                                "       br.book_number, b.title AS book_title, " +
                                "       br.issue_date, br.due_date, br.return_date " +
                                "FROM borrowing_records br " +
                                "JOIN members m ON br.member_id = m.member_id " +
                                "JOIN books b ON br.book_number = b.book_number " +
                                where.toString() +
                                "ORDER BY br.record_id DESC";

                            db.pstmt = db.con.prepareStatement(sql);

                            int idx = 1;
                            if ("overdue".equals(filter)) {
                                db.pstmt.setDate(idx++, java.sql.Date.valueOf(today));
                            }
                            if (useSearch) {
                                String like = "%" + search + "%";
                                db.pstmt.setString(idx++, like);
                                db.pstmt.setString(idx++, like);
                                db.pstmt.setString(idx++, like);
                                db.pstmt.setString(idx++, like);
                            }

                            db.rst = db.pstmt.executeQuery();

                            while (db.rst.next()) {
                                hasRows = true;
                                rows++;

                                int recordId       = db.rst.getInt("record_id");
                                String memberId    = db.rst.getString("member_id");
                                String memberName  = db.rst.getString("member_name");
                                String bookNumber  = db.rst.getString("book_number");
                                String bookTitle   = db.rst.getString("book_title");
                                java.sql.Date issueSql  = db.rst.getDate("issue_date");
                                java.sql.Date dueSql    = db.rst.getDate("due_date");
                                java.sql.Date returnSql = db.rst.getDate("return_date");

                                LocalDate issue  = issueSql.toLocalDate();
                                LocalDate due    = dueSql.toLocalDate();
                                LocalDate returned = returnSql != null ? returnSql.toLocalDate() : null;

                                // Determine status
                                String statusBadgeClass;
                                String statusText;
                                long daysLate = 0;

                                if (returned == null) {
                                    if (today.isAfter(due)) {
                                        daysLate = ChronoUnit.DAYS.between(due, today);
                                        statusBadgeClass = "badge-overdue";
                                        statusText = "⚠️ Overdue (" + daysLate + "d)";
                                    } else {
                                        long daysLeft = ChronoUnit.DAYS.between(today, due);
                                        statusBadgeClass = "badge-active";
                                        statusText = "📖 Active (" + daysLeft + "d left)";
                                    }
                                } else {
                                    if (returned.isAfter(due)) {
                                        daysLate = ChronoUnit.DAYS.between(due, returned);
                                        statusBadgeClass = "badge-fine";
                                        statusText = "⚠️ Returned Late (" + daysLate + "d)";
                                    } else {
                                        statusBadgeClass = "badge-returned";
                                        statusText = "✅ Returned";
                                    }
                                }

                                String initial = memberName != null && !memberName.isEmpty()
                                                 ? memberName.substring(0, 1).toUpperCase()
                                                 : "?";
                    %>
                        <tr>
                            <td><%= rows %></td>
                            <td><strong>#<%= recordId %></strong></td>
                            <td>
                                <div class="member-cell">
                                    <span class="avatar-sm"><%= initial %></span>
                                    <div>
                                        <strong><%= memberName %></strong><br>
                                        <span style="font-size:11px;color:#888;"><%= memberId %></span>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <strong><%= bookTitle %></strong><br>
                                <span style="font-size:11px;color:#888;"><%= bookNumber %></span>
                            </td>
                            <td><%= issue.toString() %></td>
                            <td><%= due.toString() %></td>
                            <td>
                                <%= (returned == null
                                        ? "<span style='color:#999;'>—</span>"
                                        : returned.toString()) %>
                            </td>
                            <td><span class="badge <%= statusBadgeClass %>"><%= statusText %></span></td>
                            <td>
                                <a href="memberHistory.jsp?member_id=<%= memberId %>" class="btn-icon btn-hist">👤 Member</a>
                            </td>
                        </tr>
                    <%
                            }
                            db.con.close();
                        } catch (Exception e) {
                            out.println("<tr><td colspan='9' style='color:red;text-align:center;padding:20px;'>Error: " + e.getMessage() + "</td></tr>");
                        }

                        if (!hasRows) {
                    %>
                        <tr>
                            <td colspan="9">
                                <div class="empty">
                                    <div class="icon">📭</div>
                                    <h3>No Records Found</h3>
                                    <p>
                                        <%= search.isEmpty()
                                            ? "Is filter me koi record nahi hai."
                                            : "Search \"" + search + "\" ke liye koi record nahi mila." %>
                                    </p>
                                    <a href="issueBook.jsp">📤 Issue a Book</a>
                                </div>
                            </td>
                        </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>

        </div>

        <!-- SUMMARY STRIP -->
        <div style="display:flex;gap:15px;margin-top:20px;flex-wrap:wrap;">
            <div style="flex:1;min-width:160px;background:#fff;border-radius:12px;padding:18px 22px;box-shadow:0 6px 20px rgba(0,0,0,0.1);border-left:5px solid #667eea;">
                <div style="font-size:12px;color:#777;text-transform:uppercase;letter-spacing:1px;font-weight:700;">Total Records</div>
                <div style="font-size:26px;color:#4a3f8f;font-weight:800;margin-top:4px;"><%= statTotal %></div>
            </div>
            <div style="flex:1;min-width:160px;background:#fff;border-radius:12px;padding:18px 22px;box-shadow:0 6px 20px rgba(0,0,0,0.1);border-left:5px solid #3498db;">
                <div style="font-size:12px;color:#777;text-transform:uppercase;letter-spacing:1px;font-weight:700;">Active</div>
                <div style="font-size:26px;color:#2980b9;font-weight:800;margin-top:4px;"><%= statActive %></div>
            </div>
            <div style="flex:1;min-width:160px;background:#fff;border-radius:12px;padding:18px 22px;box-shadow:0 6px 20px rgba(0,0,0,0.1);border-left:5px solid #27ae60;">
                <div style="font-size:12px;color:#777;text-transform:uppercase;letter-spacing:1px;font-weight:700;">Returned</div>
                <div style="font-size:26px;color:#1e8449;font-weight:800;margin-top:4px;"><%= statReturned %></div>
            </div>
            <div style="flex:1;min-width:160px;background:#fff;border-radius:12px;padding:18px 22px;box-shadow:0 6px 20px rgba(0,0,0,0.1);border-left:5px solid #e74c3c;">
                <div style="font-size:12px;color:#777;text-transform:uppercase;letter-spacing:1px;font-weight:700;">Overdue</div>
                <div style="font-size:26px;color:#c0392b;font-weight:800;margin-top:4px;"><%= statOverdue %></div>
            </div>
        </div>

    </div>

</body>
</html>