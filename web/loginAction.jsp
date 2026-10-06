<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="DB.DBDatabaseConnection" %>
<%
    String username = request.getParameter("username");
    String password = request.getParameter("password");

    if (username == null || password == null || username.trim().isEmpty() || password.trim().isEmpty()) {
        response.sendRedirect("login.jsp?error=1");
        return;
    }

    try {
        DBDatabaseConnection db = new DBDatabaseConnection();
        String sql = "SELECT * FROM admin WHERE username = ? AND password = ?";
        db.pstmt = db.con.prepareStatement(sql);
        db.pstmt.setString(1, username);
        db.pstmt.setString(2, password);
        db.rst = db.pstmt.executeQuery();

        if (db.rst.next()) {
            // Login successful — session me store karo
            session.setAttribute("admin", username);
            session.setAttribute("adminName", db.rst.getString("full_name"));
            db.con.close();
            response.sendRedirect("index.html");
        } else {
            db.con.close();
            response.sendRedirect("login.jsp?error=1");
        }
    } catch (Exception e) {
        out.println("Error: " + e.getMessage());
    }
%>