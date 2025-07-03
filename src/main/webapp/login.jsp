<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>

<%
    // Check if user is already logged in
    if (session.getAttribute("userId") != null) {
        // Redirect based on role
        String userRole = (String) session.getAttribute("userRole");
        if ("client".equals(userRole)) {
            response.sendRedirect("Client/dashboard.jsp");
        } else if ("employee".equals(userRole)) {
            response.sendRedirect("Employee/Dashboard.jsp");
        } else if ("manager".equals(userRole)) {
            response.sendRedirect("Manager/admin-dashboard.jsp");
        }
        return;
    }

    // Initialize variables for login processing
    String errorMessage = "";
    String email = "";
    
    // Process login form submission
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        // Get form data
        email = request.getParameter("email");
        String password = request.getParameter("password");
        String loginType = request.getParameter("loginType");
        
        // Database connection variables
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            // Establish database connection
            String jdbcURL = "jdbc:mysql://localhost:3306/hotels_db";
            String dbUser = "root";
            String dbPassword = "";
            
            Class.forName("com.mysql.jdbc.Driver");
            conn = DriverManager.getConnection(jdbcURL, dbUser, dbPassword);
            
            // Query to check user credentials
            String query = "SELECT u.user_id, u.first_name, u.last_name, u.email, u.password_hash, r.name as role_name " +
                          "FROM users u " +
                          "JOIN roles r ON u.role_id = r.role_id " +
                          "WHERE u.email = ? AND u.is_active = 1";
            
            pstmt = conn.prepareStatement(query);
            pstmt.setString(1, email);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                // User found, verify password (in production, use proper password hashing)
                String storedPassword = rs.getString("password_hash");
                String userRole = rs.getString("role_name");
                
                // Simple password check (in production, use proper password verification)
                if (password.equals(storedPassword)) {
                    // Check if the user has the correct role for the selected login type
                    boolean validRoleForType = false;
                    
                    if ("client".equals(loginType) && "client".equals(userRole)) {
                        validRoleForType = true;
                    } else if ("employee".equals(loginType) && "employee".equals(userRole)) {
                        validRoleForType = true;
                    } else if ("manager".equals(loginType) && "manager".equals(userRole)) {
                        validRoleForType = true;
                    }
                    
                    if (validRoleForType) {
                        // Set session attributes
                        session.setAttribute("userId", rs.getString("user_id"));
                        session.setAttribute("firstName", rs.getString("first_name"));
                        session.setAttribute("lastName", rs.getString("last_name"));
                        session.setAttribute("email", rs.getString("email"));
                        session.setAttribute("userRole", userRole);
                        
                        // Update last login time
                        String updateQuery = "UPDATE users SET last_login = NOW() WHERE user_id = ?";
                        PreparedStatement updateStmt = conn.prepareStatement(updateQuery);
                        updateStmt.setString(1, rs.getString("user_id"));
                        updateStmt.executeUpdate();
                        updateStmt.close();
                        
                        // Redirect based on role
                        if ("client".equals(userRole)) {
                            response.sendRedirect("Client/dashboard.jsp");
                        } else if ("employee".equals(userRole)) {
                            response.sendRedirect("Employee/Dashboard.jsp");
                        } else if ("manager".equals(userRole)) {
                            response.sendRedirect("Manager/admin-dashboard.jsp");
                        }
                        return;
                    } else {
                        errorMessage = "You don't have permission to access this portal. Please select the correct login type.";
                    }
                } else {
                    errorMessage = "Invalid email or password. Please try again.";
                }
            } else {
                errorMessage = "Invalid email or password. Please try again.";
            }
            
        } catch (Exception e) {
            errorMessage = "An error occurred: " + e.getMessage();
            e.printStackTrace();
        } finally {
            // Close database resources
            try {
                if (rs != null) rs.close();
                if (pstmt != null) pstmt.close();
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZAIRTAM - Login</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
        }
        
        .login-container {
            background-image: linear-gradient(rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.5)), url('https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80');
            background-size: cover;
            background-position: center;
        }
        
        .login-type-option {
            transition: all 0.3s ease;
        }
        
        .login-type-option.selected {
            border-color: #2563eb;
            background-color: #eff6ff;
        }
    </style>
</head>
<body class="bg-gray-50">
    <!-- Include the header -->
    <jsp:include page="/WEB-INF/components/header.jsp" />
    
    <!-- Login Section -->
    <div class="login-container min-h-screen py-12">
        <div class="max-w-md mx-auto bg-white rounded-xl shadow-lg overflow-hidden">
            <div class="px-6 py-8">
                <div class="text-center mb-8">
                    <h2 class="text-2xl font-bold text-gray-800">Welcome Back</h2>
                    <p class="text-gray-600 mt-1">Sign in to your account</p>
                </div>
                
                <% if (!errorMessage.isEmpty()) { %>
                    <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
                        <%= errorMessage %>
                    </div>
                <% } %>
                
                <form action="login.jsp" method="post">
                    <!-- Login Type Selection -->
                    <div class="mb-6">
                        <label class="block text-sm font-medium text-gray-700 mb-2">Login As</label>
                        <div class="grid grid-cols-3 gap-3">
                            <div id="clientLogin" class="login-type-option selected cursor-pointer border rounded-lg p-3 text-center">
                                <i class="fas fa-user text-xl mb-1 text-blue-600"></i>
                                <p class="text-sm font-medium">Client</p>
                            </div>
                            <div id="employeeLogin" class="login-type-option cursor-pointer border rounded-lg p-3 text-center">
                                <i class="fas fa-id-card text-xl mb-1 text-gray-600"></i>
                                <p class="text-sm font-medium">Employee</p>
                            </div>
                            <div id="managerLogin" class="login-type-option cursor-pointer border rounded-lg p-3 text-center">
                                <i class="fas fa-hotel text-xl mb-1 text-gray-600"></i>
                                <p class="text-sm font-medium">Manager</p>
                            </div>
                        </div>
                        <input type="hidden" id="loginType" name="loginType" value="client">
                    </div>
                    
                    <!-- Email Field -->
                    <div class="mb-4">
                        <label for="email" class="block text-sm font-medium text-gray-700 mb-1">Email Address</label>
                        <div class="relative">
                            <input type="email" id="email" name="email" value="<%= email %>" required 
                                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
                                placeholder="your@email.com">
                            <i class="fas fa-envelope absolute right-3 top-3.5 text-gray-400"></i>
                        </div>
                    </div>
                    
                    <!-- Password Field -->
                    <div class="mb-6">
                        <div class="flex justify-between mb-1">
                            <label for="password" class="block text-sm font-medium text-gray-700">Password</label>
                            <a href="forgot-password.jsp" class="text-sm text-blue-600 hover:text-blue-800">Forgot Password?</a>
                        </div>
                        <div class="relative">
                            <input type="password" id="password" name="password" required 
                                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
                                placeholder="••••••••">
                            <button type="button" id="togglePassword" class="absolute right-3 top-3.5 text-gray-400">
                                <i class="fas fa-eye"></i>
                            </button>
                        </div>
                    </div>
                    
                    <!-- Remember Me -->
                    <div class="flex items-center mb-6">
                        <input type="checkbox" id="remember" name="remember" class="h-4 w-4 text-blue-600 border-gray-300 rounded">
                        <label for="remember" class="ml-2 block text-sm text-gray-700">Remember me</label>
                    </div>
                    
                    <!-- Submit Button -->
                    <button type="submit" class="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 rounded-lg font-medium">
                        Sign In
                    </button>
                </form>
                
                <div class="text-center mt-6">
                    <p class="text-gray-600">Don't have an account? <a href="register.jsp" class="text-blue-600 hover:text-blue-800 font-medium">Sign Up</a></p>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Toggle password visibility
        const togglePassword = document.getElementById('togglePassword');
        const passwordInput = document.getElementById('password');
        
        togglePassword.addEventListener('click', function() {
            const type = passwordInput.getAttribute('type') === 'password' ? 'text' : 'password';
            passwordInput.setAttribute('type', type);
            
            // Toggle eye icon
            const eyeIcon = togglePassword.querySelector('i');
            eyeIcon.classList.toggle('fa-eye');
            eyeIcon.classList.toggle('fa-eye-slash');
        });
        
        // Login type selection
        const clientLogin = document.getElementById('clientLogin');
        const employeeLogin = document.getElementById('employeeLogin');
        const managerLogin = document.getElementById('managerLogin');
        const loginTypeInput = document.getElementById('loginType');
        
        clientLogin.addEventListener('click', function() {
            selectLoginType('client', clientLogin, [employeeLogin, managerLogin]);
        });
        
        employeeLogin.addEventListener('click', function() {
            selectLoginType('employee', employeeLogin, [clientLogin, managerLogin]);
        });
        
        managerLogin.addEventListener('click', function() {
            selectLoginType('manager', managerLogin, [clientLogin, employeeLogin]);
        });
        
        function selectLoginType(type, selectedElement, otherElements) {
            // Update hidden input value
            loginTypeInput.value = type;
            
            // Update selected element
            selectedElement.classList.add('selected');
            selectedElement.querySelector('i').classList.add('text-blue-600');
            selectedElement.querySelector('i').classList.remove('text-gray-600');
            
            // Update other elements
            otherElements.forEach(element => {
                element.classList.remove('selected');
                element.querySelector('i').classList.add('text-gray-600');
                element.querySelector('i').classList.remove('text-blue-600');
            });
        }
    </script>
</body>
</html>