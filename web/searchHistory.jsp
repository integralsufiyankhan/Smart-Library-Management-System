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

    // Filters
    String memberFilter = request.getParameter("member_id");
    if (memberFilter == null) memberFilter = "";

    String msg = request.getParameter("msg");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Search History - Library Management System</title>
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
        .nav-btn.search { background: #27ae60; }
        .nav-btn.search:hover { background: #1e8449; }
        .nav-btn.logout { background: #e74c3c; }
        .nav-btn.logout:hover { background: #c0392b; }

        .container { max-width: 1150px; margin: 0 auto; padding: 0 20px; }

        .card {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 15px 50px rgba(0,0,0,0.25);
            overflow: hidden;
            margin-bottom: 25px;
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

        .btn-clear {
            background: #fff;
            color: #e74c3c;
            padding: 10px 22px;
            border-radius: 25px;
            text-decoration: none;
            font-weight: 700;
            font-size: 13px;
            transition: 0.3s;
            box-shadow: 0 4px 15px rgba(0,0,0,0.15);
        }
        .btn-clear:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(0,0,0,0.25);
            color: #c0392b;
        }

        /* FILTER BAR */
        .filter-bar {
            padding: 20px 30px;
            background: #f9f9ff;
            border-bottom: 1px solid #e0e0ea;
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            align-items: center;
        }
        .filter-bar label {
            font-weight: 700;
            font-size: 13px;
            color: #4a3f8f;
            margin-right: 5px;
        }
        .filter-bar select {
            padding: 10px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            font-size: 14px;
            background: #fff;
            transition: 0.3s;
            min-width: 220px;
        }
        .filter-bar select:focus {
            border-color: #667eea;
            outline: none;
            box-shadow: 0 0 0 4px rgba(102,126,234,0.1);
        }
        .filter-bar button {
            padding: 10px 22px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            border: none;
            border-radius: 10px;
            font-weight: 700;
            font-size: 14px;
            cursor: pointer;
            transition: 0.3s;
        }
        .filter-bar button:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 15px rgba(102,126,234,0.4);
        }
        .filter-bar .btn-reset {
            padding: 10px 20px;
            background: #f0f0f5;
            color: #4a3f8f;
            border-radius: 10px;
            text-decoration: none;
            font-weight: 600;
            font-size: 14px;
        }
        .filter-bar .btn-reset:hover { background: #e0e0ea; }

        /* STATS STRIP */
        .stats-strip {
            display: flex;
            gap: 15px;
            margin-bottom: 25px;
            flex-wrap: wrap;
        }
        .stat-box {
            flex: 1;
            min-width: 160px;
            background: #fff;
            border-radius: 14px;
            padding: 18px 22px;
            box-shadow: 0 8px 25px rgba(0,0,0,0.12);
            border-left: 5px solid #667eea;
        }
        .stat-box .num {
            font-size: 26px;
            font-weight: 800;
            color: #4a3f8f;
            line-height: 1;
            margin-bottom: 5px;
        }
        .stat-box .lbl {
            font-size: 11px;
            color: #777;
            text-transform: uppercase;
            letter-spacing: 1px;
            font-weight: 700;
        }
        .stat-box.unique { border-left-color: #3498db; }
        .stat-box.unique .num { color: #2980b9; }
        .stat-box.today { border-left-color: #27ae60; }
        .stat-box.today .num { color: #1e8449; }
        .stat-box.top { border-left-color: #e67e22; }
        .stat-box.top .num { color: #b9770e; font-size: 18px; padding-top: 6px; }

        /* POPULAR SEARCHES */
        .popular-wrap {
            padding: 20px 30px;
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 15px 50px rgba(0,0,0,0.2);
            margin-bottom: 25px;
        }
        .popular-title {
            font-size: 13px;
            color: #4a3f8f;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 12px;
        }
        .popular-tags {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
        }
        .pop-tag {
            padding: 8px 16px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 600;
            text-decoration: none;
            transition: 0.3s;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }
        .pop-tag:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 18px rgba(102,126,234,0.4);
        }
        .pop-tag .cnt {
            background: rgba(255,255,255,0.3);
            padding: 1px 8px;
            border-radius: 10px;
            font-size: 11px;
        }

        /* TABLE */
        .table-wrap { padding: 20px 30px 30px; overflow-x: auto; }

        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }
        thead th {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            padding: 13px 14px;
            text-align: left;
            font-weight: 600;
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        thead th:first-child { border-radius: 10px 0 0 0; }
        thead th:last-child  { border-radius: 0 10px 0 0; }

        tbody td {
            padding: 13px 14px;
            border-bottom: 1px solid #eee;
            color: #333;
            vertical-align: middle;
        }
        tbody tr:hover { background: #f9f9ff; }
        tbody tr:last-child td { border-bottom: none; }

        .member-cell {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .avatar-sm {
            width: 30px;
            height: 30px;
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

        .query-text {
            font-family: 'Consolas', monospace;
            background: #f4f4ff;
            padding: 5px 12px;
            border-radius: 8px;
            color: #4a3f8f;
            font-size: 13px;
            font-weight: 600;
            display: inline-block;
        }

        .result-badge {
            padding: 4px 12px;
            border-radius: 15px;
            font-size: 11px;
            font-weight: 700;
        }
        .result-ok   { background: #d4edda; color: #155724; }
        .result-none { background: #f8d7da; color: #721c24; }

        .time-cell {
            font-size: 12px;
            color: #666;
            white-space: nowrap;
        }

        .btn-icon {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 8px;
            text-decoration: none;
            font-size: 11px;
            font-weight: 600;
            transition: 0.3s;
            background: #cce5ff;
            color: #004085;
        }
        .btn-icon:hover { background: #99caff; }

        /* EMPTY */
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

        .msg {
            padding: 15px 20px;
            border-radius: 10px;
            margin: 20px 30px 0;
            font-weight: 600;
            font-size: 14px;
        }
        .msg.success {
            background: #d4edda;
            color: #155724;
            border-left: 5px solid #28a745;
        }
    </style>
</head>
<body>

    <div class="navbar">
        <h1>📚 Library Management System</h1>
        <div class="nav-right">
            <span>👤 <%= adminName %></span>
            <a href="searchBooks.jsp" class="nav-btn search">🔍 Search</a>
            <a href="index.html" class="nav-btn home">🏠 Home</a>
            <a href="logout.jsp" class="nav-btn logout">Logout</a>
        </div>
    </div>

    <div class="container">

        <% if ("cleared".equals(msg)) { %>
            <div class="msg success">✅ Search history cleared successfully!</div>
        <% } %>

        <!-- STATS STRIP -->
        <%
            int totalSearches = 0;
            int uniqueQueries = 0;
            int todaySearches = 0;
            String topQuery = "—";
            int topQueryCount = 0;

            try {
                DBDatabaseConnection dbStats = new DBDatabaseConnection();

                // Total
                dbStats.rst = dbStats.con.createStatement().executeQuery(
                    "SELECT COUNT(*) AS c FROM search_history");
                if (dbStats.rst.next()) totalSearches = dbStats.rst.getInt("c");

                // Unique queries
                dbStats.rst = dbStats.con.createStatement().executeQuery(
                    "SELECT COUNT(DISTINCT query) AS c FROM search_history");
                if (dbStats.rst.next()) uniqueQueries = dbStats.rst.getInt("c");

                // Today
                dbStats.rst = dbStats.con.createStatement().executeQuery(
                    "SELECT COUNT(*) AS c FROM search_history WHERE DATE(searched_at) = CURDATE()");
                if (dbStats.rst.next()) todaySearches = dbStats.rst.getInt("c");

                // Top query
                dbStats.rst = dbStats.con.createStatement().executeQuery(
                    "SELECT query, COUNT(*) AS c FROM search_history GROUP BY query ORDER BY c DESC LIMIT 1");
                if (dbStats.rst.next()) {
                    topQuery = dbStats.rst.getString("query");
                    topQueryCount = dbStats.rst.getInt("c");
                }

                dbStats.con.close();
            } catch (Exception e) { }
        %>

        <div class="stats-strip">
            <div class="stat-box">
                <div class="num"><%= totalSearches %></div>
                <div class="lbl">Total Searches</div>
            </div>
            <div class="stat-box unique">
                <div class="num"><%= uniqueQueries %></div>
                <div class="lbl">Unique Queries</div>
            </div>
            <div class="stat-box today">
                <div class="num"><%= todaySearches %></div>
                <div class="lbl">Today</div>
            </div>
            <div class="stat-box top">
                <div class="num">🔥 <%= topQuery %></div>
                <div class="lbl">Top Query (<%= topQueryCount %> times)</div>
            </div>
        </div>

        <!-- POPULAR SEARCHES -->
        <%
            List<String[]> popularList = new ArrayList<String[]>();
            try {
                DBDatabaseConnection dbP = new DBDatabaseConnection();
                dbP.rst = dbP.con.createStatement().executeQuery(
                    "SELECT query, COUNT(*) AS c FROM search_history " +
                    "GROUP BY query ORDER BY c DESC LIMIT 10");
                while (dbP.rst.next()) {
                    popularList.add(new String[]{
                        dbP.rst.getString("query"),
                        String.valueOf(dbP.rst.getInt("c"))
                    });
                }
                dbP.con.close();
            } catch (Exception e) { }
        %>

        <% if (!popularList.isEmpty()) { %>
        <div class="popular-wrap">
            <div class="popular-title">🔥 Popular Searches</div>
            <div class="popular-tags">
                <% for (String[] p : popularList) { %>
                    <a href="searchBooks.jsp?q=<%= java.net.URLEncoder.encode(p[0], "UTF-8") %>" class="pop-tag">
                        🔍 <%= p[0] %>
                        <span class="cnt"><%= p[1] %></span>
                    </a>
                <% } %>
            </div>
        </div>
        <% } %>

        <!-- MAIN CARD -->
        <div class="card">
            <div class="card-header">
                <div>
                    <h2>🕓 Search History</h2>
                    <p>All searches performed by members</p>
                </div>
                <a href="clearSearchHistory.jsp" class="btn-clear"
                   onclick="return confirm('Are you sure you want to clear ALL search history?');">
                    🗑️ Clear All
                </a>
            </div>

            <!-- FILTER -->
            <form class="filter-bar" action="searchHistory.jsp" method="get">
                <label>👤 Filter by Member:</label>
                <select name="member_id">
                    <option value="">-- All Members --</option>
                    <%
                        try {
                            DBDatabaseConnection dbM = new DBDatabaseConnection();
                            dbM.rst = dbM.con.createStatement().executeQuery(
                                "SELECT member_id, name FROM members ORDER BY name");
                            while (dbM.rst.next()) {
                                String mid = dbM.rst.getString("member_id");
                                String mn = dbM.rst.getString("name");
                    %>
                        <option value="<%= mid %>" <%= mid.equals(memberFilter) ? "selected" : "" %>>
                            <%= mn %> (<%= mid %>)
                        </option>
                    <%
                            }
                            dbM.con.close();
                        } catch (Exception e) { }
                    %>
                </select>
                <button type="submit">Apply Filter</button>
                <% if (!memberFilter.isEmpty()) { %>
                    <a href="searchHistory.jsp" class="btn-reset">✖ Reset</a>
                <% } %>
            </form>

            <%
                int rows = 0;
                boolean hasRows = false;
            %>

            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Member</th>
                            <th>Query</th>
                            <th>Results</th>
                            <th>When</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        try {
                            DBDatabaseConnection db = new DBDatabaseConnection();

                            String sql;
                            if (memberFilter.isEmpty()) {
                                sql = "SELECT h.history_id, h.member_id, h.query, h.result_count, h.searched_at, " +
                                      "       m.name AS member_name " +
                                      "FROM search_history h " +
                                      "LEFT JOIN members m ON h.member_id = m.member_id " +
                                      "ORDER BY h.searched_at DESC LIMIT 200";
                                db.pstmt = db.con.prepareStatement(sql);
                            } else {
                                sql = "SELECT h.history_id, h.member_id, h.query, h.result_count, h.searched_at, " +
                                      "       m.name AS member_name " +
                                      "FROM search_history h " +
                                      "LEFT JOIN members m ON h.member_id = m.member_id " +
                                      "WHERE h.member_id = ? " +
                                      "ORDER BY h.searched_at DESC LIMIT 200";
                                db.pstmt = db.con.prepareStatement(sql);
                                db.pstmt.setString(1, memberFilter);
                            }

                            db.rst = db.pstmt.executeQuery();
                            while (db.rst.next()) {
                                hasRows = true;
                                rows++;

                                String mid = db.rst.getString("member_id");
                                String mName = db.rst.getString("member_name");
                                if (mName == null) mName = "Guest";
                                String initial = mName != null && !mName.isEmpty()
                                                 ? mName.substring(0, 1).toUpperCase() : "?";

                                String q = db.rst.getString("query");
                                int rc = db.rst.getInt("result_count");
                                String when = db.rst.getTimestamp("searched_at").toString();
                    %>
                        <tr>
                            <td><%= rows %></td>
                            <td>
                                <div class="member-cell">
                                    <span class="avatar-sm"><%= initial %></span>
                                    <div>
                                        <strong><%= mName %></strong><br>
                                        <span style="font-size:11px;color:#888;"><%= mid == null ? "—" : mid %></span>
                                    </div>
                                </div>
                            </td>
                            <td><span class="query-text">🔍 <%= q %></span></td>
                            <td>
                                <% if (rc > 0) { %>
                                    <span class="result-badge result-ok"><%= rc %> found</span>
                                <% } else { %>
                                    <span class="result-badge result-none">No results</span>
                                <% } %>
                            </td>
                            <td class="time-cell"><%= when %></td>
                            <td>
                                <a href="searchBooks.jsp?q=<%= java.net.URLEncoder.encode(q, "UTF-8") %>"
                                   class="btn-icon">🔍 Re-search</a>
                            </td>
                        </tr>
                    <%
                            }
                            db.con.close();
                        } catch (Exception e) {
                            out.println("<tr><td colspan='6' style='color:red;text-align:center;padding:20px;'>Error: " + e.getMessage() + "</td></tr>");
                        }

                        if (!hasRows) {
                    %>
                        <tr>
                            <td colspan="6">
                                <div class="empty">
                                    <div class="icon">🕓</div>
                                    <h3>No Search History Yet</h3>
                                    <p>Abhi tak koi member ne search nahi kiya.</p>
                                    <a href="searchBooks.jsp">🔍 Start Searching</a>
                                </div>
                            </td>
                        </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        </div>

    </div>

</body>
</html>