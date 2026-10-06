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

    // Search parameter
    String search = request.getParameter("search");
    if (search == null) search = "";

    // Delete message
    String msg = request.getParameter("msg");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>All Members - Library Management System</title>
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
            max-width: 1150px;
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

        .btn-add {
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
        .btn-add:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(0,0,0,0.25);
        }

        /* ---------- SEARCH BAR ---------- */
        .search-bar {
            padding: 20px 30px;
            background: #f9f9ff;
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

        /* ---------- MESSAGES ---------- */
        .msg {
            padding: 15px 20px;
            border-radius: 10px;
            margin: 20px 30px;
            font-weight: 600;
            font-size: 14px;
        }
        .msg.success {
            background: #d4edda;
            color: #155724;
            border-left: 5px solid #28a745;
        }
        .msg.error {
            background: #f8d7da;
            color: #721c24;
            border-left: 5px solid #dc3545;
        }

        /* ---------- TABLE ---------- */
        .table-wrap { padding: 20px 30px 30px; overflow-x: auto; }

        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }
        thead th {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            padding: 14px 15px;
            text-align: left;
            font-weight: 600;
            font-size: 13px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        thead th:first-child { border-radius: 10px 0 0 0; }
        thead th:last-child  { border-radius: 0 10px 0 0; }

        tbody td {
            padding: 14px 15px;
            border-bottom: 1px solid #eee;
            color: #333;
        }
        tbody tr:hover { background: #f9f9ff; }
        tbody tr:last-child td { border-bottom: none; }

        .avatar {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 36px;
            height: 36px;
            border-radius: 50%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            font-weight: 700;
            font-size: 14px;
            margin-right: 10px;
        }
        .member-info {
            display: flex;
            align-items: center;
        }

        .badge {
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 700;
        }
        .badge-active    { background: #d4edda; color: #155724; }
        .badge-inactive  { background: #e2e3e5; color: #383d41; }
        .badge-loans     { background: #cce5ff; color: #004085; }

        .btn-icon {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 8px;
            text-decoration: none;
            font-size: 12px;
            font-weight: 600;
            transition: 0.3s;
            margin-right: 5px;
        }
        .btn-edit   { background: #ffeaa7; color: #b8860b; }
        .btn-edit:hover { background: #f7d96c; }
        .btn-del    { background: #fab1a0; color: #b8230b; }
        .btn-del:hover { background: #ff7675; color: #fff; }
        .btn-hist   { background: #cce5ff; color: #004085; }
        .btn-hist:hover { background: #99caff; }

        /* ---------- EMPTY STATE ---------- */
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
                    <h2>👥 All Members</h2>
                    <p>Complete list of registered library members</p>
                </div>
                <a href="addMember.jsp" class="btn-add">➕ Add New Member</a>
            </div>

            <%-- Messages --%>
            <% if ("deleted".equals(msg)) { %>
                <div class="msg success">✅ Member deleted successfully!</div>
            <% } else if ("notfound".equals(msg)) { %>
                <div class="msg error">❌ Member not found!</div>
            <% } else if ("hasloans".equals(msg)) { %>
                <div class="msg error">⚠️ Cannot delete this member — they still have books issued.</div>
            <% } %>

            <!-- SEARCH BAR -->
            <form class="search-bar" action="listMembers.jsp" method="get">
                <input type="text" name="search"
                       placeholder="🔍 Search by name, member ID or email..."
                       value="<%= search %>">
                <button type="submit">Search</button>
                <% if (!search.isEmpty()) { %>
                    <a href="listMembers.jsp">✖ Clear</a>
                <% } %>
            </form>

            <%
                int totalMembers = 0;
                int withLoans = 0;
                int withoutLoans = 0;
                boolean hasRows = false;
            %>

            <!-- TABLE -->
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Member</th>
                            <th>Member ID</th>
                            <th>Email</th>
                            <th>Active Loans</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        try {
                            DBDatabaseConnection db = new DBDatabaseConnection();

                            String sql;
                            if (search.trim().isEmpty()) {
                                sql = "SELECT m.member_id, m.name, m.email, " +
                                      "(SELECT COUNT(*) FROM borrowing_records br " +
                                      " WHERE br.member_id = m.member_id AND br.return_date IS NULL) AS active_loans " +
                                      "FROM members m ORDER BY m.member_id";
                                db.pstmt = db.con.prepareStatement(sql);
                            } else {
                                sql = "SELECT m.member_id, m.name, m.email, " +
                                      "(SELECT COUNT(*) FROM borrowing_records br " +
                                      " WHERE br.member_id = m.member_id AND br.return_date IS NULL) AS active_loans " +
                                      "FROM members m " +
                                      "WHERE m.member_id LIKE ? OR m.name LIKE ? OR m.email LIKE ? " +
                                      "ORDER BY m.member_id";
                                db.pstmt = db.con.prepareStatement(sql);
                                String like = "%" + search.trim() + "%";
                                db.pstmt.setString(1, like);
                                db.pstmt.setString(2, like);
                                db.pstmt.setString(3, like);
                            }

                            db.rst = db.pstmt.executeQuery();
                            int i = 0;
                            while (db.rst.next()) {
                                hasRows = true;
                                i++;
                                totalMembers++;

                                String mid  = db.rst.getString("member_id");
                                String mnm  = db.rst.getString("name");
                                String mem  = db.rst.getString("email");
                                int loans   = db.rst.getInt("active_loans");

                                if (loans > 0) withLoans++;
                                else withoutLoans++;

                                // Initial for avatar
                                String initial = mnm != null && !mnm.isEmpty()
                                                 ? mnm.substring(0, 1).toUpperCase()
                                                 : "?";

                                String statusClass = loans > 0 ? "badge-active" : "badge-inactive";
                                String statusText  = loans > 0 ? "Active" : "No Loans";
                    %>
                        <tr>
                            <td><%= i %></td>
                            <td>
                                <div class="member-info">
                                    <span class="avatar"><%= initial %></span>
                                    <strong><%= mnm %></strong>
                                </div>
                            </td>
                            <td><strong><%= mid %></strong></td>
                            <td><%= mem %></td>
                            <td>
                                <% if (loans > 0) { %>
                                    <span class="badge badge-loans"><%= loans %> book<%= loans > 1 ? "s" : "" %></span>
                                <% } else { %>
                                    <span style="color:#888;">—</span>
                                <% } %>
                            </td>
                            <td><span class="badge <%= statusClass %>"><%= statusText %></span></td>
                            <td>
                                <a href="memberHistory.jsp?member_id=<%= mid %>" class="btn-icon btn-hist">📋 History</a>
                                <a href="editMember.jsp?member_id=<%= mid %>" class="btn-icon btn-edit">✏️ Edit</a>
                                <a href="deleteMember.jsp?member_id=<%= mid %>"
                                   class="btn-icon btn-del"
                                   onclick="return confirm('Are you sure you want to delete this member?');">🗑️ Delete</a>
                            </td>
                        </tr>
                    <%
                            }
                            db.con.close();
                        } catch (Exception e) {
                            out.println("<tr><td colspan='7' style='color:red;text-align:center;padding:20px;'>Error: " + e.getMessage() + "</td></tr>");
                        }

                        if (!hasRows) {
                    %>
                        <tr>
                            <td colspan="7">
                                <div class="empty">
                                    <div class="icon">📭</div>
                                    <h3>No Members Found</h3>
                                    <p>
                                        <%= search.trim().isEmpty()
                                            ? "Abhi tak koi member register nahi hua."
                                            : "Search \"" + search + "\" ke liye koi member nahi mila." %>
                                    </p>
                                    <a href="addMember.jsp">➕ Add First Member</a>
                                </div>
                            </td>
                        </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>

        </div>

        <!-- SUMMARY STRIP -->
        <% if (hasRows) { %>
        <div style="display:flex;gap:15px;margin-top:20px;flex-wrap:wrap;">
            <div style="flex:1;min-width:180px;background:#fff;border-radius:12px;padding:18px 22px;box-shadow:0 6px 20px rgba(0,0,0,0.1);border-left:5px solid #667eea;">
                <div style="font-size:12px;color:#777;text-transform:uppercase;letter-spacing:1px;font-weight:700;">Total Members</div>
                <div style="font-size:26px;color:#4a3f8f;font-weight:800;margin-top:4px;"><%= totalMembers %></div>
            </div>
            <div style="flex:1;min-width:180px;background:#fff;border-radius:12px;padding:18px 22px;box-shadow:0 6px 20px rgba(0,0,0,0.1);border-left:5px solid #27ae60;">
                <div style="font-size:12px;color:#777;text-transform:uppercase;letter-spacing:1px;font-weight:700;">With Active Loans</div>
                <div style="font-size:26px;color:#1e8449;font-weight:800;margin-top:4px;"><%= withLoans %></div>
            </div>
            <div style="flex:1;min-width:180px;background:#fff;border-radius:12px;padding:18px 22px;box-shadow:0 6px 20px rgba(0,0,0,0.1);border-left:5px solid #95a5a6;">
                <div style="font-size:12px;color:#777;text-transform:uppercase;letter-spacing:1px;font-weight:700;">No Active Loans</div>
                <div style="font-size:26px;color:#5d6d7e;font-weight:800;margin-top:4px;"><%= withoutLoans %></div>
            </div>
        </div>
        <% } %>

    </div>

</body>
</html>