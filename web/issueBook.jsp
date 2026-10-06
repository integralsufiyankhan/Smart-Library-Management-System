<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="DB.DBDatabaseConnection" %>
<%
    // ---------- SESSION CHECK ----------
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=2");
        return;
    }

    String adminName = (String) session.getAttribute("adminName");
    if (adminName == null) adminName = "Admin";

    // Constants
    final int LOAN_PERIOD_DAYS = 14;
    final int MAX_LOANS_PER_MEMBER = 5;

    String msg = "";
    String msgType = "";
    String lastRecordId = "";
    String lastMemberName = "";
    String lastBookTitle = "";
    String lastIssueDate = "";
    String lastDueDate = "";

    // ---------- FORM SUBMIT HANDLE ----------
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String member_id = request.getParameter("member_id");
        String book_number = request.getParameter("book_number");

        if (member_id != null && !member_id.trim().isEmpty()
            && book_number != null && !book_number.trim().isEmpty()) {

            member_id = member_id.trim();
            book_number = book_number.trim();

            try {
                DBDatabaseConnection db = new DBDatabaseConnection();

                // ---------- CHECK 1: MEMBER EXISTS ----------
                db.pstmt = db.con.prepareStatement("SELECT name FROM members WHERE member_id = ?");
                db.pstmt.setString(1, member_id);
                db.rst = db.pstmt.executeQuery();

                if (!db.rst.next()) {
                    msg = "Member ID <b>" + member_id + "</b> not found!";
                    msgType = "error";
                } else {
                    String memberName = db.rst.getString("name");

                    // ---------- CHECK 2: BOOK EXISTS ----------
                    PreparedStatement ps2 = db.con.prepareStatement(
                        "SELECT title, total_copies, available_copies FROM books WHERE book_number = ?");
                    ps2.setString(1, book_number);
                    ResultSet rs2 = ps2.executeQuery();

                    if (!rs2.next()) {
                        msg = "Book Number <b>" + book_number + "</b> not found!";
                        msgType = "error";
                    } else {
                        String bookTitle = rs2.getString("title");
                        int availableCopies = rs2.getInt("available_copies");

                        // ---------- CHECK 3: BOOK AVAILABLE ----------
                        if (availableCopies <= 0) {
                            msg = "No copies of <b>" + bookTitle + "</b> are currently available!";
                            msgType = "error";
                        } else {

                            // ---------- CHECK 4: MEMBER ALREADY HAS THIS BOOK ----------
                            PreparedStatement ps4 = db.con.prepareStatement(
                                "SELECT record_id FROM borrowing_records " +
                                "WHERE member_id = ? AND book_number = ? AND return_date IS NULL");
                            ps4.setString(1, member_id);
                            ps4.setString(2, book_number);
                            ResultSet rs4 = ps4.executeQuery();

                            if (rs4.next()) {
                                msg = "<b>" + memberName + "</b> already has a copy of <b>" + bookTitle + "</b>!";
                                msgType = "error";
                            } else {

                                // ---------- CHECK 5: BORROWING LIMIT ----------
                                PreparedStatement ps5 = db.con.prepareStatement(
                                    "SELECT COUNT(*) AS cnt FROM borrowing_records " +
                                    "WHERE member_id = ? AND return_date IS NULL");
                                ps5.setString(1, member_id);
                                ResultSet rs5 = ps5.executeQuery();
                                int activeLoans = 0;
                                if (rs5.next()) activeLoans = rs5.getInt("cnt");

                                if (activeLoans >= MAX_LOANS_PER_MEMBER) {
                                    msg = "<b>" + memberName + "</b> has reached the borrowing limit of "
                                          + MAX_LOANS_PER_MEMBER + " books!";
                                    msgType = "error";
                                } else {

                                    // ---------- ALL CHECKS PASSED — ISSUE THE BOOK ----------
                                    LocalDate today = LocalDate.now();
                                    LocalDate dueDate = today.plusDays(LOAN_PERIOD_DAYS);

                                    // Insert borrowing record
                                    PreparedStatement psInsert = db.con.prepareStatement(
                                        "INSERT INTO borrowing_records " +
                                        "(member_id, book_number, issue_date, due_date, return_date) " +
                                        "VALUES (?, ?, ?, ?, NULL)",
                                        Statement.RETURN_GENERATED_KEYS);
                                    psInsert.setString(1, member_id);
                                    psInsert.setString(2, book_number);
                                    psInsert.setDate(3, java.sql.Date.valueOf(today));
                                    psInsert.setDate(4, java.sql.Date.valueOf(dueDate));

                                    int rows = psInsert.executeUpdate();

                                    if (rows > 0) {
                                        // Decrement available_copies
                                        PreparedStatement psUpdate = db.con.prepareStatement(
                                            "UPDATE books SET available_copies = available_copies - 1 " +
                                            "WHERE book_number = ?");
                                        psUpdate.setString(1, book_number);
                                        psUpdate.executeUpdate();

                                        // Get the record ID
                                        ResultSet keys = psInsert.getGeneratedKeys();
                                        if (keys.next()) lastRecordId = "R" + String.format("%05d", keys.getInt(1));

                                        lastMemberName = memberName;
                                        lastBookTitle = bookTitle;
                                        lastIssueDate = today.toString();
                                        lastDueDate = dueDate.toString();

                                        msg = "Book issued successfully!";
                                        msgType = "success";
                                    } else {
                                        msg = "Failed to issue the book. Please try again.";
                                        msgType = "error";
                                    }
                                }
                            }
                        }
                    }
                }
                db.con.close();
            } catch (Exception e) {
                msg = "Error: " + e.getMessage();
                msgType = "error";
            }
        } else {
            msg = "Please enter both Member ID and Book Number!";
            msgType = "error";
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Issue Book - Library Management System</title>
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
            max-width: 620px;
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

        .info-note {
            background: #e7f3ff;
            border-left: 5px solid #667eea;
            padding: 12px 18px;
            border-radius: 8px;
            margin: 0 30px 5px;
            font-size: 13px;
            color: #2c3e50;
            line-height: 1.7;
        }
        .info-note strong { color: #4a3f8f; }

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

        /* ---------- RECEIPT ---------- */
        .receipt {
            margin: 20px 30px 0;
            background: linear-gradient(135deg, #f9f9ff 0%, #eef1ff 100%);
            border: 2px dashed #667eea;
            border-radius: 12px;
            padding: 20px 25px;
        }
        .receipt h3 {
            color: #4a3f8f;
            font-size: 16px;
            margin-bottom: 15px;
            text-align: center;
            letter-spacing: 1px;
        }
        .receipt-row {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            font-size: 14px;
            border-bottom: 1px dashed #c5cae9;
        }
        .receipt-row:last-child { border-bottom: none; }
        .receipt-row .lbl {
            color: #666;
            font-weight: 600;
        }
        .receipt-row .val {
            color: #4a3f8f;
            font-weight: 700;
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
                <h2>📤 Issue Book</h2>
                <p>Lend a book to a member</p>
            </div>

            <% if (!msg.isEmpty()) { %>
                <div class="msg <%= msgType %>"><%= msg %></div>
            <% } %>

            <%-- SUCCESS RECEIPT --%>
            <% if ("success".equals(msgType)) { %>
                <div class="receipt">
                    <h3>🎫 ISSUE RECEIPT</h3>
                    <div class="receipt-row">
                        <span class="lbl">Record ID</span>
                        <span class="val"><%= lastRecordId %></span>
                    </div>
                    <div class="receipt-row">
                        <span class="lbl">Member</span>
                        <span class="val"><%= lastMemberName %></span>
                    </div>
                    <div class="receipt-row">
                        <span class="lbl">Book</span>
                        <span class="val"><%= lastBookTitle %></span>
                    </div>
                    <div class="receipt-row">
                        <span class="lbl">Issue Date</span>
                        <span class="val"><%= lastIssueDate %></span>
                    </div>
                    <div class="receipt-row">
                        <span class="lbl">Due Date</span>
                        <span class="val"><%= lastDueDate %></span>
                    </div>
                </div>
            <% } %>

            <form action="issueBook.jsp" method="post">
                <div class="form-group">
                    <label>🆔 Member ID</label>
                    <input type="text" name="member_id" placeholder="e.g. M001" required>
                    <span class="hint">Member ID jo register kiya tha.</span>
                </div>

                <div class="form-group">
                    <label>📘 Book Number</label>
                    <input type="text" name="book_number" placeholder="e.g. BK001" required>
                    <span class="hint">Book ka unique number.</span>
                </div>

                <div class="btn-row">
                    <button type="submit" class="btn-primary">📤 Issue Book</button>
                    <a href="index.html" class="btn-secondary">⬅ Back</a>
                </div>
            </form>

            <div class="info-note">
                <strong>ℹ️ Rules:</strong><br>
                • Loan period: <strong>14 days</strong><br>
                • Maximum <strong>5 books</strong> per member<br>
                • Same book ek member do baar nahi le sakta (jab tak return na kare)<br>
                • Late return par <strong>₹1/day</strong> fine
            </div>
            <div style="height:30px;"></div>
        </div>
    </div>

</body>
</html>