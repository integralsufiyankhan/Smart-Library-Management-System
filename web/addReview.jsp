<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="DB.DBDatabaseConnection" %>
<%
    // ---------- SESSION CHECK ----------
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=2");
        return;
    }

    String book_number = request.getParameter("book_number");
    String member_id   = request.getParameter("member_id");
    String ratingStr   = request.getParameter("rating");
    String comment     = request.getParameter("comment");

    // Validation
    if (book_number == null || member_id == null || ratingStr == null
        || book_number.trim().isEmpty() || member_id.trim().isEmpty()
        || ratingStr.trim().isEmpty()) {
        response.sendRedirect("listBooks.jsp");
        return;
    }

    try {
        int rating = Integer.parseInt(ratingStr);
        if (rating < 1 || rating > 5) throw new NumberFormatException();
        if (comment == null) comment = "";

        DBDatabaseConnection db = new DBDatabaseConnection();

        // ---------- 1. CHECK DUPLICATE REVIEW ----------
        // Ek member ek book ko sirf ek baar review kar sakta hai
        PreparedStatement psDup = db.con.prepareStatement(
            "SELECT review_id FROM reviews WHERE book_number = ? AND member_id = ?");
        psDup.setString(1, book_number);
        psDup.setString(2, member_id);
        ResultSet rsDup = psDup.executeQuery();

        if (rsDup.next()) {
            // Already reviewed — update the existing review
            PreparedStatement psUpd = db.con.prepareStatement(
                "UPDATE reviews SET rating = ?, comment = ?, created_at = CURRENT_TIMESTAMP " +
                "WHERE book_number = ? AND member_id = ?");
            psUpd.setInt(1, rating);
            psUpd.setString(2, comment);
            psUpd.setString(3, book_number);
            psUpd.setString(4, member_id);
            psUpd.executeUpdate();
        } else {
            // New review — insert
            PreparedStatement psIns = db.con.prepareStatement(
                "INSERT INTO reviews (book_number, member_id, rating, comment) VALUES (?, ?, ?, ?)");
            psIns.setString(1, book_number);
            psIns.setString(2, member_id);
            psIns.setInt(3, rating);
            psIns.setString(4, comment);
            psIns.executeUpdate();
        }

        // ---------- 2. RECALCULATE AVG_RATING FOR THIS BOOK ----------
        PreparedStatement psAvg = db.con.prepareStatement(
            "SELECT AVG(rating) AS avg_r, COUNT(*) AS cnt FROM reviews WHERE book_number = ?");
        psAvg.setString(1, book_number);
        ResultSet rsAvg = psAvg.executeQuery();

        double newAvg = 0;
        if (rsAvg.next()) {
            newAvg = rsAvg.getDouble("avg_r");
        }

        // ---------- 3. UPDATE books.avg_rating ----------
        PreparedStatement psBook = db.con.prepareStatement(
            "UPDATE books SET avg_rating = ? WHERE book_number = ?");
        psBook.setDouble(1, newAvg);
        psBook.setString(2, book_number);
        psBook.executeUpdate();

        db.con.close();
    } catch (Exception e) {
        // Silent fail — chalta hai
    }

    // Redirect back to book details page with success flag
    response.sendRedirect("bookDetails.jsp?book_number=" + book_number + "&reviewed=1");
%>