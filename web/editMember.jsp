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

    // ---------- MEMBER ID ----------
    String member_id = request.getParameter("member_id");
    if (member_id == null || member_id.trim().isEmpty()) {
        response.sendRedirect("listMembers.jsp?msg=notfound");
        return;
    }

    // ---------- VARIABLES ----------
    String name = "";
    String email = "";
    int activeLoans = 0;
    int totalLoans = 0;
    boolean memberFound = false;

    String msg = "";
    String msgType = "";

    // ---------- HANDLE FORM SUBMIT ----------
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String newName  = request.getParameter("name");
        String newEmail = request.getParameter("email");

        if (newName != null && !newName.trim().isEmpty()
            && newEmail != null && !newEmail.trim().isEmpty()) {
            try {
                DBDatabaseConnection db = new DBDatabaseConnection();

                // Duplicate email check (excluding this member)
                db.pstmt = db.con.prepareStatement("SELECT member_id FROM members WHERE email = ? AND member_id != ?");
                db.pstmt.setString(1, newEmail);
                db.pstmt.setString(2, member_id);
                db.rst = db.pstmt.executeQuery();

                if (db.rst.next()) {
                    msg = "Email <b>" + newEmail + "</b> is already registered with another member.";
                    msgType = "error";
                } else {
                    db.pstmt2 = db.con.prepareStatement(
                        "UPDATE members SET name = ?, email = ? WHERE member_id = ?");
                    db.pstmt2.setString(1, newName);
                    db.pstmt2.setString(2, newEmail);
                    db.pstmt2.setString(3, member_id);

                    int rows = db.pstmt2.executeUpdate();
                    if (rows > 0) {
                        msg = "Member <b>" + newName + "</b> updated successfully!";
                        msgType = "success";
                    } else {
                        msg = "Failed to update member.";
                        msgType = "error";
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

    // ---------- FETCH FRESH MEMBER DATA ----------
    try {
        DBDatabaseConnection db = new DBDatabaseConnection();

        // Member info
        db.pstmt = db.con.prepareStatement("SELECT * FROM members WHERE member_id = ?");
        db.pstmt.setString(1, member_id);
        db.rst = db.pstmt.executeQuery();

        if (db.rst.next()) {
            memberFound = true;
            name  = db.rst.getString("name");
            email = db.rst.getString("email");
        }

        // Active loans count (still returned)
        db.pstmt2 = db.con.prepareStatement(
            "SELECT COUNT(*) AS cnt FROM borrowing_records WHERE member_id = ? AND return_date IS NULL");
        db.pstmt2.setString(1, member_id);
        ResultSet rs2 = db.pstmt2.executeQuery();
        if (rs2.next()) activeLoans = rs2.getInt("cnt");

        // Total loans count (all time)
        PreparedStatement ps3 = db.con.prepareStatement(
            "SELECT COUNT(*) AS cnt FROM borrowing_records WHERE member_id = ?");
        ps3.setString(1, member_id);
        ResultSet rs3 = ps3.executeQuery();
        if (rs3.next()) totalLoans = rs3.getInt("cnt");

        db.con.close();
    } catch (Exception e) {
        msg = "Error loading member: " + e.getMessage();
        msgType = "error";
    }

    if (!memberFound) {
        response.sendRedirect("listMembers.jsp?msg=notfound");
        return;
    }

    // Initial for avatar
    String initial = name != null && !name.isEmpty()
                     ? name.substring(0, 1).toUpperCase()
                     : "?";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Edit Member - Library Management System</title>
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
        .info-box.active .num { color: #27ae60; }
        .info-box.total .num { color: #667eea; }

        /* ---------- AVATAR ---------- */
        .avatar-wrap {
            padding: 25px 30px 10px;
            text-align: center;
        }
        .big-avatar {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 80px;
            height: 80px;
            border-radius: 50%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            font-weight: 800;
            font-size: 34px;
            box-shadow: 0 8px 20px rgba(102,126,234,0.35);
        }

        /* ---------- FORM ---------- */
        form { padding: 20px 30px 30px; }

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
            <a href="index.jsp" class="nav-btn home">🏠 Home</a>
            <a href="logout.jsp" class="nav-btn logout">Logout</a>
        </div>
    </div>

    <!-- MAIN CARD -->
    <div class="container">
        <div class="card">
            <div class="card-header">
                <h2>✏️ Edit Member</h2>
                <p>Update member details below</p>
            </div>

            <!-- INFO STRIP -->
            <div class="info-strip">
                <div class="info-box active">
                    <div class="num"><%= activeLoans %></div>
                    <div class="lbl">Active Loans</div>
                </div>
                <div class="info-box total">
                    <div class="num"><%= totalLoans %></div>
                    <div class="lbl">Total (All Time)</div>
                </div>
            </div>

            <!-- AVATAR -->
            <div class="avatar-wrap">
                <div class="big-avatar"><%= initial %></div>
            </div>

            <% if (!msg.isEmpty()) { %>
                <div class="msg <%= msgType %>"><%= msg %></div>
            <% } %>

            <form action="editMember.jsp?member_id=<%= member_id %>" method="post">
                <div class="form-group">
                    <label>🆔 Member ID</label>
                    <input type="text" value="<%= member_id %>" disabled>
                    <span class="hint">Member ID cannot be changed.</span>
                </div>

                <div class="form-group">
                    <label>📛 Full Name</label>
                    <input type="text" name="name" value="<%= name %>" required>
                </div>

                <div class="form-group">
                    <label>📧 Email Address</label>
                    <input type="email" name="email" value="<%= email %>" required>
                </div>

                <div class="btn-row">
                    <button type="submit" class="btn-primary">💾 Update Member</button>
                    <a href="listMembers.jsp" class="btn-secondary">⬅ Cancel</a>
                </div>
            </form>
        </div>
    </div>

</body>
</html>