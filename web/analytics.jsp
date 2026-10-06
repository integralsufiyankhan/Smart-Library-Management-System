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

    // ---------- KPI VARIABLES ----------
    int totalBooks = 0, totalTitles = 0, totalMembers = 0, totalIssued = 0;
    int activeLoans = 0, overdueLoans = 0, returnedLoans = 0, totalRecords = 0;
    int availableTotal = 0;
    double avgRating = 0, totalFines = 0;
    int totalReviews = 0;

    // Chart data
    List<String[]> categoryData = new ArrayList<String[]>();
    List<String[]> topBooksData = new ArrayList<String[]>();
    List<String[]> topMembersData = new ArrayList<String[]>();
    List<String[]> recentActivity = new ArrayList<String[]>();
    List<String[]> overdueList = new ArrayList<String[]>();
    List<String[]> monthlyTrend = new ArrayList<String[]>();

    try {
        DBDatabaseConnection db = new DBDatabaseConnection();

        // KPI: Total titles
        ResultSet r1 = db.con.createStatement().executeQuery("SELECT COUNT(*) AS c FROM books");
        if (r1.next()) totalTitles = r1.getInt("c");

        // KPI: Total copies
        r1 = db.con.createStatement().executeQuery("SELECT IFNULL(SUM(total_copies),0) AS c FROM books");
        if (r1.next()) totalBooks = r1.getInt("c");

        // KPI: Available copies
        r1 = db.con.createStatement().executeQuery("SELECT IFNULL(SUM(available_copies),0) AS c FROM books");
        if (r1.next()) availableTotal = r1.getInt("c");

        // KPI: Total members
        r1 = db.con.createStatement().executeQuery("SELECT COUNT(*) AS c FROM members");
        if (r1.next()) totalMembers = r1.getInt("c");

        // KPI: Total borrowing records
        r1 = db.con.createStatement().executeQuery("SELECT COUNT(*) AS c FROM borrowing_records");
        if (r1.next()) totalRecords = r1.getInt("c");

        // KPI: Active loans
        r1 = db.con.createStatement().executeQuery(
            "SELECT COUNT(*) AS c FROM borrowing_records WHERE return_date IS NULL");
        if (r1.next()) activeLoans = r1.getInt("c");

        // KPI: Returned
        r1 = db.con.createStatement().executeQuery(
            "SELECT COUNT(*) AS c FROM borrowing_records WHERE return_date IS NOT NULL");
        if (r1.next()) returnedLoans = r1.getInt("c");

        // KPI: Overdue
        r1 = db.con.createStatement().executeQuery(
            "SELECT COUNT(*) AS c FROM borrowing_records WHERE return_date IS NULL AND due_date < CURDATE()");
        if (r1.next()) overdueLoans = r1.getInt("c");

        // KPI: Total issued books (currently)
        totalIssued = activeLoans;

        // KPI: Avg rating
        r1 = db.con.createStatement().executeQuery(
            "SELECT IFNULL(AVG(avg_rating),0) AS c FROM books WHERE avg_rating > 0");
        if (r1.next()) avgRating = r1.getDouble("c");

        // KPI: Total reviews
        r1 = db.con.createStatement().executeQuery("SELECT COUNT(*) AS c FROM reviews");
        if (r1.next()) totalReviews = r1.getInt("c");

        // ---------- CHART 1: Category Distribution ----------
        ResultSet rc = db.con.createStatement().executeQuery(
            "SELECT category, COUNT(*) AS c, SUM(total_copies) AS copies " +
            "FROM books GROUP BY category ORDER BY copies DESC LIMIT 8");
        while (rc.next()) {
            categoryData.add(new String[]{
                rc.getString("category") == null ? "General" : rc.getString("category"),
                String.valueOf(rc.getInt("c")),
                String.valueOf(rc.getInt("copies"))
            });
        }

        // ---------- CHART 2: Top 5 Most Borrowed Books ----------
        ResultSet rb = db.con.createStatement().executeQuery(
            "SELECT b.title, b.book_number, COUNT(br.record_id) AS borrows " +
            "FROM books b LEFT JOIN borrowing_records br ON b.book_number = br.book_number " +
            "GROUP BY b.book_number, b.title " +
            "ORDER BY borrows DESC LIMIT 5");
        while (rb.next()) {
            topBooksData.add(new String[]{
                rb.getString("title"),
                rb.getString("book_number"),
                String.valueOf(rb.getInt("borrows"))
            });
        }

        // ---------- CHART 3: Top 5 Active Members ----------
        ResultSet rm = db.con.createStatement().executeQuery(
            "SELECT m.name, m.member_id, COUNT(br.record_id) AS loans " +
            "FROM members m LEFT JOIN borrowing_records br ON m.member_id = br.member_id " +
            "GROUP BY m.member_id, m.name " +
            "ORDER BY loans DESC LIMIT 5");
        while (rm.next()) {
            topMembersData.add(new String[]{
                rm.getString("name"),
                rm.getString("member_id"),
                String.valueOf(rm.getInt("loans"))
            });
        }

        // ---------- CHART 4: Monthly Trend (last 6 months) ----------
        ResultSet rt = db.con.createStatement().executeQuery(
            "SELECT DATE_FORMAT(issue_date, '%Y-%m') AS ym, " +
            "       DATE_FORMAT(issue_date, '%b %Y') AS lbl, " +
            "       COUNT(*) AS cnt " +
            "FROM borrowing_records " +
            "WHERE issue_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH) " +
            "GROUP BY ym, lbl ORDER BY ym");
        while (rt.next()) {
            monthlyTrend.add(new String[]{
                rt.getString("lbl"),
                String.valueOf(rt.getInt("cnt"))
            });
        }

        // ---------- RECENT ACTIVITY (last 8 records) ----------
        ResultSet ra = db.con.createStatement().executeQuery(
            "SELECT br.record_id, m.name AS member_name, b.title, " +
            "       br.issue_date, br.return_date " +
            "FROM borrowing_records br " +
            "JOIN members m ON br.member_id = m.member_id " +
            "JOIN books b ON br.book_number = b.book_number " +
            "ORDER BY br.record_id DESC LIMIT 8");
        while (ra.next()) {
            java.sql.Date rd = ra.getDate("return_date");
            recentActivity.add(new String[]{
                ra.getString("member_name"),
                ra.getString("title"),
                ra.getDate("issue_date").toString(),
                rd == null ? "—" : rd.toString(),
                rd == null ? "active" : "returned"
            });
        }

        // ---------- OVERDUE LIST (top 5) ----------
        ResultSet ro = db.con.createStatement().executeQuery(
            "SELECT m.name AS member_name, m.member_id, b.title, br.due_date, " +
            "       DATEDIFF(CURDATE(), br.due_date) AS days_late " +
            "FROM borrowing_records br " +
            "JOIN members m ON br.member_id = m.member_id " +
            "JOIN books b ON br.book_number = b.book_number " +
            "WHERE br.return_date IS NULL AND br.due_date < CURDATE() " +
            "ORDER BY days_late DESC LIMIT 5");
        while (ro.next()) {
            overdueList.add(new String[]{
                ro.getString("member_name"),
                ro.getString("member_id"),
                ro.getString("title"),
                ro.getDate("due_date").toString(),
                String.valueOf(ro.getInt("days_late"))
            });
            totalFines += ro.getInt("days_late") * 1.0;
        }

        db.con.close();
    } catch (Exception e) {
        out.println("<div style='padding:20px;background:#f8d7da;color:#721c24;border-radius:10px;margin-bottom:20px;'>Error: " + e.getMessage() + "</div>");
    }

    double availabilityRate = totalBooks > 0 ? (availableTotal * 100.0 / totalBooks) : 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Analytics Dashboard - Library Management System</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
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

        .container { max-width: 1300px; margin: 0 auto; padding: 0 20px; }

        /* PAGE TITLE */
        .page-title {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 15px 50px rgba(0,0,0,0.2);
            padding: 25px 30px;
            margin-bottom: 25px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
        }
        .page-title h2 {
            color: #4a3f8f;
            font-size: 26px;
            margin-bottom: 5px;
        }
        .page-title p { color: #666; font-size: 14px; }
        .page-title .live-badge {
            background: #d4edda;
            color: #155724;
            padding: 8px 18px;
            border-radius: 25px;
            font-size: 13px;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .live-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: #27ae60;
            animation: pulse 1.5s infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.3; }
        }

        /* KPI GRID */
        .kpi-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 25px;
        }
        .kpi-card {
            background: #fff;
            border-radius: 14px;
            padding: 22px 24px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.12);
            transition: 0.3s;
            position: relative;
            overflow: hidden;
        }
        .kpi-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 15px 40px rgba(0,0,0,0.18);
        }
        .kpi-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 6px;
            height: 100%;
            background: #667eea;
        }
        .kpi-card.books::before   { background: linear-gradient(180deg, #667eea, #764ba2); }
        .kpi-card.members::before { background: linear-gradient(180deg, #4facfe, #00f2fe); }
        .kpi-card.active::before  { background: linear-gradient(180deg, #27ae60, #6ee7b7); }
        .kpi-card.overdue::before { background: linear-gradient(180deg, #e74c3c, #f8a5a0); }
        .kpi-card.rating::before  { background: linear-gradient(180deg, #f39c12, #fcd34d); }
        .kpi-card.fines::before   { background: linear-gradient(180deg, #e67e22, #fcd34d); }

        .kpi-card .icon {
            font-size: 26px;
            margin-bottom: 8px;
            display: block;
        }
        .kpi-card .value {
            font-size: 30px;
            font-weight: 800;
            color: #4a3f8f;
            line-height: 1;
            margin-bottom: 6px;
        }
        .kpi-card.books .value   { color: #4a3f8f; }
        .kpi-card.members .value { color: #2980b9; }
        .kpi-card.active .value  { color: #1e8449; }
        .kpi-card.overdue .value { color: #c0392b; }
        .kpi-card.rating .value  { color: #b9770e; }
        .kpi-card.fines .value   { color: #b9770e; }

        .kpi-card .label {
            font-size: 12px;
            color: #777;
            text-transform: uppercase;
            letter-spacing: 1px;
            font-weight: 700;
        }
        .kpi-card .sub {
            font-size: 12px;
            color: #999;
            margin-top: 6px;
            font-weight: 600;
        }

        /* CHART GRID */
        .chart-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 20px;
            margin-bottom: 25px;
        }
        .chart-card {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 15px 50px rgba(0,0,0,0.2);
            overflow: hidden;
        }
        .chart-card.full-width {
            grid-column: 1 / -1;
        }
        .chart-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            padding: 16px 24px;
            font-size: 15px;
            font-weight: 700;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .chart-header .badge {
            background: rgba(255,255,255,0.25);
            padding: 4px 12px;
            border-radius: 15px;
            font-size: 11px;
            font-weight: 700;
        }
        .chart-body {
            padding: 20px 24px 24px;
            height: 300px;
            position: relative;
        }
        .chart-body.tall { height: 320px; }

        /* LISTS */
        .two-col-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(450px, 1fr));
            gap: 20px;
            margin-bottom: 25px;
        }
        .list-card {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 15px 50px rgba(0,0,0,0.2);
            overflow: hidden;
        }
        .list-header {
            padding: 16px 24px;
            color: #fff;
            font-size: 15px;
            font-weight: 700;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .list-header.warn { background: linear-gradient(135deg, #e74c3c 0%, #f8a5a0 100%); }
        .list-header.info { background: linear-gradient(135deg, #3498db 0%, #85c1e9 100%); }

        .list-header .count-badge {
            background: rgba(255,255,255,0.3);
            padding: 4px 12px;
            border-radius: 15px;
            font-size: 12px;
            font-weight: 700;
        }

        .list-body { padding: 15px 24px; }

        .list-item {
            padding: 12px 0;
            border-bottom: 1px solid #eee;
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .list-item:last-child { border-bottom: none; }

        .avatar-sm {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            font-size: 14px;
            flex-shrink: 0;
        }

        .list-item-body { flex: 1; min-width: 0; }
        .list-item-title {
            font-weight: 700;
            font-size: 13px;
            color: #4a3f8f;
            margin-bottom: 3px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
        .list-item-sub {
            font-size: 12px;
            color: #888;
        }
        .list-item-badge {
            padding: 5px 12px;
            border-radius: 15px;
            font-size: 11px;
            font-weight: 700;
            white-space: nowrap;
        }
        .badge-active { background: #cce5ff; color: #004085; }
        .badge-ok     { background: #d4edda; color: #155724; }
        .badge-late   { background: #f8d7da; color: #721c24; }

        .empty-state {
            text-align: center;
            padding: 40px 20px;
            color: #888;
        }
        .empty-state .icon { font-size: 45px; margin-bottom: 10px; }
        .empty-state p { font-size: 13px; }

        @media (max-width: 700px) {
            .chart-grid, .two-col-grid { grid-template-columns: 1fr; }
            .chart-body { height: 260px; }
        }
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

        <!-- PAGE TITLE -->
        <div class="page-title">
            <div>
                <h2>📊 Analytics Dashboard</h2>
                <p>Real-time insights into your library's performance</p>
            </div>
            <div class="live-badge">
                <span class="live-dot"></span> LIVE DATA
            </div>
        </div>

        <!-- KPI CARDS -->
        <div class="kpi-grid">
            <div class="kpi-card books">
                <span class="icon">📚</span>
                <div class="value"><%= totalTitles %></div>
                <div class="label">Book Titles</div>
                <div class="sub"><%= totalBooks %> total copies</div>
            </div>
            <div class="kpi-card members">
                <span class="icon">👥</span>
                <div class="value"><%= totalMembers %></div>
                <div class="label">Members</div>
                <div class="sub"><%= totalRecords %> total transactions</div>
            </div>
            <div class="kpi-card active">
                <span class="icon">📖</span>
                <div class="value"><%= activeLoans %></div>
                <div class="label">Active Loans</div>
                <div class="sub"><%= String.format("%.0f", availabilityRate) %>% available now</div>
            </div>
            <div class="kpi-card overdue">
                <span class="icon">⚠️</span>
                <div class="value"><%= overdueLoans %></div>
                <div class="label">Overdue</div>
                <div class="sub"><%= returnedLoans %> returned on time</div>
            </div>
            <div class="kpi-card rating">
                <span class="icon">⭐</span>
                <div class="value"><%= String.format("%.1f", avgRating) %></div>
                <div class="label">Avg Rating</div>
                <div class="sub"><%= totalReviews %> reviews</div>
            </div>
            <div class="kpi-card fines">
                <span class="icon">💰</span>
                <div class="value">₹<%= String.format("%.0f", totalFines) %></div>
                <div class="label">Pending Fines</div>
                <div class="sub">From overdue books</div>
            </div>
        </div>

        <!-- CHARTS ROW 1 -->
        <div class="chart-grid">

            <!-- Monthly Trend -->
            <div class="chart-card full-width">
                <div class="chart-header">
                    <span>📈 Borrowing Trend (Last 6 Months)</span>
                    <span class="badge">Monthly</span>
                </div>
                <div class="chart-body tall">
                    <canvas id="trendChart"></canvas>
                </div>
            </div>

            <!-- Category Distribution -->
            <div class="chart-card">
                <div class="chart-header">
                    <span>📂 Category Distribution</span>
                    <span class="badge">By Copies</span>
                </div>
                <div class="chart-body">
                    <canvas id="categoryChart"></canvas>
                </div>
            </div>

            <!-- Top Borrowed Books -->
            <div class="chart-card">
                <div class="chart-header">
                    <span>🔥 Top 5 Most Borrowed Books</span>
                    <span class="badge">All time</span>
                </div>
                <div class="chart-body">
                    <canvas id="topBooksChart"></canvas>
                </div>
            </div>

        </div>

        <!-- LISTS ROW -->
        <div class="two-col-grid">

            <!-- Overdue Alerts -->
            <div class="list-card">
                <div class="list-header warn">
                    <span>⚠️ Overdue Alerts</span>
                    <span class="count-badge"><%= overdueList.size() %> books</span>
                </div>
                <div class="list-body">
                    <% if (overdueList.isEmpty()) { %>
                        <div class="empty-state">
                            <div class="icon">🎉</div>
                            <p>Koi overdue book nahi hai — sab on time!</p>
                        </div>
                    <% } else {
                        for (String[] o : overdueList) {
                            String initial = o[0] != null && !o[0].isEmpty() ? o[0].substring(0,1).toUpperCase() : "?";
                    %>
                        <div class="list-item">
                            <div class="avatar-sm" style="background:linear-gradient(135deg,#e74c3c,#f8a5a0);"><%= initial %></div>
                            <div class="list-item-body">
                                <div class="list-item-title"><%= o[0] %></div>
                                <div class="list-item-sub">📖 <%= o[2] %> · Due <%= o[3] %></div>
                            </div>
                            <span class="list-item-badge badge-late"><%= o[4] %>d late</span>
                        </div>
                    <% } } %>
                </div>
            </div>

            <!-- Recent Activity -->
            <div class="list-card">
                <div class="list-header info">
                    <span>🕓 Recent Activity</span>
                    <span class="count-badge"><%= recentActivity.size() %> records</span>
                </div>
                <div class="list-body">
                    <% if (recentActivity.isEmpty()) { %>
                        <div class="empty-state">
                            <div class="icon">📭</div>
                            <p>Abhi tak koi activity nahi hui.</p>
                        </div>
                    <% } else {
                        for (String[] a : recentActivity) {
                            String initial = a[0] != null && !a[0].isEmpty() ? a[0].substring(0,1).toUpperCase() : "?";
                            boolean isActive = "active".equals(a[4]);
                    %>
                        <div class="list-item">
                            <div class="avatar-sm"><%= initial %></div>
                            <div class="list-item-body">
                                <div class="list-item-title"><%= a[0] %> borrowed "<%= a[1] %>"</div>
                                <div class="list-item-sub">
                                    📅 Issued: <%= a[2] %>
                                    <%= isActive ? "" : " · Returned: " + a[3] %>
                                </div>
                            </div>
                            <span class="list-item-badge <%= isActive ? "badge-active" : "badge-ok" %>">
                                <%= isActive ? "Active" : "Returned" %>
                            </span>
                        </div>
                    <% } } %>
                </div>
            </div>

        </div>

        <!-- TOP MEMBERS CHART -->
        <div class="chart-grid">
            <div class="chart-card full-width">
                <div class="chart-header">
                    <span>🏆 Top 5 Most Active Members</span>
                    <span class="badge">By total borrows</span>
                </div>
                <div class="chart-body tall">
                    <canvas id="topMembersChart"></canvas>
                </div>
            </div>
        </div>

    </div>

    <script>
        // ============================================
        // DATA FROM JSP (passed to JS)
        // ============================================

        // Category data
        var catLabels = [
            <% for (int i = 0; i < categoryData.size(); i++) {
                if (i > 0) out.print(",");
                out.print("\"" + categoryData.get(i)[0].replace("\"", "\\\"") + "\"");
            } %>
        ];
        var catValues = [<% for (int i = 0; i < categoryData.size(); i++) {
            if (i > 0) out.print(",");
            out.print(categoryData.get(i)[2]);
        } %>];

        // Top books
        var topBooksLabels = [
            <% for (int i = 0; i < topBooksData.size(); i++) {
                if (i > 0) out.print(",");
                String t = topBooksData.get(i)[0];
                if (t.length() > 25) t = t.substring(0, 22) + "...";
                out.print("\"" + t.replace("\"", "\\\"") + "\"");
            } %>
        ];
        var topBooksValues = [<% for (int i = 0; i < topBooksData.size(); i++) {
            if (i > 0) out.print(",");
            out.print(topBooksData.get(i)[2]);
        } %>];

        // Top members
        var topMembersLabels = [
            <% for (int i = 0; i < topMembersData.size(); i++) {
                if (i > 0) out.print(",");
                out.print("\"" + topMembersData.get(i)[0].replace("\"", "\\\"") + "\"");
            } %>
        ];
        var topMembersValues = [<% for (int i = 0; i < topMembersData.size(); i++) {
            if (i > 0) out.print(",");
            out.print(topMembersData.get(i)[2]);
        } %>];

        // Monthly trend
        var trendLabels = [
            <% for (int i = 0; i < monthlyTrend.size(); i++) {
                if (i > 0) out.print(",");
                out.print("\"" + monthlyTrend.get(i)[0] + "\"");
            } %>
        ];
        var trendValues = [<% for (int i = 0; i < monthlyTrend.size(); i++) {
            if (i > 0) out.print(",");
            out.print(monthlyTrend.get(i)[1]);
        } %>];

        // ============================================
        // CHART 1: Borrowing Trend (Line)
        // ============================================
        var trendCtx = document.getElementById('trendChart');
        if (trendLabels.length > 0) {
            new Chart(trendCtx, {
                type: 'line',
                data: {
                    labels: trendLabels,
                    datasets: [{
                        label: 'Books Issued',
                        data: trendValues,
                        borderColor: '#667eea',
                        backgroundColor: 'rgba(102, 126, 234, 0.15)',
                        borderWidth: 3,
                        fill: true,
                        tension: 0.4,
                        pointBackgroundColor: '#764ba2',
                        pointBorderColor: '#fff',
                        pointBorderWidth: 2,
                        pointRadius: 6,
                        pointHoverRadius: 8
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: false }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            ticks: { stepSize: 1, color: '#666' },
                            grid: { color: '#eee' }
                        },
                        x: {
                            ticks: { color: '#666' },
                            grid: { display: false }
                        }
                    }
                }
            });
        } else {
            trendCtx.parentElement.innerHTML = '<div style="text-align:center;padding-top:80px;color:#888;">📭 No data available</div>';
        }

        // ============================================
        // CHART 2: Category Distribution (Doughnut)
        // ============================================
        var catCtx = document.getElementById('categoryChart');
        if (catLabels.length > 0) {
            new Chart(catCtx, {
                type: 'doughnut',
                data: {
                    labels: catLabels,
                    datasets: [{
                        data: catValues,
                        backgroundColor: [
                            '#667eea', '#27ae60', '#e74c3c', '#f39c12',
                            '#3498db', '#9b59b6', '#e67e22', '#1abc9c'
                        ],
                        borderWidth: 3,
                        borderColor: '#fff'
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'right',
                            labels: {
                                padding: 12,
                                font: { size: 12 },
                                color: '#333'
                            }
                        }
                    }
                }
            });
        } else {
            catCtx.parentElement.innerHTML = '<div style="text-align:center;padding-top:100px;color:#888;">📭 No data</div>';
        }

        // ============================================
        // CHART 3: Top Books (Horizontal Bar)
        // ============================================
        var topBooksCtx = document.getElementById('topBooksChart');
        if (topBooksLabels.length > 0) {
            new Chart(topBooksCtx, {
                type: 'bar',
                data: {
                    labels: topBooksLabels,
                    datasets: [{
                        label: 'Times Borrowed',
                        data: topBooksValues,
                        backgroundColor: [
                            '#667eea', '#764ba2', '#f39c12', '#27ae60', '#e74c3c'
                        ],
                        borderRadius: 8,
                        borderSkipped: false
                    }]
                },
                options: {
                    indexAxis: 'y',
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: false }
                    },
                    scales: {
                        x: {
                            beginAtZero: true,
                            ticks: { stepSize: 1, color: '#666' },
                            grid: { color: '#eee' }
                        },
                        y: {
                            ticks: { color: '#333', font: { size: 11 } },
                            grid: { display: false }
                        }
                    }
                }
            });
        } else {
            topBooksCtx.parentElement.innerHTML = '<div style="text-align:center;padding-top:100px;color:#888;">📭 No data</div>';
        }

        // ============================================
        // CHART 4: Top Members (Bar)
        // ============================================
        var topMembersCtx = document.getElementById('topMembersChart');
        if (topMembersLabels.length > 0) {
            new Chart(topMembersCtx, {
                type: 'bar',
                data: {
                    labels: topMembersLabels,
                    datasets: [{
                        label: 'Total Borrows',
                        data: topMembersValues,
                        backgroundColor: 'rgba(102, 126, 234, 0.85)',
                        borderColor: '#667eea',
                        borderWidth: 2,
                        borderRadius: 10,
                        borderSkipped: false,
                        hoverBackgroundColor: '#764ba2'
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: false }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            ticks: { stepSize: 1, color: '#666' },
                            grid: { color: '#eee' }
                        },
                        x: {
                            ticks: { color: '#333', font: { size: 12 } },
                            grid: { display: false }
                        }
                    }
                }
            });
        } else {
            topMembersCtx.parentElement.innerHTML = '<div style="text-align:center;padding-top:100px;color:#888;">📭 No data</div>';
        }
    </script>

</body>
</html>