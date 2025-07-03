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
    List<Map<String, Object>> supportTicketsList = new ArrayList<>();
    List<Map<String, Object>> ticketsByStatusList = new ArrayList<>();
    List<Map<String, Object>> ticketsByPriorityList = new ArrayList<>();
    List<Map<String, Object>> recentTicketsList = new ArrayList<>();
    
    // Statistics
    int totalTickets = 0;
    int openTickets = 0;
    int resolvedTickets = 0;
    int pendingTickets = 0;
    
    // Monthly data for charts
    List<Integer> monthlyTickets = new ArrayList<>(Arrays.asList(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));
    List<Integer> monthlyResolvedTickets = new ArrayList<>(Arrays.asList(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));
    List<String> months = Arrays.asList("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
    
    // Get current month and year
    Calendar cal = Calendar.getInstance();
    int currentMonth = cal.get(Calendar.MONTH);
    int currentYear = cal.get(Calendar.YEAR);
    
    // Variables for messages
    String successMessage = "";
    String errorMessage = "";
    
    // Process form submissions
    if (request.getMethod().equals("POST")) {
        String action = request.getParameter("action");
        
        try {
            // Establish database connection
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(url, username, password);
            
            if ("submit_ticket".equals(action)) {
                // Create a new support ticket
                String subject = request.getParameter("subject");
                String message = request.getParameter("message");
                String priority = request.getParameter("priority");
                int userId = Integer.parseInt(request.getParameter("user_id"));
                
                String insertQuery = "INSERT INTO support_tickets (user_id, subject, message, priority, status, created_at) VALUES (?, ?, ?, ?, 'open', NOW())";
                pstmt = conn.prepareStatement(insertQuery);
                pstmt.setInt(1, userId);
                pstmt.setString(2, subject);
                pstmt.setString(3, message);
                pstmt.setString(4, priority);
                
                int result = pstmt.executeUpdate();
                if (result > 0) {
                    successMessage = "Your support ticket has been submitted successfully.";
                } else {
                    errorMessage = "Failed to submit your support ticket. Please try again.";
                }
                
                pstmt.close();
            } else if ("update_ticket".equals(action)) {
                // Update an existing ticket
                int ticketId = Integer.parseInt(request.getParameter("ticket_id"));
                String status = request.getParameter("status");
                String response = request.getParameter("response");
                
                String updateQuery = "UPDATE support_tickets SET status = ?, admin_response = ?, updated_at = NOW() ";
                
                if ("resolved".equals(status)) {
                    updateQuery += ", resolved_at = NOW() ";
                }
                
                updateQuery += "WHERE id = ?";
                
                pstmt = conn.prepareStatement(updateQuery);
                pstmt.setString(1, status);
                pstmt.setString(2, response);
                pstmt.setInt(3, ticketId);
                
                int result = pstmt.executeUpdate();
                if (result > 0) {
                    successMessage = "Ticket has been updated successfully.";
                } else {
                    errorMessage = "Failed to update the ticket. Please try again.";
                }
                
                pstmt.close();
            }
        } catch (Exception e) {
            errorMessage = "Error: " + e.getMessage();
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
        
        // Get overall statistics
        String statsQuery = "SELECT " +
                           "COUNT(*) as total_tickets, " +
                           "SUM(CASE WHEN status = 'open' THEN 1 ELSE 0 END) as open_tickets, " +
                           "SUM(CASE WHEN status = 'resolved' THEN 1 ELSE 0 END) as resolved_tickets, " +
                           "SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_tickets " +
                           "FROM support_tickets";
        
        pstmt = conn.prepareStatement(statsQuery);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            totalTickets = rs.getInt("total_tickets");
            openTickets = rs.getInt("open_tickets");
            resolvedTickets = rs.getInt("resolved_tickets");
            pendingTickets = rs.getInt("pending_tickets");
        }
        
        rs.close();
        pstmt.close();
        
        // Get tickets by status
        String ticketsByStatusQuery = "SELECT status, COUNT(*) as count " +
                                     "FROM support_tickets " +
                                     "GROUP BY status";
        
        pstmt = conn.prepareStatement(ticketsByStatusQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> statusData = new HashMap<>();
            statusData.put("status", rs.getString("status"));
            statusData.put("count", rs.getInt("count"));
            
            ticketsByStatusList.add(statusData);
        }
        
        rs.close();
        pstmt.close();
        
        // Get tickets by priority
        String ticketsByPriorityQuery = "SELECT priority, COUNT(*) as count " +
                                       "FROM support_tickets " +
                                       "GROUP BY priority";
        
        pstmt = conn.prepareStatement(ticketsByPriorityQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> priorityData = new HashMap<>();
            priorityData.put("priority", rs.getString("priority"));
            priorityData.put("count", rs.getInt("count"));
            
            ticketsByPriorityList.add(priorityData);
        }
        
        rs.close();
        pstmt.close();
        
        // Get all support tickets
        String ticketsQuery = "SELECT st.id, st.subject, st.message, st.priority, st.status, " +
                             "st.created_at, st.updated_at, st.resolved_at, st.admin_response, " +
                             "u.first_name, u.last_name, u.email " +
                             "FROM support_tickets st " +
                             "JOIN users u ON st.user_id = u.id " +
                             "ORDER BY st.created_at DESC";
        
        pstmt = conn.prepareStatement(ticketsQuery);
        rs = pstmt.executeQuery();
        
        SimpleDateFormat dateFormat = new SimpleDateFormat("MMM d, yyyy 'at' h:mm a");
        
        while (rs.next()) {
            Map<String, Object> ticket = new HashMap<>();
            ticket.put("id", rs.getInt("id"));
            ticket.put("subject", rs.getString("subject"));
            ticket.put("message", rs.getString("message"));
            ticket.put("priority", rs.getString("priority"));
            ticket.put("status", rs.getString("status"));
            ticket.put("created_at", dateFormat.format(rs.getTimestamp("created_at")));
            
            Timestamp updatedAt = rs.getTimestamp("updated_at");
            if (updatedAt != null) {
                ticket.put("updated_at", dateFormat.format(updatedAt));
            } else {
                ticket.put("updated_at", "N/A");
            }
            
            Timestamp resolvedAt = rs.getTimestamp("resolved_at");
            if (resolvedAt != null) {
                ticket.put("resolved_at", dateFormat.format(resolvedAt));
            } else {
                ticket.put("resolved_at", "N/A");
            }
            
            ticket.put("admin_response", rs.getString("admin_response"));
            ticket.put("user_name", rs.getString("first_name") + " " + rs.getString("last_name"));
            ticket.put("user_email", rs.getString("email"));
            
            supportTicketsList.add(ticket);
            
            // Add to recent tickets list (limited to 5)
            if (recentTicketsList.size() < 5) {
                recentTicketsList.add(ticket);
            }
        }
        
        rs.close();
        pstmt.close();
        
        // Get monthly tickets data for the current year
        String monthlyDataQuery = "SELECT MONTH(created_at) as month, " +
                                 "COUNT(*) as ticket_count " +
                                 "FROM support_tickets " +
                                 "WHERE YEAR(created_at) = ? " +
                                 "GROUP BY MONTH(created_at) " +
                                 "ORDER BY month";
        
        pstmt = conn.prepareStatement(monthlyDataQuery);
        pstmt.setInt(1, currentYear);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            int month = rs.getInt("month") - 1; // 0-based index
            int ticketCount = rs.getInt("ticket_count");
            monthlyTickets.set(month, ticketCount);
        }
        
        rs.close();
        pstmt.close();
        
        // Get monthly resolved tickets data for the current year
        String monthlyResolvedQuery = "SELECT MONTH(resolved_at) as month, " +
                                     "COUNT(*) as resolved_count " +
                                     "FROM support_tickets " +
                                     "WHERE YEAR(resolved_at) = ? " +
                                     "AND status = 'resolved' " +
                                     "GROUP BY MONTH(resolved_at) " +
                                     "ORDER BY month";
        
        pstmt = conn.prepareStatement(monthlyResolvedQuery);
        pstmt.setInt(1, currentYear);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            int month = rs.getInt("month") - 1; // 0-based index
            int resolvedCount = rs.getInt("resolved_count");
            monthlyResolvedTickets.set(month, resolvedCount);
        }
        
    } catch (Exception e) {
        errorMessage = "Error retrieving data: " + e.getMessage();
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
    StringBuilder monthlyTicketsJson = new StringBuilder("[");
    for (Integer count : monthlyTickets) {
        monthlyTicketsJson.append(count).append(",");
    }
    if (monthlyTicketsJson.charAt(monthlyTicketsJson.length() - 1) == ',') {
        monthlyTicketsJson.setLength(monthlyTicketsJson.length() - 1);
    }
    monthlyTicketsJson.append("]");
    
    StringBuilder monthlyResolvedJson = new StringBuilder("[");
    for (Integer count : monthlyResolvedTickets) {
        monthlyResolvedJson.append(count).append(",");
    }
    if (monthlyResolvedJson.charAt(monthlyResolvedJson.length() - 1) == ',') {
        monthlyResolvedJson.setLength(monthlyResolvedJson.length() - 1);
    }
    monthlyResolvedJson.append("]");
    
    // Status data for charts
    StringBuilder statusLabelsJson = new StringBuilder("[");
    StringBuilder statusCountsJson = new StringBuilder("[");
    
    for (Map<String, Object> status : ticketsByStatusList) {
        statusLabelsJson.append("\"").append(status.get("status")).append("\",");
        statusCountsJson.append(status.get("count")).append(",");
    }
    
    if (statusLabelsJson.charAt(statusLabelsJson.length() - 1) == ',') {
        statusLabelsJson.setLength(statusLabelsJson.length() - 1);
    }
    statusLabelsJson.append("]");
    
    if (statusCountsJson.charAt(statusCountsJson.length() - 1) == ',') {
        statusCountsJson.setLength(statusCountsJson.length() - 1);
    }
    statusCountsJson.append("]");
    
    // Priority data for charts
    StringBuilder priorityLabelsJson = new StringBuilder("[");
    StringBuilder priorityCountsJson = new StringBuilder("[");
    
    for (Map<String, Object> priority : ticketsByPriorityList) {
        priorityLabelsJson.append("\"").append(priority.get("priority")).append("\",");
        priorityCountsJson.append(priority.get("count")).append(",");
    }
    
    if (priorityLabelsJson.charAt(priorityLabelsJson.length() - 1) == ',') {
        priorityLabelsJson.setLength(priorityLabelsJson.length() - 1);
    }
    priorityLabelsJson.append("]");
    
    if (priorityCountsJson.charAt(priorityCountsJson.length() - 1) == ',') {
        priorityCountsJson.setLength(priorityCountsJson.length() - 1);
    }
    priorityCountsJson.append("]");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZAIRTAM - Contact Support</title>
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
                        <input type="text" placeholder="Search for support tickets..." class="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
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
                    <h3 class="text-xs uppercase text-gray-500 font-semibold tracking-wider">Support</h3>
                    <ul class="mt-3 space-y-1">
                        <li>
                            <a href="Help-Center.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-question-circle w-5 text-center"></i>
                                <span class="ml-2">Help Center</span>
                            </a>
                        </li>
                        <li>
                            <a href="Contact-Support.jsp" class="flex items-center px-3 py-2 text-blue-600 bg-blue-50 rounded-md">
                                <i class="fas fa-headset w-5 text-center"></i>
                                <span class="ml-2">Contact Support</span>
                            </a>
                        </li>
                    </ul>
                </div>
                
                <div class="mb-6">
                    <h3 class="text-xs uppercase text-gray-500 font-semibold tracking-wider">Settings</h3>
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
            </div>
        </aside>

        <!-- Main Content -->
        <main class="flex-1 p-6">
            <div class="max-w-7xl mx-auto">
                <!-- Page Header -->
                <div class="flex flex-col md:flex-row md:items-center md:justify-between mb-8">
                    <div>
                        <h1 class="text-2xl font-bold text-gray-900">Contact Support</h1>
                        <p class="mt-1 text-sm text-gray-600">Manage support tickets and customer inquiries</p>
                    </div>
                    <div class="mt-4 md:mt-0">
                        <button data-modal-target="create-ticket-modal" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg flex items-center">
                            <i class="fas fa-plus mr-2"></i>
                            <span>Create New Ticket</span>
                        </button>
                    </div>
                </div>
                
                <!-- Success/Error Messages -->
                <% if (!successMessage.isEmpty()) { %>
                <div class="bg-green-100 border-l-4 border-green-500 text-green-700 p-4 mb-6 rounded" role="alert">
                    <p><i class="fas fa-check-circle mr-2"></i> <%= successMessage %></p>
                </div>
                <% } %>
                
                <% if (!errorMessage.isEmpty()) { %>
                <div class="bg-red-100 border-l-4 border-red-500 text-red-700 p-4 mb-6 rounded" role="alert">
                    <p><i class="fas fa-exclamation-circle mr-2"></i> <%= errorMessage %></p>
                </div>
                <% } %>
                
                <!-- Stats Cards -->
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                    <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                        <div class="flex items-center">
                            <div class="bg-blue-100 p-3 rounded-full">
                                <i class="fas fa-ticket-alt text-blue-600 text-xl"></i>
                            </div>
                            <div class="ml-4">
                                <h3 class="text-sm font-medium text-gray-500">Total Tickets</h3>
                                <p class="text-2xl font-semibold text-gray-800"><%= totalTickets %></p>
                            </div>
                        </div>
                    </div>
                    
                    <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                        <div class="flex items-center">
                            <div class="bg-green-100 p-3 rounded-full">
                                <i class="fas fa-check-circle text-green-600 text-xl"></i>
                            </div>
                            <div class="ml-4">
                                <h3 class="text-sm font-medium text-gray-500">Resolved Tickets</h3>
                                <p class="text-2xl font-semibold text-gray-800"><%= resolvedTickets %></p>
                            </div>
                        </div>
                    </div>
                    
                    <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                        <div class="flex items-center">
                            <div class="bg-yellow-100 p-3 rounded-full">
                                <i class="fas fa-clock text-yellow-600 text-xl"></i>
                            </div>
                            <div class="ml-4">
                                <h3 class="text-sm font-medium text-gray-500">Pending Tickets</h3>
                                <p class="text-2xl font-semibold text-gray-800"><%= pendingTickets %></p>
                            </div>
                        </div>
                    </div>
                    
                    <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                        <div class="flex items-center">
                            <div class="bg-red-100 p-3 rounded-full">
                                <i class="fas fa-exclamation-circle text-red-600 text-xl"></i>
                            </div>
                            <div class="ml-4">
                                <h3 class="text-sm font-medium text-gray-500">Open Tickets</h3>
                                <p class="text-2xl font-semibold text-gray-800"><%= openTickets %></p>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Charts Section -->
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
                    <!-- Monthly Tickets Chart -->
                    <div class="bg-white rounded-lg shadow-sm p-6">
                        <h3 class="text-lg font-semibold text-gray-800 mb-4">Monthly Tickets</h3>
                        <div class="chart-container">
                            <canvas id="monthlyTicketsChart"></canvas>
                        </div>
                    </div>
                    
                    <!-- Tickets by Status Chart -->
                    <div class="bg-white rounded-lg shadow-sm p-6">
                        <h3 class="text-lg font-semibold text-gray-800 mb-4">Tickets by Status</h3>
                        <div class="chart-container">
                            <canvas id="ticketsByStatusChart"></canvas>
                        </div>
                    </div>
                </div>
                
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
                    <!-- Tickets by Priority Chart -->
                    <div class="bg-white rounded-lg shadow-sm p-6">
                        <h3 class="text-lg font-semibold text-gray-800 mb-4">Tickets by Priority</h3>
                        <div class="chart-container">
                            <canvas id="priorityChart"></canvas>
                        </div>
                    </div>
                    
                    <!-- Tickets by Status Chart -->
                    <div class="bg-white rounded-lg shadow-sm p-6">
                        <h3 class="text-lg font-semibold text-gray-800 mb-4">Tickets by Status</h3>
                        <div class="chart-container">
                            <canvas id="statusChart"></canvas>
                        </div>
                    </div>
                </div>
                
                <!-- Recent Support Tickets -->
                <div class="bg-white rounded-lg shadow-sm p-6 mb-8">
                    <div class="flex justify-between items-center mb-6">
                        <h3 class="text-lg font-semibold text-gray-800">Recent Support Tickets</h3>
                        <a href="#all-tickets" class="text-blue-600 hover:text-blue-800 text-sm font-medium">View All</a>
                    </div>
                    
                    <div class="overflow-x-auto">
                        <table class="min-w-full divide-y divide-gray-200">
                            <thead class="bg-gray-50">
                                <tr>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Subject</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Priority</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                                </tr>
                            </thead>
                            <tbody class="bg-white divide-y divide-gray-200">
                                <% if (recentTicketsList.isEmpty()) { %>
                                    <tr>
                                        <td colspan="7" class="px-6 py-4 text-center text-sm text-gray-500">No recent tickets found</td>
                                    </tr>
                                <% } else { 
                                    for (Map<String, Object> ticket : recentTicketsList) { 
                                        String priorityClass = "";
                                        if ("high".equals(ticket.get("priority"))) {
                                            priorityClass = "bg-red-100 text-red-800";
                                        } else if ("medium".equals(ticket.get("priority"))) {
                                            priorityClass = "bg-yellow-100 text-yellow-800";
                                        } else {
                                            priorityClass = "bg-blue-100 text-blue-800";
                                        }
                                        
                                        String statusClass = "";
                                        if ("open".equals(ticket.get("status"))) {
                                            statusClass = "bg-blue-100 text-blue-800";
                                        } else if ("pending".equals(ticket.get("status"))) {
                                            statusClass = "bg-yellow-100 text-yellow-800";
                                        } else {
                                            statusClass = "bg-green-100 text-green-800";
                                        }
                                %>
                                <tr>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">#<%= ticket.get("id") %></td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"><%= ticket.get("subject") %></td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                        <div class="flex items-center">
                                            <div class="flex-shrink-0 h-8 w-8">
                                                <img class="h-8 w-8 rounded-full" src="https://ui-avatars.com/api/?name=<%= ticket.get("user_name") %>&background=random" alt="">
                                            </div>
                                            <div class="ml-3">
                                                <div class="text-sm font-medium text-gray-900"><%= ticket.get("user_name") %></div>
                                                <div class="text-xs text-gray-500"><%= ticket.get("user_email") %></div>
                                            </div>
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full <%= priorityClass %>">
                                            <%= ticket.get("priority") %>
                                        </span>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full <%= statusClass %>">
                                            <%= ticket.get("status") %>
                                        </span>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"><%= ticket.get("created_at") %></td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                        <a href="#" data-modal-target="view-ticket-<%= ticket.get("id") %>-modal" class="text-blue-600 hover:text-blue-900 mr-3">View</a>
                                        <a href="#" data-modal-target="respond-ticket-<%= ticket.get("id") %>-modal" class="text-indigo-600 hover:text-indigo-900">Respond</a>
                                    </td>
                                </tr>
                                <% } 
                                } %>
                            </tbody>
                        </table>
                    </div>
                </div>
                
                <!-- All Support Tickets Section -->
                <div id="all-tickets" class="bg-white rounded-lg shadow-sm p-6 mb-8">
                    <div class="flex justify-between items-center mb-6">
                        <h3 class="text-lg font-semibold text-gray-800">All Support Tickets</h3>
                        <div class="flex space-x-2">
                            <select id="status-filter" class="border rounded-md px-3 py-1 text-sm">
                                <option value="all">All Status</option>
                                <option value="open">Open</option>
                                <option value="pending">Pending</option>
                                <option value="resolved">Resolved</option>
                            </select>
                            <select id="priority-filter" class="border rounded-md px-3 py-1 text-sm">
                                <option value="all">All Priorities</option>
                                <option value="low">Low</option>
                                <option value="medium">Medium</option>
                                <option value="high">High</option>
                            </select>
                        </div>
                    </div>
                    
                    <div class="overflow-x-auto">
                        <table class="min-w-full divide-y divide-gray-200">
                            <thead class="bg-gray-50">
                                <tr>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Subject</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Priority</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Updated</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                                </tr>
                            </thead>
                            <tbody class="bg-white divide-y divide-gray-200">
                                <% if (supportTicketsList.isEmpty()) { %>
                                    <tr>
                                        <td colspan="8" class="px-6 py-4 text-center text-sm text-gray-500">No tickets found</td>
                                    </tr>
                                <% } else { 
                                    for (Map<String, Object> ticket : supportTicketsList) { 
                                        String priorityClass = "";
                                        if ("high".equals(ticket.get("priority"))) {
                                            priorityClass = "bg-red-100 text-red-800";
                                        } else if ("medium".equals(ticket.get("priority"))) {
                                            priorityClass = "bg-yellow-100 text-yellow-800";
                                        } else {
                                            priorityClass = "bg-blue-100 text-blue-800";
                                        }
                                        
                                        String statusClass = "";
                                        if ("open".equals(ticket.get("status"))) {
                                            statusClass = "bg-blue-100 text-blue-800";
                                        } else if ("pending".equals(ticket.get("status"))) {
                                            statusClass = "bg-yellow-100 text-yellow-800";
                                        } else {
                                            statusClass = "bg-green-100 text-green-800";
                                        }
                                %>
                                <tr class="ticket-row" data-priority="<%= ticket.get("priority") %>" data-status="<%= ticket.get("status") %>">
                                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">#<%= ticket.get("id") %></td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"><%= ticket.get("subject") %></td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                        <div class="flex items-center">
                                            <div class="flex-shrink-0 h-8 w-8">
                                                <img class="h-8 w-8 rounded-full" src="https://ui-avatars.com/api/?name=<%= ticket.get("user_name") %>&background=random" alt="">
                                            </div>
                                            <div class="ml-3">
                                                <div class="text-sm font-medium text-gray-900"><%= ticket.get("user_name") %></div>
                                                <div class="text-xs text-gray-500"><%= ticket.get("user_email") %></div>
                                            </div>
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full <%= priorityClass %>">
                                            <%= ticket.get("priority") %>
                                        </span>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full <%= statusClass %>">
                                            <%= ticket.get("status") %>
                                        </span>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"><%= ticket.get("created_at") %></td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"><%= ticket.get("updated_at") %></td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                        <a href="#" data-modal-target="view-ticket-<%= ticket.get("id") %>-modal" class="text-blue-600 hover:text-blue-900 mr-3">View</a>
                                        <a href="#" data-modal-target="respond-ticket-<%= ticket.get("id") %>-modal" class="text-indigo-600 hover:text-indigo-900">Respond</a>
                                    </td>
                                </tr>
                                <% } 
                                } %>
                            </tbody>
                        </table>
                    </div>
                </div>
                
                <!-- Create New Ticket -->
                <div class="bg-white rounded-lg shadow-sm p-6 mb-8">
                    <h3 class="text-lg font-semibold text-gray-800 mb-4">Create New Support Ticket</h3>
                    
                    <form id="create-ticket-form" action="Contact-Support.jsp" method="post" class="space-y-4">
                        <input type="hidden" name="action" value="submit_ticket">
                        <input type="hidden" name="user_id" value="1"> <!-- Replace with actual user ID -->
                        
                        <div>
                            <label for="subject" class="block text-sm font-medium text-gray-700 mb-1">Subject</label>
                            <input type="text" id="subject" name="subject" required class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                        </div>
                        
                        <div>
                            <label for="message" class="block text-sm font-medium text-gray-700 mb-1">Message</label>
                            <textarea id="message" name="message" rows="4" required class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"></textarea>
                        </div>
                        
                        <div>
                            <label for="priority" class="block text-sm font-medium text-gray-700 mb-1">Priority</label>
                            <select id="priority" name="priority" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                                <option value="low">Low</option>
                                <option value="medium">Medium</option>
                                <option value="high">High</option>
                            </select>
                        </div>
                        
                        <div>
                            <button type="submit" class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
                                Submit Ticket
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </main>
    </div>
    
    <!-- Modals for viewing and responding to tickets -->
    <% for (Map<String, Object> ticket : supportTicketsList) { %>
        <!-- View Ticket Modal -->
        <div id="view-ticket-<%= ticket.get("id") %>-modal" class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50 hidden">
            <div class="bg-white rounded-lg max-w-2xl w-full mx-4 overflow-hidden">
                <div class="px-6 py-4 bg-gray-50 border-b flex justify-between items-center">
                    <h3 class="text-lg font-semibold text-gray-800">Ticket #<%= ticket.get("id") %></h3>
                    <button class="modal-close text-gray-500 hover:text-gray-700">
                        <i class="fas fa-times"></i>
                    </button>
                </div>
                <div class="p-6">
                    <div class="mb-4">
                        <h4 class="text-md font-medium text-gray-700">Subject</h4>
                        <p class="text-gray-900"><%= ticket.get("subject") %></p>
                    </div>
                    <div class="mb-4">
                        <h4 class="text-md font-medium text-gray-700">Message</h4>
                        <p class="text-gray-900 whitespace-pre-line"><%= ticket.get("message") %></p>
                    </div>
                    <div class="grid grid-cols-2 gap-4 mb-4">
                        <div>
                            <h4 class="text-md font-medium text-gray-700">Priority</h4>
                            <p class="text-gray-900"><%= ticket.get("priority") %></p>
                        </div>
                        <div>
                            <h4 class="text-md font-medium text-gray-700">Status</h4>
                            <p class="text-gray-900"><%= ticket.get("status") %></p>
                        </div>
                        <div>
                            <h4 class="text-md font-medium text-gray-700">Created</h4>
                            <p class="text-gray-900"><%= ticket.get("created_at") %></p>
                        </div>
                        <div>
                            <h4 class="text-md font-medium text-gray-700">Last Updated</h4>
                            <p class="text-gray-900"><%= ticket.get("updated_at") %></p>
                        </div>
                    </div>
                    <% if (ticket.get("admin_response") != null && !ticket.get("admin_response").toString().isEmpty()) { %>
                        <div class="mb-4 p-4 bg-gray-50 rounded-lg">
                            <h4 class="text-md font-medium text-gray-700 mb-2">Admin Response</h4>
                            <p class="text-gray-900 whitespace-pre-line"><%= ticket.get("admin_response") %></p>
                        </div>
                    <% } %>
                    <div class="mt-6 flex justify-end">
                        <button class="modal-close px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200 mr-2">Close</button>
                        <a href="#" data-modal-target="respond-ticket-<%= ticket.get("id") %>-modal" class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700">Respond</a>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Respond to Ticket Modal -->
        <div id="respond-ticket-<%= ticket.get("id") %>-modal" class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50 hidden">
            <div class="bg-white rounded-lg max-w-2xl w-full mx-4 overflow-hidden">
                <div class="px-6 py-4 bg-gray-50 border-b flex justify-between items-center">
                    <h3 class="text-lg font-semibold text-gray-800">Respond to Ticket #<%= ticket.get("id") %></h3>
                    <button class="modal-close text-gray-500 hover:text-gray-700">
                        <i class="fas fa-times"></i>
                    </button>
                </div>
                <div class="p-6">
                    <form action="Contact-Support.jsp" method="post">
                        <input type="hidden" name="action" value="update_ticket">
                        <input type="hidden" name="ticket_id" value="<%= ticket.get("id") %>">
                        
                        <div class="mb-4">
                            <label for="response-<%= ticket.get("id") %>" class="block text-sm font-medium text-gray-700 mb-1">Your Response</label>
                            <textarea id="response-<%= ticket.get("id") %>" name="response" rows="4" required class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"><%= ticket.get("admin_response") != null ? ticket.get("admin_response") : "" %></textarea>
                        </div>
                        
                        <div class="mb-4">
                            <label for="status-<%= ticket.get("id") %>" class="block text-sm font-medium text-gray-700 mb-1">Update Status</label>
                            <select id="status-<%= ticket.get("id") %>" name="status" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                                <option value="open" <%= "open".equals(ticket.get("status")) ? "selected" : "" %>>Open</option>
                                <option value="pending" <%= "pending".equals(ticket.get("status")) ? "selected" : "" %>>Pending</option>
                                <option value="resolved" <%= "resolved".equals(ticket.get("status")) ? "selected" : "" %>>Resolved</option>
                            </select>
                        </div>
                        
                        <div class="mt-6 flex justify-end">
                            <button type="button" class="modal-close px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200 mr-2">Cancel</button>
                            <button type="submit" class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700">Submit Response</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    <% } %>
    
    <!-- Success/Error Messages -->
    <% if (!successMessage.isEmpty() || !errorMessage.isEmpty()) { %>
        <div id="notification" class="fixed bottom-4 right-4 max-w-md p-4 rounded-lg shadow-lg <%= !errorMessage.isEmpty() ? "bg-red-100 border-l-4 border-red-500" : "bg-green-100 border-l-4 border-green-500" %> z-50">
            <div class="flex">
                <div class="flex-shrink-0">
                    <% if (!errorMessage.isEmpty()) { %>
                        <i class="fas fa-exclamation-circle text-red-500"></i>
                    <% } else { %>
                        <i class="fas fa-check-circle text-green-500"></i>
                    <% } %>
                </div>
                <div class="ml-3">
                    <p class="text-sm font-medium <%= !errorMessage.isEmpty() ? "text-red-800" : "text-green-800" %>">
                        <%= !errorMessage.isEmpty() ? errorMessage : successMessage %>
                    </p>
                </div>
                <div class="ml-auto pl-3">
                    <div class="-mx-1.5 -my-1.5">
                        <button id="close-notification" class="inline-flex rounded-md p-1.5 <%= !errorMessage.isEmpty() ? "text-red-500 hover:bg-red-200" : "text-green-500 hover:bg-green-200" %> focus:outline-none">
                            <i class="fas fa-times"></i>
                        </button>
                    </div>
                </div>
            </div>
        </div>
    <% } %>
    
    <script>
        // Toggle sidebar on mobile
        document.getElementById('sidebar-toggle').addEventListener('click', function() {
            document.getElementById('sidebar').classList.toggle('open');
        });
        
        // Modal functionality
        document.addEventListener('DOMContentLoaded', function() {
            // Open modals
            const modalTriggers = document.querySelectorAll('[data-modal-target]');
            modalTriggers.forEach(trigger => {
                trigger.addEventListener('click', function(e) {
                    e.preventDefault();
                    const modalId = this.getAttribute('data-modal-target');
                    document.getElementById(modalId).classList.remove('hidden');
                });
            });
            
            // Close modals
            const closeButtons = document.querySelectorAll('.modal-close');
            closeButtons.forEach(button => {
                button.addEventListener('click', function() {
                    const modal = this.closest('[id$="-modal"]');
                    modal.classList.add('hidden');
                });
            });
            
            // Close modals when clicking outside
            window.addEventListener('click', function(event) {
                document.querySelectorAll('[id$="-modal"]').forEach(modal => {
                    if (event.target === modal) {
                        modal.classList.add('hidden');
                    }
                });
            });
            
            // Close notification
            const notification = document.getElementById('notification');
            const closeNotification = document.getElementById('close-notification');
            
            if (notification && closeNotification) {
                closeNotification.addEventListener('click', function() {
                    notification.classList.add('hidden');
                });
                
                // Auto-hide notification after 5 seconds
                setTimeout(function() {
                    notification.classList.add('hidden');
                }, 5000);
            }
            
            // Ticket filtering
            const statusFilter = document.getElementById('status-filter');
            const priorityFilter = document.getElementById('priority-filter');
            const ticketRows = document.querySelectorAll('.ticket-row');
            
            function filterTickets() {
                const statusValue = statusFilter.value;
                const priorityValue = priorityFilter.value;
                
                ticketRows.forEach(row => {
                    const rowStatus = row.getAttribute('data-status');
                    const rowPriority = row.getAttribute('data-priority');
                    
                    const statusMatch = statusValue === 'all' || statusValue === rowStatus;
                    const priorityMatch = priorityValue === 'all' || priorityValue === rowPriority;
                    
                    if (statusMatch && priorityMatch) {
                        row.classList.remove('hidden');
                    } else {
                        row.classList.add('hidden');
                    }
                });
            }
            
            if (statusFilter && priorityFilter) {
                statusFilter.addEventListener('change', filterTickets);
                priorityFilter.addEventListener('change', filterTickets);
            }
        });
        
        // Charts
        const priorityCtx = document.getElementById('priorityChart').getContext('2d');
        const priorityChart = new Chart(priorityCtx, {
            type: 'doughnut',
            data: {
                labels: <%= priorityLabelsJson.toString() %>,
                datasets: [{
                    data: <%= priorityCountsJson.toString() %>,
                    backgroundColor: [
                        'rgba(239, 68, 68, 0.8)',
                        'rgba(245, 158, 11, 0.8)',
                        'rgba(59, 130, 246, 0.8)'
                    ],
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'right',
                        labels: {
                            boxWidth: 15,
                            padding: 15
                        }
                    }
                }
            }
        });
        
        const statusCtx = document.getElementById('statusChart').getContext('2d');
        const statusChart = new Chart(statusCtx, {
            type: 'doughnut',
            data: {
                labels: <%= statusLabelsJson.toString() %>,
                datasets: [{
                    data: <%= statusCountsJson.toString() %>,
                    backgroundColor: [
                        'rgba(59, 130, 246, 0.8)',
                        'rgba(245, 158, 11, 0.8)',
                        'rgba(16, 185, 129, 0.8)'
                    ],
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'right',
                        labels: {
                            boxWidth: 15,
                            padding: 15
                        }
                    }
                }
            }
        });
        
        const monthlyCtx = document.getElementById('monthlyChart').getContext('2d');
        const monthlyChart = new Chart(monthlyCtx, {
            type: 'line',
            data: {
                labels: <%= Arrays.toString(months.toArray()) %>,
                datasets: [
                    {
                        label: 'Tickets Created',
                        data: <%= monthlyTicketsJson.toString() %>,
                        backgroundColor: 'rgba(59, 130, 246, 0.2)',
                        borderColor: 'rgba(59, 130, 246, 1)',
                        borderWidth: 2,
                        tension: 0.3,
                        pointBackgroundColor: 'rgba(59, 130, 246, 1)',
                        pointRadius: 4
                    },
                    {
                        label: 'Tickets Resolved',
                        data: <%= monthlyResolvedJson.toString() %>,
                        backgroundColor: 'rgba(16, 185, 129, 0.2)',
                        borderColor: 'rgba(16, 185, 129, 1)',
                        borderWidth: 2,
                        tension: 0.3,
                        pointBackgroundColor: 'rgba(16, 185, 129, 1)',
                        pointRadius: 4
                    }
                ]
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
                }
            }
        });
        
        // Status distribution chart
        const statusCtx = document.getElementById('statusChart').getContext('2d');
        const statusChart = new Chart(statusCtx, {
            type: 'doughnut',
            data: {
                labels: <%= statusLabelsJson.toString() %>,
                datasets: [{
                    data: <%= statusCountsJson.toString() %>,
                    backgroundColor: [
                        'rgba(59, 130, 246, 0.8)',  // Blue for open
                        'rgba(245, 158, 11, 0.8)',  // Amber for pending
                        'rgba(16, 185, 129, 0.8)'   // Green for resolved
                    ],
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'right',
                        labels: {
                            boxWidth: 15,
                            padding: 15
                        }
                    }
                }
            }
        });
        
        // Priority distribution chart
        const priorityCtx = document.getElementById('priorityChart').getContext('2d');
        const priorityChart = new Chart(priorityCtx, {
            type: 'pie',
            data: {
                labels: <%= priorityLabelsJson.toString() %>,
                datasets: [{
                    data: <%= priorityCountsJson.toString() %>,
                    backgroundColor: [
                        'rgba(239, 68, 68, 0.8)',   // Red for high
                        'rgba(245, 158, 11, 0.8)',  // Amber for medium
                        'rgba(59, 130, 246, 0.8)'   // Blue for low
                    ],
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'right',
                        labels: {
                            boxWidth: 15,
                            padding: 15
                        }
                    }
                }
            }
        });
        
        // Form validation
        const ticketForm = document.getElementById('create-ticket-form');
        if (ticketForm) {
            ticketForm.addEventListener('submit', function(e) {
                const subject = document.getElementById('subject').value.trim();
                const message = document.getElementById('message').value.trim();
                
                if (subject === '' || message === '') {
                    e.preventDefault();
                    alert('Please fill in all required fields.');
                }
            });
        }
        
        // Response form validation
        const responseForm = document.getElementById('response-form');
        if (responseForm) {
            responseForm.addEventListener('submit', function(e) {
                const response = document.getElementById('admin-response').value.trim();
                
                if (response === '') {
                    e.preventDefault();
                    alert('Please provide a response before submitting.');
                }
            });
        }
        
        // Modal functionality
        document.addEventListener('DOMContentLoaded', function() {
            // Open modals
            const modalTriggers = document.querySelectorAll('[data-modal-target]');
            modalTriggers.forEach(trigger => {
                trigger.addEventListener('click', function(e) {
                    e.preventDefault();
                    const modalId = this.getAttribute('data-modal-target');
                    document.getElementById(modalId).classList.remove('hidden');
                });
            });
            
            // Close modals
            const closeButtons = document.querySelectorAll('.modal-close');
            closeButtons.forEach(button => {
                button.addEventListener('click', function() {
                    const modal = this.closest('[id$="-modal"]');
                    modal.classList.add('hidden');
                });
            });
            
            // Close modals when clicking outside
            window.addEventListener('click', function(event) {
                document.querySelectorAll('[id$="-modal"]').forEach(modal => {
                    if (event.target === modal) {
                        modal.classList.add('hidden');
                    }
                });
            });
        });
    </script>
</body>
</html>