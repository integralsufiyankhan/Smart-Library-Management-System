<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="DB.DBDatabaseConnection" %>
<%
    // ---------- SESSION CHECK ----------
    if (session.getAttribute("admin") == null) {
        response.sendRedirect("login.jsp?error=2");
        return;
    }

    // ---------- MEMBER ID ----------
    String member_id = request.getParameter("member_id");
    if (member_id == null || member_id.trim().isEmpty()) {
        response.sendRedirect("listMembers.jsp?msg=notfound");
        return;
    }

    try {
        DBDatabaseConnection db = new DBDatabaseConnection();

        // ---------- 1. CHECK MEMBER EXISTS ----------
        db.pstmt = db.con.prepareStatement("SELECT name FROM members WHERE member_id = ?");
        db.pstmt.setString(1, member_id);
        db.rst = db.pstmt.executeQuery();

        if (!db.rst.next()) {
            db.con.close();
            response.sendRedirect("listMembers.jsp?msg=notfound");
            return;
        }

        String memberName = db.rst.getString("name");

        // ---------- 2. CHECK ACTIVE LOANS ----------
        db.pstmt2 = db.con.prepareStatement(
            "SELECT COUNT(*) AS cnt FROM borrowing_records WHERE member_id = ? AND return_date IS NULL");
        db.pstmt2.setString(1, member_id);
        ResultSet rs1 = db.pstmt2.executeQuery();
        int activeLoans = 0;
        if (rs1.next()) activeLoans = rs1.getInt("cnt");

        if (activeLoans > 0) {
            db.con.close();
            response.sendRedirect("listMembers.jsp?msg=hasloans");
            return;
        }

        // ---------- 3. HANDLE PAST RECORDS ----------
        // Agar member ke paas purani history hai (jo return ho chuki hai),
        // to FK constraint ki wajah se directly delete nahi hoga.
        // Solution: un purane records bhi delete kar dete hain.

        db.pstmt2 = db.con.prepareStatement(
            "SELECT COUNT(*) AS cnt FROM borrowing_records WHERE member_id = ?");
        db.pstmt2.setString(1, member_id);
        ResultSet rs2 = db.pstmt2.executeQuery();
        int totalRecords = 0;
        if (rs2.next()) totalRecords = rs2.getInt("cnt");

        if (totalRecords > 0) {
            PreparedStatement delRecords = db.con.prepareStatement(
                "DELETE FROM borrowing_records WHERE member_id = ?");
            delRecords.setString(1, member_id);
            delRecords.executeUpdate();
        }

        // ---------- 4. DELETE MEMBER ----------
        db.pstmt2 = db.con.prepareStatement("DELETE FROM members WHERE member_id = ?");
        db.pstmt2.setString(1, member_id);
        int rows = db.pstmt2.executeUpdate();

        db.con.close();

        if (rows > 0) {
            response.sendRedirect("listMembers.jsp?msg=deleted");
        } else {
            response.sendRedirect("listMembers.jsp?msg=notfound");
        }
    } catch (Exception e) {
        out.println("<h2 style='color:red;'>Error deleting member: " + e.getMessage() + "</h2>");
        out.println("<p><a href='listMembers.jsp'>⬅ Back to List</a></p>");
    }
%>