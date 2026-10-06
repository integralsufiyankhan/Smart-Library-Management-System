<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="DB.DBDatabaseConnection" %>
<%
    String username = request.getParameter("username");
    String password = request.getParameter("password");
    String full_name = request.getParameter("full_name");

    if (username == null || password == null || full_name == null
        || username.trim().isEmpty() || password.trim().isEmpty() || full_name.trim().isEmpty()) {
        response.sendRedirect("signup.jsp?error=1");
        return;
    }

    try {
        DBDatabaseConnection db = new DBDatabaseConnection();

        // Pehle check karo username already exists ya nahi
        db.pstmt = db.con.prepareStatement("SELECT admin_id FROM admin WHERE username = ?");
        db.pstmt.setString(1, username);
        db.rst = db.pstmt.executeQuery();
        if (db.rst.next()) {
            db.con.close();
            response.sendRedirect("signup.jsp?error=dup");
            return;
        }

        // Insert new admin
        String sql = "INSERT INTO admin (username, password, full_name) VALUES (?, ?, ?)";
        db.pstmt2 = db.con.prepareStatement(sql);
        db.pstmt2.setString(1, username);
        db.pstmt2.setString(2, password);
        db.pstmt2.setString(3, full_name);

        int rows = db.pstmt2.executeUpdate();
        db.con.close();

        if (rows > 0) {
            response.sendRedirect("login.jsp");
        } else {
            response.sendRedirect("signup.jsp?error=1");
        }
    } catch (Exception e) {
        out.println("Error: " + e.getMessage());
    }
%>