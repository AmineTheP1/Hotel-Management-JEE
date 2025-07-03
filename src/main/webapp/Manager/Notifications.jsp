<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    // Database connection parameters
    String url = "jdbc:mysql://localhost:3306/hotels_db"; // Change to your database name
    String username = "root"; // Change to your database username
    String password = ""; // Change to your database password
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // Lists to store data
    List<Map<String, Object>> notificationsList = new ArrayList<>();
    List<Map<String, Object>> notificationsByTypeList = new ArrayList<>();
    List<Map<String, Object>> unreadNotificationsByUserList = new ArrayList<>();
    List<Map<String, Object>> recentNotificationsList = new ArrayList<>();
    
    // Statistics
    int totalNotifications = 0;
    int unreadNotifications = 0;
    int systemNotifications = 0;
    int userNotifications = 0;
    
    // Monthly data for charts
    List<Integer> monthlyNotifications = new ArrayList<>(Arrays.asList(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));
    List<String> months = Arrays.asList("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
    
    // Get current month and year
    Calendar cal = Calendar.getInstance();
    int currentMonth = cal.get(Calendar.MONTH);
    int currentYear = cal.get(Calendar.YEAR);
    
    // Variables for notification actions
    String successMessage = "";
    String errorMessage = "";
    
    // Process form submissions
    if (request.getMethod().equals("POST")) {
        String action = request.getParameter("action");
        
        try {
            // Establish database connection
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(url, username, password);
            
            if ("mark_read".equals(action)) {
                // Mark notifications as read
                String[] notificationIds = request.getParameterValues("notification_ids");
                if (notificationIds != null && notificationIds.length > 0) {
                    String updateQuery = "UPDATE notifications SET is_read = 1 WHERE id = ?";
                    pstmt = conn.prepareStatement(updateQuery);
                    
                    for (String id : notificationIds) {
                        pstmt.setInt(1, Integer.parseInt(id));
                        pstmt.executeUpdate();
                    }
                    
                    successMessage = "Selected notifications marked as read.";
                }
            } else if ("delete".equals(action)) {
                // Delete notifications
                String[] notificationIds = request.getParameterValues("notification_ids");
                if (notificationIds != null && notificationIds.length > 0) {
                    String deleteQuery = "DELETE FROM notifications WHERE id = ?";
                    pstmt = conn.prepareStatement(deleteQuery);
                    
                    for (String id : notificationIds) {
                        pstmt.setInt(1, Integer.parseInt(id));
                        pstmt.executeUpdate();
                    }
                    
                    successMessage = "Selected notifications deleted successfully.";
                }
            } else if ("send".equals(action)) {
                // Send a new notification
                String title = request.getParameter("title");
                String message = request.getParameter("message");
                String type = request.getParameter("type");
                String[] recipientIds = request.getParameterValues("recipient_ids");
                
                if (title != null && !title.isEmpty() && message != null && !message.isEmpty()) {
                    if ("system".equals(type)) {
                        // System notification to all users
                        String insertQuery = "INSERT INTO notifications (title, message, type, created_at, is_read) VALUES (?, ?, 'system', NOW(), 0)";
                        pstmt = conn.prepareStatement(insertQuery);
                        pstmt.setString(1, title);
                        pstmt.setString(2, message);
                        pstmt.executeUpdate();
                        
                        successMessage = "System notification sent to all users.";
                    } else if ("user".equals(type) && recipientIds != null && recipientIds.length > 0) {
                        // User-specific notifications
                        String insertQuery = "INSERT INTO notifications (title, message, type, user_id, created_at, is_read) VALUES (?, ?, 'user', ?, NOW(), 0)";
                        pstmt = conn.prepareStatement(insertQuery);
                        
                        for (String userId : recipientIds) {
                            pstmt.setString(1, title);
                            pstmt.setString(2, message);
                            pstmt.setInt(3, Integer.parseInt(userId));
                            pstmt.executeUpdate();
                        }
                        
                        successMessage = "Notifications sent to selected users.";
                    } else {
                        errorMessage = "Please select valid recipients for user notifications.";
                    }
                } else {
                    errorMessage = "Title and message are required.";
                }
            }
        } catch (Exception e) {
            errorMessage = "Error processing request: " + e.getMessage();
            e.printStackTrace();
        } finally {
            try {
                if (pstmt != null) pstmt.close();
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
    
    try {
        // Establish database connection
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(url, username, password);
        
        // Get notification statistics
        String statsQuery = "SELECT " +
                           "COUNT(*) as total_notifications, " +
                           "SUM(CASE WHEN is_read = 0 THEN 1 ELSE 0 END) as unread_notifications, " +
                           "SUM(CASE WHEN type = 'system' THEN 1 ELSE 0 END) as system_notifications, " +
                           "SUM(CASE WHEN type = 'user' THEN 1 ELSE 0 END) as user_notifications " +
                           "FROM notifications";
        
        pstmt = conn.prepareStatement(statsQuery);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            totalNotifications = rs.getInt("total_notifications");
            unreadNotifications = rs.getInt("unread_notifications");
            systemNotifications = rs.getInt("system_notifications");
            userNotifications = rs.getInt("user_notifications");
        }
        
        rs.close();
        pstmt.close();
        
        // Get all notifications
        String notificationsQuery = "SELECT n.id, n.title, n.message, n.type, n.is_read, n.created_at, " +
                                   "u.id as user_id, u.first_name, u.last_name, u.email " +
                                   "FROM notifications n " +
                                   "LEFT JOIN users u ON n.user_id = u.id " +
                                   "ORDER BY n.created_at DESC " +
                                   "LIMIT 100";
        
        pstmt = conn.prepareStatement(notificationsQuery);
        rs = pstmt.executeQuery();
        
        SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy, HH:mm");
        
        while (rs.next()) {
            Map<String, Object> notification = new HashMap<>();
            notification.put("id", rs.getInt("id"));
            notification.put("title", rs.getString("title"));
            notification.put("message", rs.getString("message"));
            notification.put("type", rs.getString("type"));
            notification.put("is_read", rs.getBoolean("is_read"));
            notification.put("created_at", dateFormat.format(rs.getTimestamp("created_at")));
            
            if ("user".equals(rs.getString("type"))) {
                notification.put("user_id", rs.getInt("user_id"));
                notification.put("user_name", rs.getString("first_name") + " " + rs.getString("last_name"));
                notification.put("user_email", rs.getString("email"));
            } else {
                notification.put("user_id", null);
                notification.put("user_name", "All Users");
                notification.put("user_email", "System Notification");
            }
            
            notificationsList.add(notification);
            
            // Add to recent notifications (limit to 5)
            if (recentNotificationsList.size() < 5) {
                recentNotificationsList.add(notification);
            }
        }
        
        rs.close();
        pstmt.close();
        
        // Get notifications by type
        String typeQuery = "SELECT type, COUNT(*) as count " +
                          "FROM notifications " +
                          "GROUP BY type " +
                          "ORDER BY count DESC";
        
        pstmt = conn.prepareStatement(typeQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> typeData = new HashMap<>();
            typeData.put("type", rs.getString("type"));
            typeData.put("count", rs.getInt("count"));
            
            notificationsByTypeList.add(typeData);
        }
        
        rs.close();
        pstmt.close();
        
        // Get unread notifications by user
        String unreadByUserQuery = "SELECT u.id, u.first_name, u.last_name, u.email, " +
                                  "COUNT(n.id) as unread_count " +
                                  "FROM users u " +
                                  "JOIN notifications n ON u.id = n.user_id " +
                                  "WHERE n.is_read = 0 " +
                                  "GROUP BY u.id " +
                                  "ORDER BY unread_count DESC " +
                                  "LIMIT 10";
        
        pstmt = conn.prepareStatement(unreadByUserQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> userData = new HashMap<>();
            userData.put("user_id", rs.getInt("id"));
            userData.put("user_name", rs.getString("first_name") + " " + rs.getString("last_name"));
            userData.put("email", rs.getString("email"));
            userData.put("unread_count", rs.getInt("unread_count"));
            
            unreadNotificationsByUserList.add(userData);
        }
        
        rs.close();
        pstmt.close();
        
        // Get monthly notifications data for the current year
        String monthlyDataQuery = "SELECT MONTH(created_at) as month, " +
                                 "COUNT(*) as notification_count " +
                                 "FROM notifications " +
                                 "WHERE YEAR(created_at) = ? " +
                                 "GROUP BY MONTH(created_at) " +
                                 "ORDER BY month";
        
        pstmt = conn.prepareStatement(monthlyDataQuery);
        pstmt.setInt(1, currentYear);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            int month = rs.getInt("month") - 1; // 0-based index
            int notificationCount = rs.getInt("notification_count");
            monthlyNotifications.set(month, notificationCount);
        }
        
    } catch (Exception e) {
        errorMessage = "Error retrieving notification data: " + e.getMessage();
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
    
    // Convert data to JSON for charts
    StringBuilder monthlyNotificationsJson = new StringBuilder("[");
    for (Integer count : monthlyNotifications) {
        monthlyNotificationsJson.append(count).append(",");
    }
    if (monthlyNotificationsJson.charAt(monthlyNotificationsJson.length() - 1) == ',') {
        monthlyNotificationsJson.setLength(monthlyNotificationsJson.length() - 1);
    }
    monthlyNotificationsJson.append("]");
    
    // Notification types data for charts
    StringBuilder notificationTypesJson = new StringBuilder("[");
    StringBuilder notificationTypeCountsJson = new StringBuilder("[");
    
    for (Map<String, Object> type : notificationsByTypeList) {
        notificationTypesJson.append("\"").append(type.get("type")).append("\",");
        notificationTypeCountsJson.append(type.get("count")).append(",");
    }
    
    if (notificationTypesJson.charAt(notificationTypesJson.length() - 1) == ',') {
        notificationTypesJson.setLength(notificationTypesJson.length() - 1);
    }
    notificationTypesJson.append("]");
    
    if (notificationTypeCountsJson.charAt(notificationTypeCountsJson.length() - 1) == ',') {
        notificationTypeCountsJson.setLength(notificationTypeCountsJson.length() - 1);
    }
    notificationTypeCountsJson.append("]");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZAIRTAM - Notifications Management</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
        }
        
        .stats-card {
            transition: all 0.3s ease;
        }
        
        .stats-card:hover {
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
        
        .chart-container {
            position: relative;
            height: 300px;
            width: 100%;
        }
        
        .notification-item {
            transition: all 0.2s ease;
        }
        
        .notification-item:hover {
            background-color: #f9fafb;
        }
        
        .notification-unread {
            border-left: 4px solid #3b82f6;
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
                        <input type="text" placeholder="Search for notifications..." class="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                        <i class="fas fa-search absolute left-3 top-3 text-gray-400"></i>
                    </div>
                </div>
                
                <!-- Right Nav Items -->
                <div class="flex items-center space-x-4">
                    <button class="text-gray-500 hover:text-gray-700 relative">
                        <i class="fas fa-bell text-xl"></i>
                        <span class="absolute top-0 right-0 h-4 w-4 bg-red-500 rounded-full text-xs text-white flex items-center justify-center"><%= unreadNotifications %></span>
                    </button>
                    
                    <div class="relative">
                        <button class="flex items-center text-gray-800 hover:text-blue-600">
                            <img src="https://randomuser.me/api/portraits/women/28.jpg" alt="Profile" class="h-8 w-8 rounded-full object-cover">
                            <span class="ml-2 hidden md:block">Admin Smith</span>
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
                            <a href="users.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
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
                    <h3 class="text-xs uppercase text-gray-500 font-semibold tracking-wider">Management</h3>
                    <ul class="mt-3 space-y-1">
                        <li>
                            <a href="AdminUsers.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-user-shield w-5 text-center"></i>
                                <span class="ml-2">Admin Users</span>
                            </a>
                        </li>
                        <li>
                            <a href="Notifications.jsp" class="flex items-center px-3 py-2 text-blue-600 bg-blue-50 rounded-md">
                                <i class="fas fa-bell w-5 text-center"></i>
                                <span class="ml-2">Notifications</span>
                            </a>
                        </li>
                        <li>
                            <a href="Settings.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-cog w-5 text-center"></i>
                                <span class="ml-2">Settings</span>
                            </a>
                        </li>
                    </ul>
                </div>
            </div>
        </aside>

        <!-- Main Content -->
        <main class="flex-1 p-4 sm:p-6 lg:p-8">
            <div class="max-w-7xl mx-auto">
                <!-- Page Header -->
                <div class="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
                    <div>
                        <h1 class="text-2xl font-bold text-gray-900">Notifications Management</h1>
                        <p class="mt-1 text-sm text-gray-600">Manage and monitor all system notifications</p>
                    </div>
                    <div class="mt-4 md:mt-0">
                        <button type="button" class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500" data-modal-toggle="send-notification-modal">
                            <i class="fas fa-plus mr-2"></i>
                            Send New Notification
                        </button>
                    </div>
                </div>
                
                <% if (!successMessage.isEmpty()) { %>
                <div class="bg-green-50 border-l-4 border-green-400 p-4 mb-6">
                    <div class="flex">
                        <div class="flex-shrink-0">
                            <i class="fas fa-check-circle text-green-400"></i>
                        </div>
                        <div class="ml-3">
                            <p class="text-sm text-green-700"><%= successMessage %></p>
                        </div>
                    </div>
                </div>
                <% } %>
                
                <% if (!errorMessage.isEmpty()) { %>
                <div class="bg-red-50 border-l-4 border-red-400 p-4 mb-6">
                    <div class="flex">
                        <div class="flex-shrink-0">
                            <i class="fas fa-exclamation-circle text-red-400"></i>
                        </div>
                        <div class="ml-3">
                            <p class="text-sm text-red-700"><%= errorMessage %></p>
                        </div>
                    </div>
                </div>
                <% } %>
                
                <!-- Stats Cards -->
                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
                    <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                        <div class="flex items-center">
                            <div class="flex-shrink-0 bg-blue-100 rounded-full p-3">
                                <i class="fas fa-bell text-blue-600 text-xl"></i>
                            </div>
                            <div class="ml-5">
                                <p class="text-sm font-medium text-gray-500">Total Notifications</p>
                                <h3 class="text-xl font-bold text-gray-900"><%= totalNotifications %></h3>
                            </div>
                        </div>
                    </div>
                    
                    <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                        <div class="flex items-center">
                            <div class="flex-shrink-0 bg-red-100 rounded-full p-3">
                                <i class="fas fa-envelope text-red-600 text-xl"></i>
                            </div>
                            <div class="ml-5">
                                <p class="text-sm font-medium text-gray-500">Unread Notifications</p>
                                <h3 class="text-xl font-bold text-gray-900"><%= unreadNotifications %></h3>
                            </div>
                        </div>
                    </div>
                    
                    <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                        <div class="flex items-center">
                            <div class="flex-shrink-0 bg-green-100 rounded-full p-3">
                                <i class="fas fa-bullhorn text-green-600 text-xl"></i>
                            </div>
                            <div class="ml-5">
                                <p class="text-sm font-medium text-gray-500">System Notifications</p>
                                <h3 class="text-xl font-bold text-gray-900"><%= systemNotifications %></h3>
                            </div>
                        </div>
                    </div>
                    
                    <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                        <div class="flex items-center">
                            <div class="flex-shrink-0 bg-purple-100 rounded-full p-3">
                                <i class="fas fa-user-bell text-purple-600 text-xl"></i>
                            </div>
                            <div class="ml-5">
                                <p class="text-sm font-medium text-gray-500">User Notifications</p>
                                <h3 class="text-xl font-bold text-gray-900"><%= userNotifications %></h3>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Charts Section -->
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
                    <!-- Monthly Notifications Chart -->
                    <div class="bg-white rounded-lg shadow-sm p-6">
                        <h3 class="text-lg font-semibold text-gray-800 mb-4">Monthly Notifications</h3>
                        <div class="chart-container">
                            <canvas id="monthlyNotificationsChart"></canvas>
                        </div>
                    </div>
                    
                    <!-- Notifications by Type Chart -->
                    <div class="bg-white rounded-lg shadow-sm p-6">
                        <h3 class="text-lg font-semibold text-gray-800 mb-4">Notifications by Type</h3>
                        <div class="chart-container">
                            <canvas id="notificationTypeChart"></canvas>
                        </div>
                    </div>
                </div>
                
                <!-- Notifications Management Section -->
                <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    <!-- All Notifications -->
                    <div class="lg:col-span-2">
                        <div class="bg-white rounded-lg shadow-sm overflow-hidden">
                            <div class="px-6 py-4 border-b border-gray-200 bg-gray-50">
                                <div class="flex items-center justify-between">
                                    <h3 class="text-lg font-semibold text-gray-800">All Notifications</h3>
                                    <div class="flex space-x-2">
                                        <button id="mark-read-btn" class="text-sm px-3 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200" disabled>
                                            <i class="fas fa-check-double mr-1"></i> Mark as Read
                                        </button>
                                        <button id="delete-btn" class="text-sm px-3 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200" disabled>
                                            <i class="fas fa-trash-alt mr-1"></i> Delete
                                        </button>
                                    </div>
                                </div>
                            </div>
                            
                            <form id="notifications-form" method="post" action="Notifications.jsp">
                                <input type="hidden" name="action" id="notification-action" value="">
                                
                                <div class="overflow-x-auto">
                                    <table class="min-w-full divide-y divide-gray-200">
                                        <thead class="bg-gray-50">
                                            <tr>
                                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                                    <div class="flex items-center">
                                                        <input type="checkbox" id="select-all" class="h-4 w-4 text-blue-600 border-gray-300 rounded">
                                                        <label for="select-all" class="sr-only">Select All</label>
                                                    </div>
                                                </th>
                                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                                    Title
                                                </th>
                                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                                    Type
                                                </th>
                                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                                    Recipient
                                                </th>
                                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                                    Date
                                                </th>
                                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                                    Status
                                                </th>
                                                <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                                                    Actions
                                                </th>
                                            </tr>
                                        </thead>
                                        <tbody class="bg-white divide-y divide-gray-200">
                                            <% if (notificationsList.isEmpty()) { %>
                                                <tr>
                                                    <td colspan="7" class="px-6 py-4 text-center text-sm text-gray-500">
                                                        No notifications found
                                                    </td>
                                                </tr>
                                            <% } else { %>
                                                <% for (Map<String, Object> notification : notificationsList) { %>
                                                    <tr class="notification-item <%= notification.get("is_read").equals(false) ? "notification-unread" : "" %>">
                                                        <td class="px-6 py-4 whitespace-nowrap">
                                                            <div class="flex items-center">
                                                                <input type="checkbox" name="notification_ids" value="<%= notification.get("id") %>" class="notification-checkbox h-4 w-4 text-blue-600 border-gray-300 rounded">
                                                            </div>
                                                        </td>
                                                        <td class="px-6 py-4">
                                                            <div class="text-sm font-medium text-gray-900"><%= notification.get("title") %></div>
                                                            <div class="text-sm text-gray-500 truncate max-w-xs"><%= notification.get("message") %></div>
                                                        </td>
                                                        <td class="px-6 py-4 whitespace-nowrap">
                                                            <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full <%= "system".equals(notification.get("type")) ? "bg-purple-100 text-purple-800" : "bg-green-100 text-green-800" %>">
                                                                <%= notification.get("type") %>
                                                            </span>
                                                        </td>
                                                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                                            <%= notification.get("user_name") %>
                                                        </td>
                                                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                                            <%= notification.get("created_at") %>
                                                        </td>
                                                        <td class="px-6 py-4 whitespace-nowrap">
                                                            <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full <%= notification.get("is_read").equals(false) ? "bg-yellow-100 text-yellow-800" : "bg-gray-100 text-gray-800" %>">
                                                                <%= notification.get("is_read").equals(false) ? "Unread" : "Read" %>
                                                            </span>
                                                        </td>
                                                        <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                                            <button type="button" class="text-blue-600 hover:text-blue-900 view-notification" data-id="<%= notification.get("id") %>" data-title="<%= notification.get("title") %>" data-message="<%= notification.get("message") %>">
                                                                View
                                                            </button>
                                                        </td>
                                                    </tr>
                                                <% } %>
                                            <% } %>
                                        </tbody>
                                    </table>
                                </div>
                                
                                <div class="mt-4 flex space-x-3">
                                    <button type="button" id="mark-read-btn" class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
                                        <i class="fas fa-check-circle mr-2"></i>
                                        Mark as Read
                                    </button>
                                    <button type="button" id="delete-btn" class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
                                        <i class="fas fa-trash-alt mr-2"></i>
                                        Delete
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                    
                    <!-- Send New Notification -->
                    <div class="bg-white shadow rounded-lg mt-6">
                        <div class="px-6 py-4 border-b">
                            <h3 class="text-lg font-medium text-gray-900">Send New Notification</h3>
                        </div>
                        <div class="p-6">
                            <form action="Notifications.jsp" method="post">
                                <input type="hidden" name="action" value="send">
                                
                                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                                    <div class="col-span-1 md:col-span-2">
                                        <label for="title" class="block text-sm font-medium text-gray-700 mb-1">Title</label>
                                        <input type="text" id="title" name="title" class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500" required>
                                    </div>
                                    
                                    <div class="col-span-1 md:col-span-2">
                                        <label for="message" class="block text-sm font-medium text-gray-700 mb-1">Message</label>
                                        <textarea id="message" name="message" rows="4" class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500" required></textarea>
                                    </div>
                                    
                                    <div>
                                        <label for="type" class="block text-sm font-medium text-gray-700 mb-1">Notification Type</label>
                                        <select id="type" name="type" class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                                            <option value="system">System (All Users)</option>
                                            <option value="user">Specific Users</option>
                                        </select>
                                    </div>
                                    
                                    <div id="recipients-container" style="display: none;">
                                        <label for="recipient_ids" class="block text-sm font-medium text-gray-700 mb-1">Recipients</label>
                                        <select id="recipient_ids" name="recipient_ids" multiple class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                                            <% 
                                            try {
                                                // Establish database connection
                                                Class.forName("com.mysql.cj.jdbc.Driver");
                                                conn = DriverManager.getConnection(url, username, password);
                                                
                                                // Get all users
                                                String usersQuery = "SELECT id, first_name, last_name, email FROM users ORDER BY first_name, last_name";
                                                pstmt = conn.prepareStatement(usersQuery);
                                                rs = pstmt.executeQuery();
                                                
                                                while (rs.next()) {
                                                    int userId = rs.getInt("id");
                                                    String userName = rs.getString("first_name") + " " + rs.getString("last_name");
                                                    String userEmail = rs.getString("email");
                                            %>
                                                <option value="<%= userId %>"><%= userName %> (<%= userEmail %>)</option>
                                            <% 
                                                }
                                            } catch (Exception e) {
                                                e.printStackTrace();
                                            } finally {
                                                try {
                                                    if (rs != null) rs.close();
                                                    if (pstmt != null) pstmt.close();
                                                    if (conn != null) conn.close();
                                                } catch (SQLException e) {
                                                    e.printStackTrace();
                                                }
                                            }
                                            %>
                                        </select>
                                        <p class="mt-1 text-xs text-gray-500">Hold Ctrl/Cmd to select multiple users</p>
                                    </div>
                                </div>
                                
                                <div class="mt-6 flex justify-end">
                                    <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
                                        Send Notification
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
                
                <!-- Right Sidebar -->
                <div class="hidden lg:block lg:col-span-1">
                    <!-- Notification Stats -->
                    <div class="bg-white shadow rounded-lg mb-6">
                        <div class="px-6 py-4 border-b">
                            <h3 class="text-lg font-medium text-gray-900">Notification Stats</h3>
                        </div>
                        <div class="p-6">
                            <div class="flex items-center justify-between mb-4">
                                <div class="text-sm text-gray-500">Total Notifications</div>
                                <div class="text-lg font-semibold"><%= totalNotifications %></div>
                            </div>
                            <div class="flex items-center justify-between mb-4">
                                <div class="text-sm text-gray-500">Unread Notifications</div>
                                <div class="text-lg font-semibold text-yellow-600"><%= unreadNotifications %></div>
                            </div>
                            <div class="flex items-center justify-between mb-4">
                                <div class="text-sm text-gray-500">System Notifications</div>
                                <div class="text-lg font-semibold text-purple-600"><%= systemNotifications %></div>
                            </div>
                            <div class="flex items-center justify-between">
                                <div class="text-sm text-gray-500">User Notifications</div>
                                <div class="text-lg font-semibold text-green-600"><%= userNotifications %></div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Recent Notifications -->
                    <div class="bg-white shadow rounded-lg mb-6">
                        <div class="px-6 py-4 border-b">
                            <h3 class="text-lg font-medium text-gray-900">Recent Notifications</h3>
                        </div>
                        <div class="p-6">
                            <% if (recentNotificationsList.isEmpty()) { %>
                                <p class="text-sm text-gray-500">No recent notifications</p>
                            <% } else { %>
                                <ul class="divide-y divide-gray-200">
                                    <% for (Map<String, Object> notification : recentNotificationsList) { %>
                                        <li class="py-3">
                                            <div class="flex items-start">
                                                <div class="flex-shrink-0 mt-1">
                                                    <span class="inline-block h-2 w-2 rounded-full <%= notification.get("is_read").equals(false) ? "bg-blue-600" : "bg-gray-300" %>"></span>
                                                </div>
                                                <div class="ml-3 flex-1">
                                                    <p class="text-sm font-medium text-gray-900"><%= notification.get("title") %></p>
                                                    <p class="text-xs text-gray-500"><%= notification.get("created_at") %></p>
                                                </div>
                                            </div>
                                        </li>
                                    <% } %>
                                </ul>
                            <% } %>
                        </div>
                    </div>
                    
                    <!-- Monthly Trend -->
                    <div class="bg-white shadow rounded-lg">
                        <div class="px-6 py-4 border-b">
                            <h3 class="text-lg font-medium text-gray-900">Monthly Trend</h3>
                        </div>
                        <div class="p-6">
                            <div class="chart-container">
                                <canvas id="monthlyChart"></canvas>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    </div>
    
    <!-- Notification View Modal -->
    <div id="notification-modal" class="fixed inset-0 z-50 hidden overflow-y-auto">
        <div class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
            <div class="fixed inset-0 transition-opacity" aria-hidden="true">
                <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
            </div>
            <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>
            <div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
                <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                    <div class="sm:flex sm:items-start">
                        <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left w-full">
                            <h3 class="text-lg leading-6 font-medium text-gray-900" id="modal-title"></h3>
                            <div class="mt-4">
                                <p class="text-sm text-gray-500" id="modal-message"></p>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                    <button type="button" id="close-modal" class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm">
                        Close
                    </button>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Toggle sidebar on mobile
        document.getElementById('sidebar-toggle').addEventListener('click', function() {
            document.getElementById('sidebar').classList.toggle('open');
        });
        
        // Select all notifications
        document.getElementById('select-all').addEventListener('change', function() {
            const checkboxes = document.querySelectorAll('.notification-checkbox');
            checkboxes.forEach(checkbox => {
                checkbox.checked = this.checked;
            });
        });
        
        // Mark as read button
        document.getElementById('mark-read-btn').addEventListener('click', function() {
            const form = document.getElementById('notifications-form');
            const action = document.getElementById('notification-action');
            
            // Check if any notifications are selected
            const selectedNotifications = document.querySelectorAll('.notification-checkbox:checked');
            if (selectedNotifications.length === 0) {
                alert('Please select at least one notification');
                return;
            }
            
            action.value = 'mark_read';
            form.submit();
        });
        
        // Delete button
        document.getElementById('delete-btn').addEventListener('click', function() {
            const form = document.getElementById('notifications-form');
            const action = document.getElementById('notification-action');
            
            // Check if any notifications are selected
            const selectedNotifications = document.querySelectorAll('.notification-checkbox:checked');
            if (selectedNotifications.length === 0) {
                alert('Please select at least one notification');
                return;
            }
            
            if (confirm('Are you sure you want to delete the selected notifications?')) {
                action.value = 'delete';
                form.submit();
            }
        });
        
        // Show/hide recipients based on notification type
        document.getElementById('type').addEventListener('change', function() {
            const recipientsContainer = document.getElementById('recipients-container');
            if (this.value === 'user') {
                recipientsContainer.style.display = 'block';
            } else {
                recipientsContainer.style.display = 'none';
            }
        });
        
        // View notification modal
        const viewButtons = document.querySelectorAll('.view-notification');
        const modal = document.getElementById('notification-modal');
        const modalTitle = document.getElementById('modal-title');
        const modalMessage = document.getElementById('modal-message');
        const closeModal = document.getElementById('close-modal');
        
        viewButtons.forEach(button => {
            button.addEventListener('click', function() {
                const id = this.getAttribute('data-id');
                const title = this.getAttribute('data-title');
                const message = this.getAttribute('data-message');
                
                modalTitle.textContent = title;
                modalMessage.textContent = message;
                modal.classList.remove('hidden');
            });
        });
        
        closeModal.addEventListener('click', function() {
            modal.classList.add('hidden');
        });
        
        // Close modal when clicking outside
        window.addEventListener('click', function(event) {
            if (event.target === modal) {
                modal.classList.add('hidden');
            }
        });
        
        // Charts
        const monthlyCtx = document.getElementById('monthlyChart').getContext('2d');
        const monthlyChart = new Chart(monthlyCtx, {
            type: 'line',
            data: {
                labels: <%= Arrays.toString(months.toArray()) %>,
                datasets: [{
                    label: 'Notifications',
                    data: <%= monthlyNotificationsJson.toString() %>,
                    backgroundColor: 'rgba(59, 130, 246, 0.2)',
                    borderColor: 'rgba(59, 130, 246, 1)',
                    borderWidth: 2,
                    tension: 0.3,
                    pointBackgroundColor: 'rgba(59, 130, 246, 1)',
                    pointRadius: 4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            precision: 0
                        }
                    }
                },
                plugins: {
                    legend: {
                        display: false
                    }
                }
            }
        });
    </script>
</body>
</html>