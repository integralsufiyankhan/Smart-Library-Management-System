<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Signup - Library Management System</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .signup-card {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            width: 100%;
            max-width: 440px;
            overflow: hidden;
        }
        .signup-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            padding: 30px;
            text-align: center;
        }
        .signup-header h1 { font-size: 22px; margin-bottom: 5px; }
        .signup-header p { font-size: 13px; opacity: 0.9; }

        form { padding: 30px; }
        .form-group { margin-bottom: 16px; }
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
        .btn-signup {
            width: 100%;
            padding: 13px;
            border: none;
            border-radius: 10px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: 0.3s;
            margin-top: 8px;
        }
        .btn-signup:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 20px rgba(102,126,234,0.4);
        }
        .login-link {
            text-align: center;
            padding: 0 30px 30px;
            font-size: 14px;
            color: #666;
        }
        .login-link a {
            color: #667eea;
            font-weight: 600;
            text-decoration: none;
        }
        .login-link a:hover { text-decoration: underline; }

        .msg-error {
            background: #f8d7da;
            color: #721c24;
            padding: 12px 18px;
            border-radius: 8px;
            margin: 20px 30px 0;
            border-left: 5px solid #dc3545;
            font-weight: 600;
            font-size: 14px;
        }
    </style>
</head>
<body>

    <div class="signup-card">
        <div class="signup-header">
            <h1>📝 Create Admin Account</h1>
            <p>Register a new librarian / admin</p>
        </div>

        <%
            String error = request.getParameter("error");
            if ("dup".equals(error)) {
        %>
            <div class="msg-error">⚠️ Username already exists! Try another.</div>
        <%
            } else if ("1".equals(error)) {
        %>
            <div class="msg-error">❌ Please fill all fields correctly.</div>
        <%
            }
        %>

        <form action="signupAction.jsp" method="post">
            <div class="form-group">
                <label>👤 Username</label>
                <input type="text" name="username" placeholder="Choose a username" required>
            </div>

            <div class="form-group">
                <label>🔒 Password</label>
                <input type="password" name="password" placeholder="Choose a password" required>
            </div>

            <div class="form-group">
                <label>📛 Full Name</label>
                <input type="text" name="full_name" placeholder="e.g. Ramesh Kumar" required>
            </div>

            <button type="submit" class="btn-signup">Create Account</button>
        </form>

        <div class="login-link">
            Already have an account? <a href="login.jsp">Login here</a>
        </div>
    </div>

</body>
</html>