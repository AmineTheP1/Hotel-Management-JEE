<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="java.sql.Connection,java.sql.DriverManager,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,java.sql.Timestamp" %>
<%@ page import="java.util.Calendar,java.util.List,java.util.Map,java.util.ArrayList,java.util.HashMap,java.util.Date" %>
<%@ page import="java.text.SimpleDateFormat" %>


<%
    // Database connection parameters
    String url = "jdbc:mysql://localhost:4200/hotel?useSSL=false"; // Change to your database name
    String username = "root"; // Change to your database username
    String password = "Hamza_13579"; // Change to your database password
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // User information - Get from session if available
    String adminName = (String) session.getAttribute("adminName");
    String adminImage = (String) session.getAttribute("adminImage");
    
    // Set default values if not in session
    if (adminName == null) adminName = "Admin";
    if (adminImage == null) adminImage = "";
    
    // Statistics variables
    int totalUsersCount = 0;
    int activeUsersCount = 0;
    int newUsersThisMonth = 0;
    
    // Users list
    List<Map<String, Object>> usersList = new ArrayList<>();
    
    try {
        // Establish database connection
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(url, username, password);
        PreparedStatement userStmt = conn.prepareStatement(
            "SELECT u.first_name, u.last_name " + 
            "FROM users u " +
            "JOIN roles r ON u.role_id = r.role_id " + 
            "WHERE r.name = 'manager' " + 
            "LIMIT 1");
        ResultSet userRs = userStmt.executeQuery();
        if (userRs.next()) {
            // Combine first and last names
            adminName = userRs.getString("first_name") + " " + userRs.getString("last_name");
            
            // Store in session for future use
            session.setAttribute("adminName", adminName);
            session.setAttribute("adminImage", adminImage);
        }
        // Get total users count
        pstmt = conn.prepareStatement("SELECT COUNT(*) FROM users");
        rs = pstmt.executeQuery();
        if (rs.next()) {
            totalUsersCount = rs.getInt(1);
        }
        
        // Get active users count
        pstmt = conn.prepareStatement("SELECT COUNT(*) FROM users WHERE is_active = 1");
        rs = pstmt.executeQuery();
        if (rs.next()) {
            activeUsersCount = rs.getInt(1);
        }
        
        // Get new users this month
        Calendar cal = Calendar.getInstance();
        cal.set(Calendar.DAY_OF_MONTH, 1); // First day of current month
        java.sql.Date firstDayOfMonth = new java.sql.Date(cal.getTimeInMillis());
        
        pstmt = conn.prepareStatement("SELECT COUNT(*) FROM users WHERE created_at >= ?");
        pstmt.setDate(1, firstDayOfMonth);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            newUsersThisMonth = rs.getInt(1);
        }
        
        // Get all users
        pstmt = conn.prepareStatement(
            "SELECT u.*, " +
            "(SELECT COUNT(*) FROM bookings b WHERE b.client_id = u.user_id) as booking_count " +
            "FROM users u " +
            "ORDER BY u.user_id DESC"
        );
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> user = new HashMap<>();
            user.put("id", rs.getInt("user_id"));
            user.put("username", rs.getString("email")); // Using email as username
            user.put("email", rs.getString("email"));
            user.put("first_name", rs.getString("first_name"));
            user.put("last_name", rs.getString("last_name"));
            user.put("status", rs.getBoolean("is_active") ? "active" : "inactive");
            
            // Get role name from role_id
            int roleId = rs.getInt("role_id");
            PreparedStatement roleStmt = conn.prepareStatement("SELECT name FROM roles WHERE role_id = ?");
            roleStmt.setInt(1, roleId);
            ResultSet roleRs = roleStmt.executeQuery();
            if (roleRs.next()) {
                user.put("role", roleRs.getString("name"));
            } else {
                user.put("role", "unknown");
            }
            roleRs.close();
            roleStmt.close();
            
            user.put("created_at", rs.getTimestamp("created_at"));
            user.put("booking_count", rs.getInt("booking_count"));
            user.put("profile_image", ""); // Default empty profile image
            
            usersList.add(user);
        }
        
    } catch (Exception e) {
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
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZAIRTAM - Users Management</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
        }
        
        .user-card {
            transition: all 0.3s ease;
        }
        
        .user-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
        }
        
        .sidebar {
            height: calc(100vh - 64px);
            position: sticky;
            top: 64px;
        }
        
        @media (max-width: 1024px) {
            .sidebar {
                position: fixed;
                left: -100%;
                top: 64px;
                bottom: 0;
                width: 250px;
                z-index: 40;
                transition: left 0.3s ease;
            }
            
            .sidebar.open {
                left: 0;
            }
        }
        
        .status-badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 500;
        }
        
        .status-active {
            background-color: #D1FAE5;
            color: #065F46;
        }
        
        .status-inactive {
            background-color: #FEE2E2;
            color: #B91C1C;
        }
        
        .status-pending {
            background-color: #FEF3C7;
            color: #92400E;
        }
        
        .role-badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 500;
        }
        
        .role-admin {
            background-color: #EFF6FF;
            color: #1E40AF;
        }
        
        .role-manager {
            background-color: #F3E8FF;
            color: #6B21A8;
        }
        
        .role-user {
            background-color: #F3F4F6;
            color: #374151;
        }
    </style>
</head>
<body class="bg-gray-50">
    <!-- Navigation -->
    <nav class="bg-white shadow-sm sticky top-0 z-50">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between items-center h-16">
                <!-- Logo -->
                <div class="flex items-center">
                    <button id="sidebar-toggle" class="lg:hidden mr-4 text-gray-500 hover:text-gray-700">
                        <i class="fas fa-bars text-xl"></i>
                    </button>
                    <a href="../index.jsp" class="flex items-center">
                        <i class="fas fa-hotel text-blue-600 text-2xl mr-2"></i>
                        <span class="text-xl font-bold text-gray-800">ZAIRTAM</span>
                    </a>
                </div>
                
                <!-- Search -->
                <div class="hidden md:flex items-center flex-1 max-w-md mx-8">
                    <div class="w-full relative">
                        <input type="text" placeholder="Search for hotels, users or bookings..." class="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                        <i class="fas fa-search absolute left-3 top-3 text-gray-400"></i>
                    </div>
                </div>
                
                <!-- Right Nav Items -->
                <div class="flex items-center space-x-4">
                    <button class="text-gray-500 hover:text-gray-700 relative">
                        <i class="fas fa-bell text-xl"></i>
                        <span class="absolute top-0 right-0 h-4 w-4 bg-red-500 rounded-full text-xs text-white flex items-center justify-center">5</span>
                    </button>
                    
                    <div class="relative">
                        <button class="flex items-center text-gray-800 hover:text-blue-600">
                            <% if (adminImage != null && !adminImage.isEmpty()) { %>
                                <img src="<%= adminImage %>" alt="Profile" class="h-8 w-8 rounded-full object-cover">
                            <% } else { %>
                                <i class="fas fa-user-circle text-gray-600 text-2xl"></i>
                            <% } %>
                            <span class="ml-2 hidden md:block"><%= adminName %></span>
                            <i class="fas fa-chevron-down ml-1 text-xs hidden md:block"></i>
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </nav>

    <div class="flex">
        <!-- Sidebar -->
        <aside class="bg-white w-64 shadow-sm sidebar" id="sidebar">
            <div class="p-4">
                <div class="mb-6">
                    <h3 class="text-xs uppercase text-gray-500 font-semibold tracking-wider">Main</h3>
                    <ul class="mt-3 space-y-1">
                        <li>
                            <a href="admin-dashboard.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-tachometer-alt w-5 text-center"></i>
                                <span class="ml-2">Dashboard</span>
                            </a>
                        </li>
                        <li>
                            <a href="hotels.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-hotel w-5 text-center"></i>
                                <span class="ml-2">Hotels</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-blue-600 bg-blue-50 rounded-md">
                                <i class="fas fa-users w-5 text-center"></i>
                                <span class="ml-2">Users</span>
                            </a>
                        </li>
                        <li>
                            <a href="bookings.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-calendar-alt w-5 text-center"></i>
                                <span class="ml-2">Bookings</span>
                            </a>
                        </li>
                    </ul>
                </div>
                
                <div class="mb-6">
                    <h3 class="text-xs uppercase text-gray-500 font-semibold tracking-wider">Analytics</h3>
                    <ul class="mt-3 space-y-1">
                        <li>
                            <a href="Reports.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-chart-line w-5 text-center"></i>
                                <span class="ml-2">Reports</span>
                            </a>
                        </li>
                        <li>
                            <a href="Revenue.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-money-bill-wave w-5 text-center"></i>
                                <span class="ml-2">Revenue</span>
                            </a>
                        </li>
                        <li>
                            <a href="Statistiques.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-chart-pie w-5 text-center"></i>
                                <span class="ml-2">Statistics</span>
                            </a>
                        </li>
                    </ul>
                </div>
                
                <div class="mb-6">
                    <h3 class="text-xs uppercase text-gray-500 font-semibold tracking-wider">Administration</h3>
                    <ul class="mt-3 space-y-1">
                        <li>
                            <a href="AdminUsers.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-user-shield w-5 text-center"></i>
                                <span class="ml-2">Admin Users</span>
                            </a>
                        </li>
                        <li>
                            <a href="Settings.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-cog w-5 text-center"></i>
                                <span class="ml-2">Settings</span>
                            </a>
                        </li>
                        <li>
                            <a href="Notifications.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-bell w-5 text-center"></i>
                                <span class="ml-2">Notifications</span>
                            </a>
                        </li>
                    </ul>
                </div>
                
                <div>
                    <h3 class="text-xs uppercase text-gray-500 font-semibold tracking-wider">Support</h3>
                    <ul class="mt-3 space-y-1">
                        <li>
                            <a href="Help-Center.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-question-circle w-5 text-center"></i>
                                <span class="ml-2">Help Center</span>
                            </a>
                        </li>
                        <li>
                            <a href="Contact-Support.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-headset w-5 text-center"></i>
                                <span class="ml-2">Contact Support</span>
                            </a>
                        </li>
                    </ul>
                </div>
            </div>
        </aside>

        <!-- Main Content -->
        <main class="flex-1 p-6">
            <div class="flex justify-between items-center mb-8">
                <div>
                    <h1 class="text-2xl font-bold text-gray-800">Users Management</h1>
                    <p class="text-gray-600">Manage all registered users in the system</p>
                </div>
                <button class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg transition duration-200 flex items-center">
                    <i class="fas fa-plus mr-2"></i> Add New User
                </button>
            </div>
            
            <!-- Filters Section -->
            <div class="bg-white rounded-lg shadow-sm p-6 mb-8">
                <div class="flex flex-wrap items-center justify-between">
                    <h3 class="text-lg font-semibold text-gray-800 mb-4 md:mb-0">Filter Users</h3>
                    
                    <div class="flex flex-wrap gap-4">
                        <div class="w-full md:w-auto">
                            <label for="role-filter" class="block text-sm font-medium text-gray-700 mb-1">Role</label>
                            <select id="role-filter" class="w-full md:w-48 px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                <option value="all">All Roles</option>
                                <option value="admin">Admin</option>
                                <option value="manager">Manager</option>
                                <option value="user">User</option>
                            </select>
                        </div>
                        
                        <div class="w-full md:w-auto">
                            <label for="status-filter" class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                            <select id="status-filter" class="w-full md:w-48 px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                <option value="all">All Status</option>
                                <option value="active">Active</option>
                                <option value="inactive">Inactive</option>
                                <option value="pending">Pending</option>
                            </select>
                        </div>
                        
                        <div class="w-full md:w-auto">
                            <label for="date-filter" class="block text-sm font-medium text-gray-700 mb-1">Registration Date</label>
                            <select id="date-filter" class="w-full md:w-48 px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                <option value="all">All Time</option>
                                <option value="today">Today</option>
                                <option value="week">This Week</option>
                                <option value="month">This Month</option>
                                <option value="year">This Year</option>
                            </select>
                        </div>
                        
                        <div class="w-full md:w-auto flex items-end">
                            <button class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg transition duration-200">
                                <i class="fas fa-filter mr-1"></i> Apply Filters
                            </button>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Users Stats Cards -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Total Users</h3>
                        <div class="bg-blue-100 p-2 rounded-md">
                            <i class="fas fa-users text-blue-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= totalUsersCount %></p>
                        <p class="text-green-600 text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-up mr-1"></i>8%
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Compared to last month</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Active Users</h3>
                        <div class="bg-green-100 p-2 rounded-md">
                            <i class="fas fa-user-check text-green-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= activeUsersCount %></p>
                        <p class="text-green-600 text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-up mr-1"></i>5%
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Compared to last month</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">New Users This Month</h3>
                        <div class="bg-purple-100 p-2 rounded-md">
                            <i class="fas fa-user-plus text-purple-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= newUsersThisMonth %></p>
                        <p class="text-green-600 text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-up mr-1"></i>12%
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Compared to last month</p>
                </div>
            </div>
            
            <!-- Users Table -->
            <div class="bg-white rounded-lg shadow-sm overflow-hidden mb-8">
                <div class="p-6 border-b">
                    <h3 class="text-lg font-semibold text-gray-800">All Users</h3>
                </div>
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Role</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Bookings</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Joined Date</th>
                                <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            <% 
                            SimpleDateFormat dateFormat = new SimpleDateFormat("MMM d, yyyy");
                            for (Map<String, Object> user : usersList) {
                                String fullName = user.get("first_name") + " " + user.get("last_name");
                                String profileImage = user.get("profile_image") != null ? 
                                    user.get("profile_image").toString() : 
                                    "https://ui-avatars.com/api/?name=" + fullName.replace(" ", "+") + "&background=random";
                                
                                Date createdAt = (Date) user.get("created_at");
                                String formattedDate = createdAt != null ? dateFormat.format(createdAt) : "N/A";
                            %>
                            <tr>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="flex items-center">
                                        <div class="flex-shrink-0 h-10 w-10">
                                            <img class="h-10 w-10 rounded-full object-cover" 
                                                 src="<%= profileImage %>" 
                                                 alt="<%= fullName %>">
                                        </div>
                                        <div class="ml-4">
                                            <div class="text-sm font-medium text-gray-900"><%= fullName %></div>
                                            <div class="text-sm text-gray-500">@<%= user.get("username") %></div>
                                        </div>
                                    </div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm text-gray-900"><%= user.get("email") %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <% 
                                    String role = (String) user.get("role");
                                    String roleClass = "";
                                    
                                    if ("admin".equalsIgnoreCase(role)) {
                                        roleClass = "role-admin";
                                    } else if ("manager".equalsIgnoreCase(role)) {
                                        roleClass = "role-manager";
                                    } else {
                                        roleClass = "role-user";
                                    }
                                    %>
                                    <span class="role-badge <%= roleClass %>">
                                        <%= role != null ? role.substring(0, 1).toUpperCase() + role.substring(1) : "User" %>
                                    </span>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <% 
                                    String status = (String) user.get("status");
                                    String statusClass = "";
                                    String statusIcon = "";
                                    
                                    if ("active".equalsIgnoreCase(status)) {
                                        statusClass = "status-active";
                                        statusIcon = "fa-check-circle";
                                    } else if ("pending".equalsIgnoreCase(status)) {
                                        statusClass = "status-pending";
                                        statusIcon = "fa-clock";
                                    } else {
                                        statusClass = "status-inactive";
                                        statusIcon = "fa-times-circle";
                                    }
                                    %>
                                    <span class="status-badge <%= statusClass %>">
                                        <i class="fas <%= statusIcon %> mr-1"></i>
                                        <%= status != null ? status.substring(0, 1).toUpperCase() + status.substring(1) : "Inactive" %>
                                    </span>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm text-gray-900"><%= user.get("booking_count") %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm text-gray-900"><%= formattedDate %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                    <div class="flex justify-end space-x-2">
                                        <button class="text-blue-600 hover:text-blue-900" title="View Details">
                                            <i class="fas fa-eye"></i>
                                        </button>
                                        <button class="text-indigo-600 hover:text-indigo-900" title="Edit User">
                                            <i class="fas fa-edit"></i>
                                        </button>
                                        <button class="text-red-600 hover:text-red-900" title="Delete User">
                                            <i class="fas fa-trash-alt"></i>
                                        </button>
                                    </div>
                                </td>
                            </tr>
                            <% } %>
                            
                            <!-- If no users found -->
                            <% if (usersList.isEmpty()) { %>
                            <tr>
                                <td colspan="7" class="px-6 py-4 text-center text-gray-500">
                                    No users found. Add a new user to get started.
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
                
                <!-- Pagination -->
                <div class="px-6 py-4 flex items-center justify-between border-t">
                    <div class="flex-1 flex justify-between sm:hidden">
                        <a href="#" class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                            Previous
                        </a>
                        <a href="#" class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                            Next
                        </a>
                    </div>
                    <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
                        <div>
                            <p class="text-sm text-gray-700">
                                Showing <span class="font-medium">1</span> to <span class="font-medium">10</span> of <span class="font-medium"><%= totalUsersCount %></span> users
                            </p>
                        </div>
                        <div>
                            <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
                                <a href="#" class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50">
                                    <span class="sr-only">Previous</span>
                                    <i class="fas fa-chevron-left"></i>
                                </a>
                                <a href="#" aria-current="page" class="z-10 bg-blue-50 border-blue-500 text-blue-600 relative inline-flex items-center px-4 py-2 border text-sm font-medium">
                                    1
                                </a>
                                <a href="#" class="bg-white border-gray-300 text-gray-500 hover:bg-gray-50 relative inline-flex items-center px-4 py-2 border text-sm font-medium">
                                    2
                                </a>
                                <a href="#" class="bg-white border-gray-300 text-gray-500 hover:bg-gray-50 relative inline-flex items-center px-4 py-2 border text-sm font-medium">
                                    3
                                </a>
                                <span class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-gray-50 text-sm font-medium text-gray-700">
                                    ...
                                </span>
                                <a href="#" class="bg-white border-gray-300 text-gray-500 hover:bg-gray-50 relative inline-flex items-center px-4 py-2 border text-sm font-medium">
                                    8
                                </a>
                                <a href="#" class="bg-white border-gray-300 text-gray-500 hover:bg-gray-50 relative inline-flex items-center px-4 py-2 border text-sm font-medium">
                                    9
                                </a>
                                <a href="#" class="bg-white border-gray-300 text-gray-500 hover:bg-gray-50 relative inline-flex items-center px-4 py-2 border text-sm font-medium">
                                    10
                                </a>
                                <a href="#" class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50">
                                    <span class="sr-only">Next</span>
                                    <i class="fas fa-chevron-right"></i>
                                </a>
                            </nav>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Delete Confirmation Modal -->
            <div id="deleteModal" class="fixed inset-0 bg-gray-900 bg-opacity-50 hidden items-center justify-center z-50">
                <div class="bg-white rounded-lg shadow-xl max-w-md w-full p-6">
                    <div class="text-center mb-6">
                        <div class="bg-red-100 h-20 w-20 rounded-full flex items-center justify-center mx-auto mb-4">
                            <i class="fas fa-exclamation-triangle text-red-600 text-3xl"></i>
                        </div>
                        <h3 class="text-lg font-bold text-gray-900 mb-1">Delete User</h3>
                        <p class="text-gray-500" id="deleteModalText">Are you sure you want to delete this user?</p>
                    </div>
                    <div class="flex space-x-3">
                        <button onclick="closeDeleteModal()" class="flex-1 px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-800 rounded-lg transition duration-200">
                            Cancel
                        </button>
                        <form action="delete-user.jsp" method="post" class="flex-1">
                            <input type="hidden" name="user_id" id="deleteUserId">
                            <button type="submit" class="w-full px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg transition duration-200">
                                Delete
                            </button>
                        </form>
                    </div>
                </div>
            </div>
            
            <!-- JavaScript for sidebar toggle and delete confirmation -->
            <script>
                // Sidebar toggle
                document.getElementById('sidebar-toggle').addEventListener('click', function() {
                    document.getElementById('sidebar').classList.toggle('open');
                });
                
                // Close sidebar when clicking outside on mobile
                document.addEventListener('click', function(event) {
                    const sidebar = document.getElementById('sidebar');
                    const sidebarToggle = document.getElementById('sidebar-toggle');
                    
                    if (window.innerWidth < 1024 && 
                        !sidebar.contains(event.target) && 
                        !sidebarToggle.contains(event.target) &&
                        sidebar.classList.contains('open')) {
                        sidebar.classList.remove('open');
                    }
                });
                
                // Delete confirmation modal
                function confirmDelete(userId, userName) {
                    document.getElementById('deleteUserId').value = userId;
                    document.getElementById('deleteModalText').textContent = `Are you sure you want to delete "${userName}"?`;
                    document.getElementById('deleteModal').classList.remove('hidden');
                    document.getElementById('deleteModal').classList.add('flex');
                }
                
                function closeDeleteModal() {
                    document.getElementById('deleteModal').classList.add('hidden');
                    document.getElementById('deleteModal').classList.remove('flex');
                }
                
                // Filter functionality
                document.querySelector('button.bg-blue-600').addEventListener('click', function() {
                    const roleFilter = document.getElementById('role-filter').value;
                    const statusFilter = document.getElementById('status-filter').value;
                    const dateFilter = document.getElementById('date-filter').value;
                    
                    // Redirect with filter parameters
                    window.location.href = `users.jsp?role=${roleFilter}&status=${statusFilter}&date=${dateFilter}`;
                });
            </script>
        </main>
    </div>
</body>
</html>
