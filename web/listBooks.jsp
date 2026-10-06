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

    String search = request.getParameter("search");
    if (search == null) search = "";

    String categoryFilter = request.getParameter("category");
    if (categoryFilter == null) categoryFilter = "All";

    String msg = request.getParameter("msg");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>All Books - Library Management System</title>
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

        .container { max-width: 1250px; margin: 0 auto; padding: 0 20px; }
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

        .search-bar {
            padding: 20px 30px;
            background: #f9f9ff;
            border-bottom: 1px solid #e0e0ea;
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        .search-bar input,
        .search-bar select {
            padding: 11px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            font-size: 14px;
            transition: 0.3s;
            background: #fff;
        }
        .search-bar input { flex: 1; min-width: 200px; }
        .search-bar select { min-width: 160px; }
        .search-bar input:focus,
        .search-bar select:focus {
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

        .msg {
            padding: 15px 20px;
            border-radius: 10px;
            margin: 20px 30px;
            font-weight: 600;
            font-size: 14px;
        }
        .msg.success { background: #d4edda; color: #155724; border-left: 5px solid #28a745; }
        .msg.error { background: #f8d7da; color: #721c24; border-left: 5px solid #dc3545; }

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
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        thead th:first-child { border-radius: 10px 0 0 0; }
        thead th:last-child  { border-radius: 0 10px 0 0; }

        tbody td {
            padding: 14px 15px;
            border-bottom: 1px solid #eee;
            color: #333;
            vertical-align: middle;
        }
        tbody tr:hover { background: #f9f9ff; }
        tbody tr:last-child td { border-bottom: none; }

        .cat-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 15px;
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

        .stars {
            color: #f39c12;
            font-size: 14px;
            white-space: nowrap;
        }
        .stars .empty { color: #ddd; }
        .rating-num {
            font-size: 11px;
            color: #666;
            margin-left: 4px;
            font-weight: 600;
        }

        .badge {
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 700;
            display: inline-block;
        }
        .badge-ok      { background: #d4edda; color: #155724; }
        .badge-low     { background: #fff3cd; color: #856404; }
        .badge-out     { background: #f8d7da; color: #721c24; }

        .btn-icon {
            display: inline-block;
            padding: 6px 10px;
            border-radius: 8px;
            text-decoration: none;
            font-size: 11px;
            font-weight: 600;
            transition: 0.3s;
            margin-right: 3px;
        }
        .btn-view { background: #cce5ff; color: #004085; }
        .btn-view:hover { background: #99caff; }
        .btn-edit { background: #ffeaa7; color: #b8860b; }
        .btn-edit:hover { background: #f7d96c; }
        .btn-del  { background: #fab1a0; color: #b8230b; }
        .btn-del:hover { background: #ff7675; color: #fff; }

        .empty { padding: 60px 30px; text-align: center; color: #888; }
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

    <div class="navbar">
        <h1>📚 Library Management System</h1>
        <div class="nav-right">
            <span>👤 <%= adminName %></span>
            <a href="index.html" class="nav-btn home">🏠 Home</a>
            <a href="logout.jsp" class="nav-btn logout">Logout</a>
        </div>
    </div>

    <div class="container">
        <div class="card">
            <div class="card-header">
                <div>
                    <h2>📖 All Books</h2>
                    <p>Complete catalog with categories & ratings</p>
                </div>
                <a href="addBook.jsp" class="btn-add">➕ Add New Book</a>
            </div>

            <% if ("deleted".equals(msg)) { %>
                <div class="msg success">✅ Book deleted successfully!</div>
            <% } else if ("notfound".equals(msg)) { %>
                <div class="msg error">❌ Book not found!</div>
            <% } else if ("hasloans".equals(msg)) { %>
                <div class="msg error">⚠️ Cannot delete — some copies are currently issued.</div>
            <% } %>

            <!-- SEARCH + FILTER -->
            <form class="search-bar" action="listBooks.jsp" method="get">
                <input type="text" name="search"
                       placeholder="🔍 Search by title, author or book number..."
                       value="<%= search %>">

                <select name="category">
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

                <button type="submit">Search</button>
                <% if (!search.isEmpty() || !"All".equals(categoryFilter)) { %>
                    <a href="listBooks.jsp">✖ Clear</a>
                <% } %>
            </form>

            <%
                int totalBooks = 0;
                int totalCopies = 0;
                int availableCopies = 0;
                boolean hasRows = false;
            %>

            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Book Number</th>
                            <th>Title</th>
                            <th>Author</th>
                            <th>Category</th>
                            <th>Rating</th>
                            <th>Available</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        try {
                            DBDatabaseConnection db = new DBDatabaseConnection();

                            StringBuilder sql = new StringBuilder(
                                "SELECT book_number, title, author, category, total_copies, available_copies, avg_rating " +
                                "FROM books WHERE 1=1 ");
                            boolean hasSearch = !search.trim().isEmpty();
                            boolean hasCat = !"All".equals(categoryFilter);

                            if (hasSearch) {
                                sql.append(" AND (book_number LIKE ? OR title LIKE ? OR author LIKE ? OR description LIKE ?) ");
                            }
                            if (hasCat) {
                                sql.append(" AND category = ? ");
                            }
                            sql.append(" ORDER BY book_number");

                            db.pstmt = db.con.prepareStatement(sql.toString());

                            int idx = 1;
                            if (hasSearch) {
                                String like = "%" + search.trim() + "%";
                                db.pstmt.setString(idx++, like);
                                db.pstmt.setString(idx++, like);
                                db.pstmt.setString(idx++, like);
                                db.pstmt.setString(idx++, like);
                            }
                            if (hasCat) {
                                db.pstmt.setString(idx++, categoryFilter);
                            }

                            db.rst = db.pstmt.executeQuery();
                            int i = 0;
                            while (db.rst.next()) {
                                hasRows = true;
                                i++;
                                totalBooks++;
                                int tot = db.rst.getInt("total_copies");
                                int av  = db.rst.getInt("available_copies");
                                double rating = db.rst.getDouble("avg_rating");
                                String cat = db.rst.getString("category");
                                if (cat == null) cat = "General";

                                totalCopies += tot;
                                availableCopies += av;

                                // Category badge class
                                String catClass = "cat-badge cat-" + cat.replace("-", "").replace(" ", "");

                                // Rating stars
                                int fullStars = (int) Math.round(rating);
                                StringBuilder stars = new StringBuilder();
                                for (int s = 1; s <= 5; s++) {
                                    stars.append(s <= fullStars ? "★" : "<span class='empty'>★</span>");
                                }

                                String statusClass, statusText;
                                if (av == 0) {
                                    statusClass = "badge-out"; statusText = "Out of Stock";
                                } else if (av <= 1) {
                                    statusClass = "badge-low"; statusText = "Low Stock";
                                } else {
                                    statusClass = "badge-ok"; statusText = "Available";
                                }
                    %>
                        <tr>
                            <td><%= i %></td>
                            <td><strong><%= db.rst.getString("book_number") %></strong></td>
                            <td>
                                <a href="bookDetails.jsp?book_number=<%= db.rst.getString("book_number") %>"
                                   style="color:#4a3f8f;text-decoration:none;font-weight:600;">
                                    <%= db.rst.getString("title") %>
                                </a>
                            </td>
                            <td><%= db.rst.getString("author") %></td>
                            <td><span class="<%= catClass %>"><%= cat %></span></td>
                            <td>
                                <div class="stars">
                                    <%= stars.toString() %>
                                    <% if (rating > 0) { %>
                                        <span class="rating-num"><%= String.format("%.1f", rating) %></span>
                                    <% } else { %>
                                        <span class="rating-num" style="color:#bbb;">—</span>
                                    <% } %>
                                </div>
                            </td>
                            <td><%= av %> / <%= tot %></td>
                            <td><span class="badge <%= statusClass %>"><%= statusText %></span></td>
                            <td style="white-space:nowrap;">
                                <a href="bookDetails.jsp?book_number=<%= db.rst.getString("book_number") %>" class="btn-icon btn-view">👁</a>
                                <a href="editBook.jsp?book_number=<%= db.rst.getString("book_number") %>" class="btn-icon btn-edit">✏️</a>
                                <a href="deleteBook.jsp?book_number=<%= db.rst.getString("book_number") %>"
                                   class="btn-icon btn-del"
                                   onclick="return confirm('Delete this book?');">🗑️</a>
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
                                    <h3>No Books Found</h3>
                                    <p>
                                        <%= !search.trim().isEmpty()
                                            ? "Search \"" + search + "\" ke liye koi book nahi mili."
                                            : "Is filter me koi book nahi hai." %>
                                    </p>
                                    <a href="listBooks.jsp">🔄 View All Books</a>
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
                <div style="font-size:12px;color:#777;text-transform:uppercase;letter-spacing:1px;font-weight:700;">Total Titles</div>
                <div style="font-size:26px;color:#4a3f8f;font-weight:800;margin-top:4px;"><%= totalBooks %></div>
            </div>
            <div style="flex:1;min-width:180px;background:#fff;border-radius:12px;padding:18px 22px;box-shadow:0 6px 20px rgba(0,0,0,0.1);border-left:5px solid #27ae60;">
                <div style="font-size:12px;color:#777;text-transform:uppercase;letter-spacing:1px;font-weight:700;">Total Copies</div>
                <div style="font-size:26px;color:#1e8449;font-weight:800;margin-top:4px;"><%= totalCopies %></div>
            </div>
            <div style="flex:1;min-width:180px;background:#fff;border-radius:12px;padding:18px 22px;box-shadow:0 6px 20px rgba(0,0,0,0.1);border-left:5px solid #e67e22;">
                <div style="font-size:12px;color:#777;text-transform:uppercase;letter-spacing:1px;font-weight:700;">Available Now</div>
                <div style="font-size:26px;color:#b9770e;font-weight:800;margin-top:4px;"><%= availableCopies %></div>
            </div>
        </div>
        <% } %>

    </div>

</body>
</html>