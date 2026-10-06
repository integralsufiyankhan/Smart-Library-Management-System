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

    // ---------- BOOK NUMBER ----------
    String book_number = request.getParameter("book_number");
    if (book_number == null || book_number.trim().isEmpty()) {
        response.sendRedirect("listBooks.jsp?msg=notfound");
        return;
    }

    // ---------- VARIABLES (form fields) ----------
    String title = "";
    String author = "";
    int totalCopies = 0;
    int availableCopies = 0;
    int issuedCopies = 0;
    boolean bookFound = false;

    String msg = "";
    String msgType = "";

    // ---------- HANDLE FORM SUBMIT ----------
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String newTitle = request.getParameter("title");
        String newAuthor = request.getParameter("author");
        String totalStr = request.getParameter("total_copies");

        if (newTitle != null && !newTitle.trim().isEmpty()
            && newAuthor != null && !newAuthor.trim().isEmpty()
            && totalStr != null && !totalStr.trim().isEmpty()) {
            try {
                int newTotal = Integer.parseInt(totalStr);
                if (newTotal <= 0) throw new NumberFormatException();

                DBDatabaseConnection db = new DBDatabaseConnection();

                // Get current issued count
                db.pstmt = db.con.prepareStatement("SELECT total_copies, available_copies FROM books WHERE book_number = ?");
                db.pstmt.setString(1, book_number);
                db.rst = db.pstmt.executeQuery();

                if (db.rst.next()) {
                    int oldTotal = db.rst.getInt("total_copies");
                    int oldAvail = db.rst.getInt("available_copies");
                    int issued = oldTotal - oldAvail;

                    if (newTotal < issued) {
                        msg = "Total copies cannot be less than <b>" + issued + "</b> (currently issued to members).";
                        msgType = "error";
                    } else {
                        int newAvail = newTotal - issued;

                        db.pstmt2 = db.con.prepareStatement(
                            "UPDATE books SET title = ?, author = ?, total_copies = ?, available_copies = ? WHERE book_number = ?");
                        db.pstmt2.setString(1, newTitle);
                        db.pstmt2.setString(2, newAuthor);
                        db.pstmt2.setInt(3, newTotal);
                        db.pstmt2.setInt(4, newAvail);
                        db.pstmt2.setString(5, book_number);

                        int rows = db.pstmt2.executeUpdate();
                        if (rows > 0) {
                            msg = "Book <b>" + newTitle + "</b> updated successfully!";
                            msgType = "success";
                        } else {
                            msg = "Failed to update book.";
                            msgType = "error";
                        }
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
            msg = "Please fill all fields!";
            msgType = "error";
        }
    }

    // ---------- FETCH FRESH BOOK DATA ----------
    try {
        DBDatabaseConnection db = new DBDatabaseConnection();
        db.pstmt = db.con.prepareStatement("SELECT * FROM books WHERE book_number = ?");
        db.pstmt.setString(1, book_number);
        db.rst = db.pstmt.executeQuery();

        if (db.rst.next()) {
            bookFound = true;
            title = db.rst.getString("title");
            author = db.rst.getString("author");
            totalCopies = db.rst.getInt("total_copies");
            availableCopies = db.rst.getInt("available_copies");
            issuedCopies = totalCopies - availableCopies;
        }
        db.con.close();
    } catch (Exception e) {
        msg = "Error loading book: " + e.getMessage();
        msgType = "error";
    }

    if (!bookFound) {
        response.sendRedirect("listBooks.jsp?msg=notfound");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Edit Book - Library Management System</title>
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
            max-width: 640px;
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

        /* ---------- INFO STRIP ---------- */
        .info-strip {
            display: flex;
            background: #f9f9ff;
            border-bottom: 1px solid #e0e0ea;
        }
        .info-strip .info-box {
            flex: 1;
            padding: 15px 20px;
            text-align: center;
            border-right: 1px solid #e0e0ea;
        }
        .info-strip .info-box:last-child { border-right: none; }
        .info-box .num {
            font-size: 22px;
            font-weight: 800;
            color: #4a3f8f;
        }
        .info-box .lbl {
            font-size: 11px;
            color: #888;
            text-transform: uppercase;
            letter-spacing: 1px;
            font-weight: 700;
            margin-top: 3px;
        }
        .info-box.issued .num { color: #e74c3c; }
        .info-box.avail .num { color: #27ae60; }

        /* ---------- FORM ---------- */
        form { padding: 30px; }

        .form-group { margin-bottom: 18px; }
        .form-group label {
            display: block;
            font-weight: 600;
            margin-bottom: 8px;
            color: #4a3f8f;
            font-size: 14px;
        }
        .form-group input {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            font-size: 15px;
            transition: 0.3s;
            background: #f9f9ff;
        }
        .form-group input:focus {
            border-color: #667eea;
            outline: none;
            background: #fff;
            box-shadow: 0 0 0 4px rgba(102,126,234,0.1);
        }
        .form-group input:disabled {
            background: #f0f0f0;
            color: #888;
            cursor: not-allowed;
        }
        .hint {
            display: block;
            font-size: 12px;
            color: #888;
            margin-top: 6px;
        }

        /* ---------- BUTTONS ---------- */
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
        .btn-secondary {
            background: #f0f0f5;
            color: #4a3f8f;
        }
        .btn-secondary:hover { background: #e0e0ea; }

        /* ---------- MESSAGES ---------- */
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
                <h2>✏️ Edit Book</h2>
                <p>Update book details below</p>
            </div>

            <!-- INFO STRIP -->
            <div class="info-strip">
                <div class="info-box">
                    <div class="num"><%= totalCopies %></div>
                    <div class="lbl">Total</div>
                </div>
                <div class="info-box avail">
                    <div class="num"><%= availableCopies %></div>
                    <div class="lbl">Available</div>
                </div>
                <div class="info-box issued">
                    <div class="num"><%= issuedCopies %></div>
                    <div class="lbl">Issued</div>
                </div>
            </div>

            <% if (!msg.isEmpty()) { %>
                <div class="msg <%= msgType %>"><%= msg %></div>
            <% } %>

            <form action="editBook.jsp?book_number=<%= book_number %>" method="post">
                <div class="form-group">
                    <label>📘 Book Number</label>
                    <input type="text" value="<%= book_number %>" disabled>
                    <span class="hint">Book number cannot be changed.</span>
                </div>

                <div class="form-group">
                    <label>📖 Title</label>
                    <input type="text" name="title" value="<%= title %>" required>
                </div>

                <div class="form-group">
                    <label>✍️ Author</label>
                    <input type="text" name="author" value="<%= author %>" required>
                </div>

                <div class="form-group">
                    <label>🔢 Total Copies</label>
                    <input type="number" name="total_copies" min="<%= issuedCopies > 0 ? issuedCopies : 1 %>"
                           value="<%= totalCopies %>" required>
                    <span class="hint">
                        <%= issuedCopies > 0
                            ? "Minimum allowed: " + issuedCopies + " (copies currently issued)."
                            : "Total copies in library." %>
                    </span>
                </div>

                <div class="btn-row">
                    <button type="submit" class="btn-primary">💾 Update Book</button>
                    <a href="listBooks.jsp" class="btn-secondary">⬅ Cancel</a>
                </div>
            </form>
        </div>
    </div>

</body>
</html>