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

    String msg = "";
    String msgType = "";

    // ---------- FORM SUBMIT ----------
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String book_number = request.getParameter("book_number");
        String title       = request.getParameter("title");
        String author      = request.getParameter("author");
        String category    = request.getParameter("category");
        String description = request.getParameter("description");
        String totalStr    = request.getParameter("total_copies");

        if (book_number != null && !book_number.trim().isEmpty()
            && title != null && !title.trim().isEmpty()
            && author != null && !author.trim().isEmpty()
            && totalStr != null && !totalStr.trim().isEmpty()) {
            try {
                int total = Integer.parseInt(totalStr);
                if (total <= 0) throw new NumberFormatException();

                DBDatabaseConnection db = new DBDatabaseConnection();

                // Duplicate check
                db.pstmt = db.con.prepareStatement("SELECT book_number FROM books WHERE book_number = ?");
                db.pstmt.setString(1, book_number);
                db.rst = db.pstmt.executeQuery();

                if (db.rst.next()) {
                    msg = "Book Number <b>" + book_number + "</b> already exists!";
                    msgType = "error";
                } else {
                    String sql = "INSERT INTO books (book_number, title, author, category, description, total_copies, available_copies, avg_rating) " +
                                 "VALUES (?, ?, ?, ?, ?, ?, ?, 0)";
                    db.pstmt2 = db.con.prepareStatement(sql);
                    db.pstmt2.setString(1, book_number);
                    db.pstmt2.setString(2, title);
                    db.pstmt2.setString(3, author);
                    db.pstmt2.setString(4, category);
                    db.pstmt2.setString(5, description);
                    db.pstmt2.setInt(6, total);
                    db.pstmt2.setInt(7, total);

                    int rows = db.pstmt2.executeUpdate();
                    if (rows > 0) {
                        msg = "Book <b>" + title + "</b> added successfully!";
                        msgType = "success";
                    }
                }
                db.con.close();
            } catch (NumberFormatException ne) {
                msg = "Total copies must be a valid number greater than 0.";
                msgType = "error";
            } catch (Exception e) {
                msg = "Error: " + e.getMessage();
                msgType = "error";
            }
        } else {
            msg = "Please fill all required fields!";
            msgType = "error";
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Add Book - Library Management System</title>
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

        .container { max-width: 650px; margin: 0 auto; padding: 0 20px; }
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

        form { padding: 30px; }
        .form-group { margin-bottom: 18px; }
        .form-group label {
            display: block;
            font-weight: 600;
            margin-bottom: 8px;
            color: #4a3f8f;
            font-size: 14px;
        }
        .form-group input,
        .form-group select,
        .form-group textarea {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            font-size: 15px;
            transition: 0.3s;
            background: #f9f9ff;
            font-family: inherit;
        }
        .form-group textarea { resize: vertical; min-height: 90px; }
        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            border-color: #667eea;
            outline: none;
            background: #fff;
            box-shadow: 0 0 0 4px rgba(102,126,234,0.1);
        }
        .hint {
            display: block;
            font-size: 12px;
            color: #888;
            margin-top: 6px;
        }

        .btn-row { display: flex; gap: 12px; margin-top: 10px; }
        .btn-primary, .btn-secondary {
            padding: 13px 25px;
            border: none;
            border-radius: 10px;
            font-size: 15px;
            font-weight: 600;
            cursor: pointer;
            text-decoration: none;
            text-align: center;
            transition: 0.3s;
            display: inline-block;
        }
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            flex: 1;
        }
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 20px rgba(102,126,234,0.4);
        }
        .btn-secondary { background: #f0f0f5; color: #4a3f8f; }
        .btn-secondary:hover { background: #e0e0ea; }

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
        .msg.error {
            background: #f8d7da;
            color: #721c24;
            border-left: 5px solid #dc3545;
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
                <h2>➕ Add New Book</h2>
                <p>Fill the book details below</p>
            </div>

            <% if (!msg.isEmpty()) { %>
                <div class="msg <%= msgType %>"><%= msg %></div>
            <% } %>

            <form action="addBook.jsp" method="post">
                <div class="form-group">
                    <label>📘 Book Number <span style="color:#e74c3c;">*</span></label>
                    <input type="text" name="book_number" placeholder="e.g. BK005" required>
                </div>

                <div class="form-group">
                    <label>📖 Title <span style="color:#e74c3c;">*</span></label>
                    <input type="text" name="title" placeholder="e.g. Clean Code" required>
                </div>

                <div class="form-group">
                    <label>✍️ Author <span style="color:#e74c3c;">*</span></label>
                    <input type="text" name="author" placeholder="e.g. Robert C. Martin" required>
                </div>

                <div class="form-group">
                    <label>📂 Category</label>
                    <select name="category">
                        <option value="General">General</option>
                        <option value="Programming">Programming</option>
                        <option value="Fiction">Fiction</option>
                        <option value="Non-Fiction">Non-Fiction</option>
                        <option value="Biography">Biography</option>
                        <option value="Self-Help">Self-Help</option>
                        <option value="Science">Science</option>
                        <option value="History">History</option>
                        <option value="Indian Authors">Indian Authors</option>
                        <option value="Children">Children</option>
                    </select>
                </div>

                <div class="form-group">
                    <label>📝 Description</label>
                    <textarea name="description" placeholder="Short summary of the book (for search & recommendations)"></textarea>
                    <span class="hint">Ye description search me help karegi aur recommendations me kaam aayegi.</span>
                </div>

                <div class="form-group">
                    <label>🔢 Total Copies <span style="color:#e74c3c;">*</span></label>
                    <input type="number" name="total_copies" min="1" value="1" required>
                </div>

                <div class="btn-row">
                    <button type="submit" class="btn-primary">✅ Add Book</button>
                    <a href="index.jsp" class="btn-secondary">⬅ Back</a>
                </div>
            </form>
        </div>
    </div>

</body>
</html>