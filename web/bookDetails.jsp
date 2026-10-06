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

    String book_number = request.getParameter("book_number");
    if (book_number == null || book_number.trim().isEmpty()) {
        response.sendRedirect("listBooks.jsp");
        return;
    }
    book_number = book_number.trim();

    // ---------- BOOK VARIABLES ----------
    String bTitle = "", bAuthor = "", bCategory = "General", bDescription = "";
    int bTotal = 0, bAvail = 0, bIssued = 0;
    double bRating = 0;
    boolean bookFound = false;

    // Review stats
    int reviewCount = 0;
    int star5 = 0, star4 = 0, star3 = 0, star2 = 0, star1 = 0;

    // ---------- FETCH BOOK ----------
    try {
        DBDatabaseConnection db = new DBDatabaseConnection();
        db.pstmt = db.con.prepareStatement("SELECT * FROM books WHERE book_number = ?");
        db.pstmt.setString(1, book_number);
        db.rst = db.pstmt.executeQuery();

        if (db.rst.next()) {
            bookFound = true;
            bTitle = db.rst.getString("title");
            bAuthor = db.rst.getString("author");
            bCategory = db.rst.getString("category");
            if (bCategory == null || bCategory.trim().isEmpty()) bCategory = "General";
            bDescription = db.rst.getString("description");
            if (bDescription == null) bDescription = "";
            bTotal = db.rst.getInt("total_copies");
            bAvail = db.rst.getInt("available_copies");
            bIssued = bTotal - bAvail;
            bRating = db.rst.getDouble("avg_rating");
        }
        db.con.close();
    } catch (Exception e) {
        out.println("Error: " + e.getMessage());
    }

    if (!bookFound) {
        response.sendRedirect("listBooks.jsp?msg=notfound");
        return;
    }

    // Rating stars display
    int fullStars = (int) Math.round(bRating);
    StringBuilder bigStars = new StringBuilder();
    for (int s = 1; s <= 5; s++) {
        bigStars.append(s <= fullStars ? "★" : "<span class='empty'>★</span>");
    }

    // Category badge class
    String catClass = "cat-" + bCategory.replace("-", "").replace(" ", "");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title><%= bTitle %> - Book Details</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Segoe UI', Tahoma, Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding-bottom: 40px;
        }

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
        .nav-right span { color: #4a3f8f; font-size: 14px; font-weight: 600; }
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
        .nav-btn.back { background: #3498db; }
        .nav-btn.back:hover { background: #2980b9; }
        .nav-btn.logout { background: #e74c3c; }
        .nav-btn.logout:hover { background: #c0392b; }

        .container { max-width: 1100px; margin: 0 auto; padding: 0 20px; }

        /* ---------- BOOK HERO CARD ---------- */
        .hero-card {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 15px 50px rgba(0,0,0,0.25);
            overflow: hidden;
            margin-bottom: 25px;
        }
        .hero-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 30px;
            display: flex;
            gap: 25px;
            align-items: center;
            color: #fff;
            flex-wrap: wrap;
        }
        .book-cover {
            width: 120px;
            height: 160px;
            border-radius: 12px;
            background: rgba(255,255,255,0.2);
            border: 3px solid rgba(255,255,255,0.4);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 60px;
            flex-shrink: 0;
            box-shadow: 0 8px 25px rgba(0,0,0,0.25);
        }
        .hero-info { flex: 1; min-width: 250px; }
        .hero-info .book-num-badge {
            display: inline-block;
            background: rgba(255,255,255,0.25);
            padding: 4px 14px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 700;
            margin-bottom: 10px;
            letter-spacing: 0.5px;
        }
        .hero-info h1 {
            font-size: 30px;
            margin-bottom: 8px;
            line-height: 1.2;
        }
        .hero-info .author {
            font-size: 15px;
            opacity: 0.95;
            margin-bottom: 12px;
        }
        .hero-info .big-stars {
            font-size: 22px;
            color: #ffd700;
            letter-spacing: 3px;
            margin-bottom: 6px;
        }
        .hero-info .big-stars .empty { color: rgba(255,255,255,0.3); }
        .hero-info .rating-text {
            font-size: 14px;
            opacity: 0.95;
        }

        /* ---------- STATS STRIP ---------- */
        .stats-strip {
            display: flex;
            background: #f9f9ff;
            border-bottom: 1px solid #e0e0ea;
        }
        .stats-strip .stat-box {
            flex: 1;
            padding: 20px;
            text-align: center;
            border-right: 1px solid #e0e0ea;
        }
        .stats-strip .stat-box:last-child { border-right: none; }
        .stat-box .num {
            font-size: 26px;
            font-weight: 800;
            color: #4a3f8f;
            margin-bottom: 4px;
        }
        .stat-box .lbl {
            font-size: 11px;
            color: #888;
            text-transform: uppercase;
            letter-spacing: 1px;
            font-weight: 700;
        }
        .stat-box.issued .num { color: #e74c3c; }
        .stat-box.avail .num  { color: #27ae60; }

        /* ---------- DESCRIPTION + CATEGORY ---------- */
        .book-body { padding: 25px 30px; }
        .cat-badge {
            display: inline-block;
            padding: 6px 16px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 700;
            background: #eef1ff;
            color: #4a3f8f;
            border: 1px solid #c5cae9;
            margin-bottom: 15px;
        }
        .cat-Programming { background: #dbeafe; color: #1e40af; border-color: #93c5fd; }
        .cat-Fiction { background: #fce7f3; color: #9d174d; border-color: #f9a8d4; }
        .cat-Biography { background: #fef3c7; color: #92400e; border-color: #fcd34d; }
        .cat-NonFiction { background: #e0f2fe; color: #075985; border-color: #7dd3fc; }
        .cat-SelfHelp { background: #d1fae5; color: #065f46; border-color: #6ee7b7; }
        .cat-General { background: #ede9fe; color: #5b21b6; border-color: #c4b5fd; }

        .description-title {
            font-size: 13px;
            color: #4a3f8f;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 8px;
        }
        .description-text {
            color: #555;
            line-height: 1.7;
            font-size: 14px;
        }

        /* ---------- REVIEWS SECTION ---------- */
        .section-card {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 15px 50px rgba(0,0,0,0.2);
            overflow: hidden;
            margin-bottom: 25px;
        }
        .section-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            padding: 18px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .section-header h2 { font-size: 18px; }
        .section-header .count-badge {
            background: rgba(255,255,255,0.25);
            padding: 4px 14px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 700;
        }

        /* Rating breakdown */
        .rating-breakdown {
            display: flex;
            padding: 25px 30px;
            gap: 30px;
            border-bottom: 1px solid #eee;
            flex-wrap: wrap;
        }
        .rating-big {
            text-align: center;
            padding-right: 30px;
            border-right: 2px solid #eee;
            flex-shrink: 0;
        }
        .rating-big .avg {
            font-size: 52px;
            font-weight: 800;
            color: #4a3f8f;
            line-height: 1;
        }
        .rating-big .stars-sm {
            color: #f39c12;
            font-size: 18px;
            letter-spacing: 2px;
            margin-top: 8px;
        }
        .rating-big .stars-sm .empty { color: #ddd; }
        .rating-big .total-reviews {
            font-size: 12px;
            color: #888;
            margin-top: 8px;
            font-weight: 600;
        }
        .rating-bars { flex: 1; min-width: 200px; }
        .bar-row {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 6px;
            font-size: 13px;
        }
        .bar-row .star-lbl { width: 40px; color: #666; font-weight: 600; }
        .bar-row .bar-wrap {
            flex: 1;
            height: 8px;
            background: #eee;
            border-radius: 4px;
            overflow: hidden;
        }
        .bar-row .bar-fill {
            height: 100%;
            background: linear-gradient(90deg, #f39c12, #e67e22);
            border-radius: 4px;
            transition: width 0.5s;
        }
        .bar-row .bar-count { width: 30px; text-align: right; color: #888; font-weight: 600; }

        /* Reviews list */
        .review-list { padding: 20px 30px; }
        .review-item {
            padding: 18px 0;
            border-bottom: 1px solid #eee;
            display: flex;
            gap: 15px;
        }
        .review-item:last-child { border-bottom: none; }
        .review-avatar {
            width: 44px;
            height: 44px;
            border-radius: 50%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            font-size: 17px;
            flex-shrink: 0;
        }
        .review-body { flex: 1; }
        .review-top {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 6px;
            flex-wrap: wrap;
            gap: 8px;
        }
        .review-author {
            font-weight: 700;
            color: #4a3f8f;
            font-size: 14px;
        }
        .review-stars {
            color: #f39c12;
            font-size: 14px;
            letter-spacing: 1px;
        }
        .review-stars .empty { color: #ddd; }
        .review-text {
            color: #555;
            font-size: 14px;
            line-height: 1.6;
            margin-bottom: 4px;
        }
        .review-date {
            font-size: 11px;
            color: #999;
        }

        .no-reviews {
            text-align: center;
            padding: 40px 20px;
            color: #888;
        }
        .no-reviews .icon { font-size: 50px; margin-bottom: 10px; }
        .no-reviews h3 { color: #4a3f8f; margin-bottom: 6px; }
        .no-reviews p { font-size: 14px; }

        /* Add review form */
        .add-review-form {
            padding: 20px 30px 30px;
            background: #f9f9ff;
            border-top: 1px solid #eee;
        }
        .add-review-form h3 {
            color: #4a3f8f;
            font-size: 15px;
            margin-bottom: 15px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .form-row {
            display: flex;
            gap: 12px;
            margin-bottom: 12px;
            flex-wrap: wrap;
        }
        .form-row select,
        .form-row input,
        .form-row textarea {
            padding: 10px 14px;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            font-size: 14px;
            font-family: inherit;
            transition: 0.3s;
            background: #fff;
        }
        .form-row select { min-width: 180px; }
        .form-row input { flex: 1; min-width: 180px; }
        .form-row textarea { flex: 1; min-width: 100%; resize: vertical; min-height: 70px; }
        .form-row input:focus,
        .form-row select:focus,
        .form-row textarea:focus {
            border-color: #667eea;
            outline: none;
            box-shadow: 0 0 0 4px rgba(102,126,234,0.1);
        }
        .btn-submit {
            padding: 11px 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            border: none;
            border-radius: 10px;
            font-weight: 700;
            font-size: 14px;
            cursor: pointer;
            transition: 0.3s;
        }
        .btn-submit:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 18px rgba(102,126,234,0.4);
        }

        /* ---------- RECOMMENDATIONS ---------- */
        .rec-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
            gap: 15px;
            padding: 25px 30px;
        }
        .rec-item {
            background: #f9f9ff;
            border: 2px solid #e0e0ea;
            border-radius: 12px;
            padding: 15px;
            text-decoration: none;
            transition: 0.3s;
        }
        .rec-item:hover {
            border-color: #667eea;
            transform: translateY(-3px);
            box-shadow: 0 10px 25px rgba(102,126,234,0.2);
        }
        .rec-item .rec-icon {
            font-size: 32px;
            margin-bottom: 8px;
        }
        .rec-item .rec-title {
            color: #4a3f8f;
            font-weight: 700;
            font-size: 14px;
            margin-bottom: 4px;
            line-height: 1.3;
        }
        .rec-item .rec-author {
            color: #888;
            font-size: 12px;
            margin-bottom: 6px;
        }
        .rec-item .rec-rating {
            color: #f39c12;
            font-size: 13px;
            letter-spacing: 1px;
        }
        .rec-item .rec-rating .empty { color: #ddd; }
    </style>
</head>
<body>

    <div class="navbar">
        <h1>📚 Library Management System</h1>
        <div class="nav-right">
            <span>👤 <%= adminName %></span>
            <a href="listBooks.jsp" class="nav-btn back">⬅ Books</a>
            <a href="index.html" class="nav-btn home">🏠 Home</a>
            <a href="logout.jsp" class="nav-btn logout">Logout</a>
        </div>
    </div>

    <div class="container">

        <!-- BOOK HERO -->
        <div class="hero-card">
            <div class="hero-header">
                <div class="book-cover">📖</div>
                <div class="hero-info">
                    <span class="book-num-badge">📘 <%= book_number %></span>
                    <h1><%= bTitle %></h1>
                    <div class="author">✍️ by <strong><%= bAuthor %></strong></div>
                    <div class="big-stars"><%= bigStars.toString() %></div>
                    <div class="rating-text">
                        <% if (bRating > 0) { %>
                            <%= String.format("%.1f", bRating) %> out of 5
                        <% } else { %>
                            No ratings yet — be the first to review!
                        <% } %>
                    </div>
                </div>
            </div>

            <div class="stats-strip">
                <div class="stat-box">
                    <div class="num"><%= bTotal %></div>
                    <div class="lbl">Total Copies</div>
                </div>
                <div class="stat-box avail">
                    <div class="num"><%= bAvail %></div>
                    <div class="lbl">Available</div>
                </div>
                <div class="stat-box issued">
                    <div class="num"><%= bIssued %></div>
                    <div class="lbl">Issued</div>
                </div>
            </div>

            <div class="book-body">
                <span class="cat-badge <%= catClass %>">📂 <%= bCategory %></span>
                <% if (!bDescription.isEmpty()) { %>
                    <div class="description-title">📝 Description</div>
                    <div class="description-text"><%= bDescription %></div>
                <% } else { %>
                    <div class="description-text" style="color:#999;font-style:italic;">
                        No description available for this book.
                    </div>
                <% } %>
            </div>
        </div>

        <%
            // ---------- FETCH REVIEW STATS + LIST ----------
            java.util.List<String[]> reviews = new java.util.ArrayList<String[]>();
            try {
                DBDatabaseConnection db = new DBDatabaseConnection();

                // Reviews with member name
                String sql = "SELECT r.review_id, r.member_id, m.name AS member_name, " +
                             "r.rating, r.comment, r.created_at " +
                             "FROM reviews r " +
                             "JOIN members m ON r.member_id = m.member_id " +
                             "WHERE r.book_number = ? " +
                             "ORDER BY r.created_at DESC";
                db.pstmt = db.con.prepareStatement(sql);
                db.pstmt.setString(1, book_number);
                db.rst = db.pstmt.executeQuery();

                while (db.rst.next()) {
                    int r = db.rst.getInt("rating");
                    reviewCount++;
                    if (r == 5) star5++;
                    else if (r == 4) star4++;
                    else if (r == 3) star3++;
                    else if (r == 2) star2++;
                    else if (r == 1) star1++;

                    reviews.add(new String[]{
                        db.rst.getString("member_id"),
                        db.rst.getString("member_name"),
                        String.valueOf(r),
                        db.rst.getString("comment") == null ? "" : db.rst.getString("comment"),
                        db.rst.getTimestamp("created_at").toString().substring(0, 10)
                    });
                }
                db.con.close();
            } catch (Exception e) { }
        %>

        <!-- REVIEWS SECTION -->
        <div class="section-card">
            <div class="section-header">
                <h2>⭐ Reviews & Ratings</h2>
                <span class="count-badge"><%= reviewCount %> review<%= reviewCount != 1 ? "s" : "" %></span>
            </div>

            <% if (reviewCount > 0) { 
                int pct5 = star5 * 100 / reviewCount;
                int pct4 = star4 * 100 / reviewCount;
                int pct3 = star3 * 100 / reviewCount;
                int pct2 = star2 * 100 / reviewCount;
                int pct1 = star1 * 100 / reviewCount;
            %>
                <!-- RATING BREAKDOWN -->
                <div class="rating-breakdown">
                    <div class="rating-big">
                        <div class="avg"><%= String.format("%.1f", bRating) %></div>
                        <div class="stars-sm"><%= bigStars.toString() %></div>
                        <div class="total-reviews"><%= reviewCount %> review<%= reviewCount != 1 ? "s" : "" %></div>
                    </div>
                    <div class="rating-bars">
                        <div class="bar-row">
                            <span class="star-lbl">5 ★</span>
                            <div class="bar-wrap"><div class="bar-fill" style="width:<%= pct5 %>%"></div></div>
                            <span class="bar-count"><%= star5 %></span>
                        </div>
                        <div class="bar-row">
                            <span class="star-lbl">4 ★</span>
                            <div class="bar-wrap"><div class="bar-fill" style="width:<%= pct4 %>%"></div></div>
                            <span class="bar-count"><%= star4 %></span>
                        </div>
                        <div class="bar-row">
                            <span class="star-lbl">3 ★</span>
                            <div class="bar-wrap"><div class="bar-fill" style="width:<%= pct3 %>%"></div></div>
                            <span class="bar-count"><%= star3 %></span>
                        </div>
                        <div class="bar-row">
                            <span class="star-lbl">2 ★</span>
                            <div class="bar-wrap"><div class="bar-fill" style="width:<%= pct2 %>%"></div></div>
                            <span class="bar-count"><%= star2 %></span>
                        </div>
                        <div class="bar-row">
                            <span class="star-lbl">1 ★</span>
                            <div class="bar-wrap"><div class="bar-fill" style="width:<%= pct1 %>%"></div></div>
                            <span class="bar-count"><%= star1 %></span>
                        </div>
                    </div>
                </div>

                <!-- REVIEW LIST -->
                <div class="review-list">
                    <%
                        for (String[] rv : reviews) {
                            String mName = rv[1];
                            String initial = mName != null && !mName.isEmpty() ? mName.substring(0, 1).toUpperCase() : "?";
                            int r = Integer.parseInt(rv[2]);
                            StringBuilder rStars = new StringBuilder();
                            for (int s = 1; s <= 5; s++) {
                                rStars.append(s <= r ? "★" : "<span class='empty'>★</span>");
                            }
                    %>
                        <div class="review-item">
                            <div class="review-avatar"><%= initial %></div>
                            <div class="review-body">
                                <div class="review-top">
                                    <div>
                                        <div class="review-author"><%= mName %></div>
                                        <div class="review-stars"><%= rStars.toString() %></div>
                                    </div>
                                    <div class="review-date"><%= rv[4] %></div>
                                </div>
                                <% if (!rv[3].isEmpty()) { %>
                                    <div class="review-text"><%= rv[3] %></div>
                                <% } %>
                            </div>
                        </div>
                    <% } %>
                </div>
            <% } else { %>
                <div class="no-reviews">
                    <div class="icon">💬</div>
                    <h3>No Reviews Yet</h3>
                    <p>Be the first one to review this book!</p>
                </div>
            <% } %>

            <!-- ADD REVIEW FORM -->
            <form class="add-review-form" action="addReview.jsp" method="post">
                <h3>✍️ Write a Review</h3>
                <input type="hidden" name="book_number" value="<%= book_number %>">
                <div class="form-row">
                    <select name="member_id" required>
                        <option value="">-- Select Member --</option>
                        <%
                            try {
                                DBDatabaseConnection dbM = new DBDatabaseConnection();
                                dbM.rst = dbM.con.createStatement().executeQuery(
                                    "SELECT member_id, name FROM members ORDER BY name");
                                while (dbM.rst.next()) {
                        %>
                            <option value="<%= dbM.rst.getString("member_id") %>">
                                <%= dbM.rst.getString("name") %> (<%= dbM.rst.getString("member_id") %>)
                            </option>
                        <%
                                }
                                dbM.con.close();
                            } catch (Exception e) { }
                        %>
                    </select>
                    <select name="rating" required>
                        <option value="">-- Rating --</option>
                        <option value="5">⭐⭐⭐⭐⭐ (5) Excellent</option>
                        <option value="4">⭐⭐⭐⭐ (4) Very Good</option>
                        <option value="3">⭐⭐⭐ (3) Good</option>
                        <option value="2">⭐⭐ (2) Fair</option>
                        <option value="1">⭐ (1) Poor</option>
                    </select>
                </div>
                <div class="form-row">
                    <textarea name="comment" placeholder="Write your review comment here (optional)..."></textarea>
                </div>
                <button type="submit" class="btn-submit">📤 Submit Review</button>
            </form>
        </div>

        <!-- RECOMMENDATIONS -->
        <%
            java.util.List<String[]> recommendations = new java.util.ArrayList<String[]>();
            try {
                DBDatabaseConnection dbR = new DBDatabaseConnection();
                // Same category books, excluding this one, ordered by rating
                String sqlR = "SELECT book_number, title, author, avg_rating " +
                              "FROM books " +
                              "WHERE category = ? AND book_number != ? " +
                              "ORDER BY avg_rating DESC, RAND() " +
                              "LIMIT 4";
                dbR.pstmt = dbR.con.prepareStatement(sqlR);
                dbR.pstmt.setString(1, bCategory);
                dbR.pstmt.setString(2, book_number);
                dbR.rst = dbR.pstmt.executeQuery();
                while (dbR.rst.next()) {
                    recommendations.add(new String[]{
                        dbR.rst.getString("book_number"),
                        dbR.rst.getString("title"),
                        dbR.rst.getString("author"),
                        String.valueOf(dbR.rst.getDouble("avg_rating"))
                    });
                }
                dbR.con.close();
            } catch (Exception e) { }
        %>

        <% if (!recommendations.isEmpty()) { %>
        <div class="section-card">
            <div class="section-header">
                <h2>🎯 You Might Also Like</h2>
                <span class="count-badge">From "<%= bCategory %>"</span>
            </div>
            <div class="rec-grid">
                <% for (String[] rec : recommendations) {
                    double rr = Double.parseDouble(rec[3]);
                    int rfs = (int) Math.round(rr);
                    StringBuilder rrs = new StringBuilder();
                    for (int s = 1; s <= 5; s++) {
                        rrs.append(s <= rfs ? "★" : "<span class='empty'>★</span>");
                    }
                %>
                    <a href="bookDetails.jsp?book_number=<%= rec[0] %>" class="rec-item">
                        <div class="rec-icon">📚</div>
                        <div class="rec-title"><%= rec[1] %></div>
                        <div class="rec-author">✍️ <%= rec[2] %></div>
                        <div class="rec-rating"><%= rrs.toString() %></div>
                    </a>
                <% } %>
            </div>
        </div>
        <% } %>

    </div>

</body>
</html>