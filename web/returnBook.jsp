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

    final double FINE_PER_DAY = 1.00;

    String msg = "";
    String msgType = "";

    // Receipt variables
    String receiptMemberName = "";
    String receiptBookTitle = "";
    String receiptIssueDate = "";
    String receiptDueDate = "";
    String receiptReturnDate = "";
    long receiptDaysOverdue = 0;
    double receiptFine = 0;

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
                        "SELECT title FROM books WHERE book_number = ?");
                    ps2.setString(1, book_number);
                    ResultSet rs2 = ps2.executeQuery();

                    if (!rs2.next()) {
                        msg = "Book Number <b>" + book_number + "</b> not found!";
                        msgType = "error";
                    } else {
                        String bookTitle = rs2.getString("title");

                        // ---------- CHECK 3: ACTIVE LOAN EXISTS ----------
                        PreparedStatement ps3 = db.con.prepareStatement(
                            "SELECT record_id, issue_date, due_date FROM borrowing_records " +
                            "WHERE member_id = ? AND book_number = ? AND return_date IS NULL " +
                            "ORDER BY issue_date DESC LIMIT 1");
                        ps3.setString(1, member_id);
                        ps3.setString(2, book_number);
                        ResultSet rs3 = ps3.executeQuery();

                        if (!rs3.next()) {
                            msg = "<b>" + memberName + "</b> has no active loan for <b>" + bookTitle + "</b>!";
                            msgType = "error";
                        } else {
                            int recordId = rs3.getInt("record_id");
                            java.sql.Date issueDateSql = rs3.getDate("issue_date");
                            java.sql.Date dueDateSql = rs3.getDate("due_date");

                            LocalDate today = LocalDate.now();
                            LocalDate dueDate = dueDateSql.toLocalDate();

                            // ---------- CALCULATE FINE ----------
                            long daysOverdue = 0;
                            if (today.isAfter(dueDate)) {
                                daysOverdue = ChronoUnit.DAYS.between(dueDate, today);
                            }
                            double fine = daysOverdue * FINE_PER_DAY;

                            // ---------- UPDATE BORROWING RECORD ----------
                            PreparedStatement psUpdate = db.con.prepareStatement(
                                "UPDATE borrowing_records SET return_date = ? WHERE record_id = ?");
                            psUpdate.setDate(1, java.sql.Date.valueOf(today));
                            psUpdate.setInt(2, recordId);
                            int updateRows = psUpdate.executeUpdate();

                            if (updateRows > 0) {
                                // ---------- INCREMENT AVAILABLE COPIES ----------
                                PreparedStatement psInc = db.con.prepareStatement(
                                    "UPDATE books SET available_copies = available_copies + 1 " +
                                    "WHERE book_number = ? AND available_copies < total_copies");
                                psInc.setString(1, book_number);
                                psInc.executeUpdate();

                                // Set receipt data
                                receiptMemberName = memberName;
                                receiptBookTitle = bookTitle;
                                receiptIssueDate = issueDateSql.toString();
                                receiptDueDate = dueDateSql.toString();
                                receiptReturnDate = today.toString();
                                receiptDaysOverdue = daysOverdue;
                                receiptFine = fine;

                                if (daysOverdue > 0) {
                                    msg = "Book returned with a fine of <b>₹" +
                                          String.format("%.2f", fine) + "</b> (" +
                                          daysOverdue + " day(s) late).";
                                    msgType = "success";
                                } else {
                                    msg = "Book returned successfully on time! No fine.";
                                    msgType = "success";
                                }
                            } else {
                                msg = "Failed to record the return. Please try again.";
                                msgType = "error";
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
    <title>Return Book - Library Management System</title>
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
            background: #fff8e1;
            border-left: 5px solid #f39c12;
            padding: 12px 18px;
            border-radius: 8px;
            margin: 0 30px 5px;
            font-size: 13px;
            color: #7d5a00;
            line-height: 1.7;
        }
        .info-note strong { color: #b9770e; }

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
            background: linear-gradient(135deg, #f0fff4 0%, #d4f5e0 100%);
            border: 2px dashed #27ae60;
            border-radius: 12px;
            padding: 20px 25px;
        }
        .receipt.hasFine {
            background: linear-gradient(135deg, #fff5f5 0%, #ffe0e0 100%);
            border-color: #e74c3c;
        }
        .receipt h3 {
            color: #1e8449;
            font-size: 16px;
            margin-bottom: 15px;
            text-align: center;
            letter-spacing: 1px;
        }
        .receipt.hasFine h3 { color: #c0392b; }

        .receipt-row {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            font-size: 14px;
            border-bottom: 1px dashed #a8d5ba;
        }
        .receipt.hasFine .receipt-row {
            border-bottom-color: #f5b7b1;
        }
        .receipt-row:last-child { border-bottom: none; }
        .receipt-row .lbl {
            color: #666;
            font-weight: 600;
        }
        .receipt-row .val {
            color: #1e8449;
            font-weight: 700;
        }
        .receipt.hasFine .receipt-row .val {
            color: #c0392b;
        }

        .fine-badge {
            text-align: center;
            margin-top: 15px;
            padding: 12px;
            background: #fff;
            border-radius: 10px;
            font-weight: 800;
            font-size: 18px;
        }
        .fine-badge.no-fine { color: #1e8449; }
        .fine-badge.yes-fine { color: #c0392b; }
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
                <h2>📥 Return Book</h2>
                <p>Receive a book back from a member</p>
            </div>

            <% if (!msg.isEmpty()) { %>
                <div class="msg <%= msgType %>"><%= msg %></div>
            <% } %>

            <%-- RETURN RECEIPT --%>
            <% if ("success".equals(msgType)) {
                 boolean hasFine = receiptDaysOverdue > 0;
            %>
                <div class="receipt <%= hasFine ? "hasFine" : "" %>">
                    <h3>🎫 RETURN RECEIPT</h3>
                    <div class="receipt-row">
                        <span class="lbl">Member</span>
                        <span class="val"><%= receiptMemberName %></span>
                    </div>
                    <div class="receipt-row">
                        <span class="lbl">Book</span>
                        <span class="val"><%= receiptBookTitle %></span>
                    </div>
                    <div class="receipt-row">
                        <span class="lbl">Issue Date</span>
                        <span class="val"><%= receiptIssueDate %></span>
                    </div>
                    <div class="receipt-row">
                        <span class="lbl">Due Date</span>
                        <span class="val"><%= receiptDueDate %></span>
                    </div>
                    <div class="receipt-row">
                        <span class="lbl">Return Date</span>
                        <span class="val"><%= receiptReturnDate %></span>
                    </div>

                    <div class="fine-badge <%= hasFine ? "yes-fine" : "no-fine" %>">
                        <%= hasFine
                            ? "⚠️ Fine: ₹" + String.format("%.2f", receiptFine) + " (" + receiptDaysOverdue + " day late)"
                            : "✅ No Fine — Returned on Time!" %>
                    </div>
                </div>
            <% } %>

            <form action="returnBook.jsp" method="post">
                <div class="form-group">
                    <label>🆔 Member ID</label>
                    <input type="text" name="member_id" placeholder="e.g. M001" required>
                </div>

                <div class="form-group">
                    <label>📘 Book Number</label>
                    <input type="text" name="book_number" placeholder="e.g. BK001" required>
                </div>

                <div class="btn-row">
                    <button type="submit" class="btn-primary">📥 Return Book</button>
                    <a href="index.html" class="btn-secondary">⬅ Back</a>
                </div>
            </form>

            <div class="info-note">
                <strong>⚠️ Fine Rules:</strong><br>
                • Loan period: 14 days<br>
                • Late return: <strong>₹1 per day</strong> after due date<br>
                • Fine auto-calculate hoga aaj ki date se
            </div>
            <div style="height:30px;"></div>
        </div>
    </div>

</body>
</html>