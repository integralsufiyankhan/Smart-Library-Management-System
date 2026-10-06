<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="DB.DBDatabaseConnection" %>
<%
    // ---------- SESSION CHECK ----------
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=2");
        return;
    }

    // ---------- FORM SUBMIT HANDLE ----------
    String msg = "";
    String msgType = "";

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String member_id = request.getParameter("member_id");
        String name      = request.getParameter("name");
        String email     = request.getParameter("email");

        if (member_id != null && !member_id.trim().isEmpty()
            && name != null && !name.trim().isEmpty()
            && email != null && !email.trim().isEmpty()) {
            try {
                DBDatabaseConnection db = new DBDatabaseConnection();

                // Duplicate member_id check
                db.pstmt = db.con.prepareStatement("SELECT member_id FROM members WHERE member_id = ?");
                db.pstmt.setString(1, member_id);
                db.rst = db.pstmt.executeQuery();

                if (db.rst.next()) {
                    msg = "Member ID <b>" + member_id + "</b> already exists!";
                    msgType = "error";
                } else {
                    // Duplicate email check
                    db.pstmt = db.con.prepareStatement("SELECT member_id FROM members WHERE email = ?");
                    db.pstmt.setString(1, email);
                    db.rst = db.pstmt.executeQuery();

                    if (db.rst.next()) {
                        msg = "Email <b>" + email + "</b> is already registered!";
                        msgType = "error";
                    } else {
                        String sql = "INSERT INTO members (member_id, name, email) VALUES (?, ?, ?)";
                        db.pstmt2 = db.con.prepareStatement(sql);
                        db.pstmt2.setString(1, member_id);
                        db.pstmt2.setString(2, name);
                        db.pstmt2.setString(3, email);

                        int rows = db.pstmt2.executeUpdate();
                        if (rows > 0) {
                            msg = "Member <b>" + name + "</b> added successfully!";
                            msgType = "success";
                        }
                    }
                }
                db.con.close();
            } catch (Exception e) {
                msg = "Error: " + e.getMessage();
                msgType = "error";
            }
        } else {
            msg = "Please fill all fields!";
            msgType = "error";
        }
    }

    String adminName = (String) session.getAttribute("adminName");
    if (adminName == null) adminName = "Admin";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Add Member - Library Management System</title>
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
            max-width: 600px;
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
                <h2>👤 Add New Member</h2>
                <p>Register a new library member</p>
            </div>

            <% if (!msg.isEmpty()) { %>
                <div class="msg <%= msgType %>"><%= msg %></div>
            <% } %>

            <form action="addMember.jsp" method="post">
                <div class="form-group">
                    <label>🆔 Member ID</label>
                    <input type="text" name="member_id" placeholder="e.g. M003" required>
                    <span class="hint">Unique ID for each member (e.g. M001, M002...)</span>
                </div>

                <div class="form-group">
                    <label>📛 Full Name</label>
                    <input type="text" name="name" placeholder="e.g. Rahul Sharma" required>
                </div>

                <div class="form-group">
                    <label>📧 Email Address</label>
                    <input type="email" name="email" placeholder="e.g. rahul@email.com" required>
                </div>

                <div class="btn-row">
                    <button type="submit" class="btn-primary">✅ Add Member</button>
                    <a href="index.html" class="btn-secondary">⬅ Back</a>
                </div>
            </form>
        </div>
    </div>

</body>
</html>