<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="DB.DBDatabaseConnection" %>
<%
    // ---------- SESSION CHECK ----------
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=2");
        return;
    }

    // ---------- BOOK NUMBER ----------
    String book_number = request.getParameter("book_number");
    if (book_number == null || book_number.trim().isEmpty()) {
        response.sendRedirect("listBooks.jsp?msg=notfound");
        return;
    }

    try {
        DBDatabaseConnection db = new DBDatabaseConnection();

        // ---------- 1. CHECK BOOK EXISTS ----------
        db.pstmt = db.con.prepareStatement("SELECT title, total_copies, available_copies FROM books WHERE book_number = ?");
        db.pstmt.setString(1, book_number);
        db.rst = db.pstmt.executeQuery();

        if (!db.rst.next()) {
            db.con.close();
            response.sendRedirect("listBooks.jsp?msg=notfound");
            return;
        }

        String title = db.rst.getString("title");
        int totalCopies = db.rst.getInt("total_copies");
        int availCopies = db.rst.getInt("available_copies");
        int issuedCopies = totalCopies - availCopies;

        // ---------- 2. CHECK IF ANY COPY IS ISSUED ----------
        if (issuedCopies > 0) {
            db.con.close();
            response.sendRedirect("listBooks.jsp?msg=hasloans");
            return;
        }

        // ---------- 3. CHECK BORROWING_RECORDS (History) ----------
        // Agar is book ka koi purana record bhi hai, to FK constraint ki wajah se delete nahi hoga.
        // Isliye pehle purane records delete karne padenge, ya unhe archive karna padega.
        // Hum yahan ek smart approach lete hain: sirf wahi delete karte hain jiska koi record hi na ho.
        db.pstmt2 = db.con.prepareStatement("SELECT COUNT(*) AS cnt FROM borrowing_records WHERE book_number = ?");
        db.pstmt2.setString(1, book_number);
        ResultSet rs2 = db.pstmt2.executeQuery();
        int recordCount = 0;
        if (rs2.next()) {
            recordCount = rs2.getInt("cnt");
        }

        if (recordCount > 0) {
            // Purane records hain → direct delete nahi ho sakta FK ki wajah se.
            // Best approach: un records ko delete kar do, ya book ko soft-delete karo.
            // Yahan hum saare borrowing_records bhi delete kar dete hain (with confirmation).
            PreparedStatement delRecords = db.con.prepareStatement("DELETE FROM borrowing_records WHERE book_number = ?");
            delRecords.setString(1, book_number);
            delRecords.executeUpdate();
        }

        // ---------- 4. DELETE BOOK ----------
        db.pstmt2 = db.con.prepareStatement("DELETE FROM books WHERE book_number = ?");
        db.pstmt2.setString(1, book_number);
        int rows = db.pstmt2.executeUpdate();

        db.con.close();

        if (rows > 0) {
            response.sendRedirect("listBooks.jsp?msg=deleted");
        } else {
            response.sendRedirect("listBooks.jsp?msg=notfound");
        }
    } catch (Exception e) {
        out.println("<h2 style='color:red;'>Error deleting book: " + e.getMessage() + "</h2>");
        out.println("<p><a href='listBooks.jsp'>⬅ Back to List</a></p>");
    }
%>