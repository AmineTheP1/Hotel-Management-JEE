<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
    // Database connection parameters
    String jdbcURL = "jdbc:mysql://localhost:3306/hotels_db";
    String dbUser = "root";
    String dbPassword = "";
    
    // Initialize connection objects
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // Employee information (would normally come from session)
    String employeeName = "Marie Dupont";
    String employeeRole = "Receptionist";
    String employeeImage = "https://randomuser.me/api/portraits/women/45.jpg";
    
    // Hotel information
    String hotelName = "ZAIRTAM Grand Hotel";
    String hotelLocation = "Paris, France";
    
    // Dashboard statistics
    int totalPayments = 0;
    double thisMonthRevenue = 0;
    double lastMonthRevenue = 0;
    int pendingPayments = 0;
    
    // Payments lists
    List<Map<String, Object>> recentPaymentsList = new ArrayList<>();
    List<Map<String, Object>> pendingPaymentsList = new ArrayList<>();
    
    // Filter parameters
    String dateFilter = request.getParameter("dateFilter");
    String statusFilter = request.getParameter("statusFilter");
    String searchQuery = request.getParameter("search");
    
    if (dateFilter == null) dateFilter = "all";
    if (statusFilter == null) statusFilter = "all";
    
    try {
        // Establish database connection
        Class.forName("com.mysql.jdbc.Driver");
        conn = DriverManager.getConnection(jdbcURL, dbUser, dbPassword);
        
        // Get today's date
        java.util.Date today = new java.util.Date();
        java.sql.Date sqlToday = new java.sql.Date(today.getTime());
        
        // Get current month and year
        Calendar cal = Calendar.getInstance();
        int currentMonth = cal.get(Calendar.MONTH) + 1;
        int currentYear = cal.get(Calendar.YEAR);
        
        // Last month
        cal.add(Calendar.MONTH, -1);
        int lastMonth = cal.get(Calendar.MONTH) + 1;
        int lastMonthYear = cal.get(Calendar.YEAR);
        
        // Query for total payments count
        String totalPaymentsQuery = "SELECT COUNT(*) FROM payments";
        pstmt = conn.prepareStatement(totalPaymentsQuery);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            totalPayments = rs.getInt(1);
        }
        
        // Query for this month's revenue
        String thisMonthQuery = "SELECT SUM(amount) FROM payments WHERE MONTH(payment_date) = ? AND YEAR(payment_date) = ?";
        pstmt = conn.prepareStatement(thisMonthQuery);
        pstmt.setInt(1, currentMonth);
        pstmt.setInt(2, currentYear);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            thisMonthRevenue = rs.getDouble(1);
            if (rs.wasNull()) {
                thisMonthRevenue = 0;
            }
        }
        
        // Query for last month's revenue
        pstmt = conn.prepareStatement(thisMonthQuery);
        pstmt.setInt(1, lastMonth);
        pstmt.setInt(2, lastMonthYear);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            lastMonthRevenue = rs.getDouble(1);
            if (rs.wasNull()) {
                lastMonthRevenue = 0;
            }
        }
        
        // Query for pending payments
        String pendingQuery = "SELECT COUNT(*) FROM payments WHERE status = 'pending'";
        pstmt = conn.prepareStatement(pendingQuery);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            pendingPayments = rs.getInt(1);
        }
        
        // Base query for payments list
        StringBuilder paymentsListQuery = new StringBuilder(
            "SELECT p.payment_id, p.booking_id, p.amount, p.payment_date, p.payment_method, p.status, " +
            "g.first_name, g.last_name, g.profile_image, g.email, g.phone, " +
            "r.room_number, r.room_type, b.check_in_date, b.check_out_date " +
            "FROM payments p " +
            "JOIN bookings b ON p.booking_id = b.booking_id " +
            "JOIN guests g ON b.guest_id = g.guest_id " +
            "JOIN rooms r ON b.room_id = r.room_id " +
            "WHERE 1=1"
        );
        
        // Apply filters
        if (!"all".equals(dateFilter)) {
            if ("today".equals(dateFilter)) {
                paymentsListQuery.append(" AND DATE(p.payment_date) = ?");
            } else if ("yesterday".equals(dateFilter)) {
                Calendar yesterdayCal = Calendar.getInstance();
                yesterdayCal.add(Calendar.DATE, -1);
                java.sql.Date sqlYesterday = new java.sql.Date(yesterdayCal.getTimeInMillis());
                paymentsListQuery.append(" AND DATE(p.payment_date) = ?");
            } else if ("thisWeek".equals(dateFilter)) {
                Calendar weekStartCal = Calendar.getInstance();
                weekStartCal.set(Calendar.DAY_OF_WEEK, weekStartCal.getFirstDayOfWeek());
                java.sql.Date weekStart = new java.sql.Date(weekStartCal.getTimeInMillis());
                paymentsListQuery.append(" AND p.payment_date BETWEEN ? AND ?");
            } else if ("thisMonth".equals(dateFilter)) {
                paymentsListQuery.append(" AND MONTH(p.payment_date) = ? AND YEAR(p.payment_date) = ?");
            }
        }
        
        if (!"all".equals(statusFilter)) {
            paymentsListQuery.append(" AND p.status = ?");
        }
        
        if (searchQuery != null && !searchQuery.trim().isEmpty()) {
            paymentsListQuery.append(" AND (g.first_name LIKE ? OR g.last_name LIKE ? OR CONCAT('BK-', b.booking_id) LIKE ? OR r.room_number LIKE ?)");
        }
        
        // Query for recent payments (last 30 days)
        String recentPaymentsQuery = paymentsListQuery.toString() + 
            " AND p.payment_date BETWEEN DATE_SUB(?, INTERVAL 30 DAY) AND ? " +
            "ORDER BY p.payment_date DESC LIMIT 50";
        
        pstmt = conn.prepareStatement(recentPaymentsQuery);
        
        int paramIndex = 1;
        
        // Set date filter parameters
        if (!"all".equals(dateFilter)) {
            if ("today".equals(dateFilter)) {
                pstmt.setDate(paramIndex++, sqlToday);
            } else if ("yesterday".equals(dateFilter)) {
                Calendar yesterdayCal = Calendar.getInstance();
                yesterdayCal.add(Calendar.DATE, -1);
                java.sql.Date sqlYesterday = new java.sql.Date(yesterdayCal.getTimeInMillis());
                pstmt.setDate(paramIndex++, sqlYesterday);
            } else if ("thisWeek".equals(dateFilter)) {
                Calendar weekStartCal = Calendar.getInstance();
                weekStartCal.set(Calendar.DAY_OF_WEEK, weekStartCal.getFirstDayOfWeek());
                java.sql.Date weekStart = new java.sql.Date(weekStartCal.getTimeInMillis());
                pstmt.setDate(paramIndex++, weekStart);
                pstmt.setDate(paramIndex++, sqlToday);
            } else if ("thisMonth".equals(dateFilter)) {
                pstmt.setInt(paramIndex++, currentMonth);
                pstmt.setInt(paramIndex++, currentYear);
            }
        }
        
        // Set status filter parameter
        if (!"all".equals(statusFilter)) {
            pstmt.setString(paramIndex++, statusFilter);
        }
        
        // Set search parameters
        if (searchQuery != null && !searchQuery.trim().isEmpty()) {
            String searchPattern = "%" + searchQuery.trim() + "%";
            pstmt.setString(paramIndex++, searchPattern);
            pstmt.setString(paramIndex++, searchPattern);
            pstmt.setString(paramIndex++, searchPattern);
            pstmt.setString(paramIndex++, searchPattern);
        }
        
        // Set date range parameters for recent payments
        pstmt.setDate(paramIndex++, sqlToday);
        pstmt.setDate(paramIndex++, sqlToday);
        
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> payment = new HashMap<>();
            payment.put("paymentId", rs.getString("payment_id"));
            payment.put("bookingId", "BK-" + rs.getString("booking_id"));
            payment.put("amount", rs.getDouble("amount"));
            payment.put("paymentDate", rs.getTimestamp("payment_date"));
            payment.put("paymentMethod", rs.getString("payment_method"));
            payment.put("status", rs.getString("status"));
            payment.put("guestName", rs.getString("first_name") + " " + rs.getString("last_name"));
            payment.put("guestImage", rs.getString("profile_image"));
            payment.put("guestEmail", rs.getString("email"));
            payment.put("guestPhone", rs.getString("phone"));
            payment.put("roomNumber", rs.getString("room_number"));
            payment.put("roomType", rs.getString("room_type"));
            payment.put("checkInDate", rs.getDate("check_in_date"));
            payment.put("checkOutDate", rs.getDate("check_out_date"));
            
            // Calculate nights
            long diff = rs.getDate("check_out_date").getTime() - rs.getDate("check_in_date").getTime();
            int nights = (int) (diff / (1000 * 60 * 60 * 24));
            payment.put("nights", nights);
            
            // Format dates for display
            SimpleDateFormat displayDateFormat = new SimpleDateFormat("dd MMM yyyy");
            payment.put("formattedCheckIn", displayDateFormat.format(rs.getDate("check_in_date")));
            payment.put("formattedCheckOut", displayDateFormat.format(rs.getDate("check_out_date")));
            
            SimpleDateFormat paymentDateFormat = new SimpleDateFormat("dd MMM yyyy HH:mm");
            payment.put("formattedPaymentDate", paymentDateFormat.format(rs.getTimestamp("payment_date")));
            
            recentPaymentsList.add(payment);
        }
        
        // Query for pending payments
        String pendingPaymentsQuery = paymentsListQuery.toString() + 
            " AND p.status = 'pending' " +
            "ORDER BY p.payment_date DESC LIMIT 10";
        
        pstmt = conn.prepareStatement(pendingPaymentsQuery);
        
        paramIndex = 1;
        
        // Set date filter parameters
        if (!"all".equals(dateFilter)) {
            if ("today".equals(dateFilter)) {
                pstmt.setDate(paramIndex++, sqlToday);
            } else if ("yesterday".equals(dateFilter)) {
                Calendar yesterdayCal = Calendar.getInstance();
                yesterdayCal.add(Calendar.DATE, -1);
                java.sql.Date sqlYesterday = new java.sql.Date(yesterdayCal.getTimeInMillis());
                pstmt.setDate(paramIndex++, sqlYesterday);
            } else if ("thisWeek".equals(dateFilter)) {
                Calendar weekStartCal = Calendar.getInstance();
                weekStartCal.set(Calendar.DAY_OF_WEEK, weekStartCal.getFirstDayOfWeek());
                java.sql.Date weekStart = new java.sql.Date(weekStartCal.getTimeInMillis());
                pstmt.setDate(paramIndex++, weekStart);
                pstmt.setDate(paramIndex++, sqlToday);
            } else if ("thisMonth".equals(dateFilter)) {
                pstmt.setInt(paramIndex++, currentMonth);
                pstmt.setInt(paramIndex++, currentYear);
            }
        }
        
        // Set status filter parameter (already included in the query)
        if (!"all".equals(statusFilter)) {
            pstmt.setString(paramIndex++, statusFilter);
        }
        
        // Set search parameters
        if (searchQuery != null && !searchQuery.trim().isEmpty()) {
            String searchPattern = "%" + searchQuery.trim() + "%";
            pstmt.setString(paramIndex++, searchPattern);
            pstmt.setString(paramIndex++, searchPattern);
            pstmt.setString(paramIndex++, searchPattern);
            pstmt.setString(paramIndex++, searchPattern);
        }
        
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> payment = new HashMap<>();
            payment.put("paymentId", rs.getString("payment_id"));
            payment.put("bookingId", "BK-" + rs.getString("booking_id"));
            payment.put("amount", rs.getDouble("amount"));
            payment.put("paymentDate", rs.getTimestamp("payment_date"));
            payment.put("paymentMethod", rs.getString("payment_method"));
            payment.put("status", rs.getString("status"));
            payment.put("guestName", rs.getString("first_name") + " " + rs.getString("last_name"));
            payment.put("guestImage", rs.getString("profile_image"));
            payment.put("guestEmail", rs.getString("email"));
            payment.put("guestPhone", rs.getString("phone"));
            payment.put("roomNumber", rs.getString("room_number"));
            payment.put("roomType", rs.getString("room_type"));
            payment.put("checkInDate", rs.getDate("check_in_date"));
            payment.put("checkOutDate", rs.getDate("check_out_date"));
            
            // Calculate nights
            long diff = rs.getDate("check_out_date").getTime() - rs.getDate("check_in_date").getTime();
            int nights = (int) (diff / (1000 * 60 * 60 * 24));
            payment.put("nights", nights);
            
            // Format dates for display
            SimpleDateFormat displayDateFormat = new SimpleDateFormat("dd MMM yyyy");
            payment.put("formattedCheckIn", displayDateFormat.format(rs.getDate("check_in_date")));
            payment.put("formattedCheckOut", displayDateFormat.format(rs.getDate("check_out_date")));
            
            SimpleDateFormat paymentDateFormat = new SimpleDateFormat("dd MMM yyyy HH:mm");
            payment.put("formattedPaymentDate", paymentDateFormat.format(rs.getTimestamp("payment_date")));
            
            pendingPaymentsList.add(payment);
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
    
    // Format current date for display
    SimpleDateFormat dateFormat = new SimpleDateFormat("MMMM dd, yyyy");
    String formattedDate = dateFormat.format(new java.util.Date());
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZAIRTAM - Historique des Paiements</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
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
        
        .payment-badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 500;
        }
        
        .payment-completed {
            background-color: #ECFDF5;
            color: #065F46;
        }
        
        .payment-pending {
            background-color: #FEF3C7;
            color: #92400E;
        }
        
        .payment-failed {
            background-color: #FEE2E2;
            color: #B91C1C;
        }
        
        .payment-refunded {
            background-color: #E0F2FE;
            color: #0369A1;
        }
        
        .date-badge {
            display: inline-block;
            padding: 0.25rem 0.5rem;
            border-radius: 0.25rem;
            font-size: 0.75rem;
            font-weight: 500;
        }
        
        .date-today {
            background-color: #E0F2FE;
            color: #0369A1;
        }
        
        .date-recent {
            background-color: #F3E8FF;
            color: #6B21A8;
        }
        
        .date-past {
            background-color: #E5E7EB;
            color: #4B5563;
        }
    </style>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Sidebar toggle for mobile
            const sidebarToggle = document.getElementById('sidebar-toggle');
            const sidebar = document.getElementById('sidebar');
            
            if (sidebarToggle) {
                sidebarToggle.addEventListener('click', function() {
                    sidebar.classList.toggle('open');
                });
            }
            
            // Close sidebar when clicking outside
            document.addEventListener('click', function(event) {
                if (!sidebar.contains(event.target) && !sidebarToggle.contains(event.target) && sidebar.classList.contains('open')) {
                    sidebar.classList.remove('open');
                }
            });
            
            // Initialize date pickers if needed
            const dateFilterSelect = document.getElementById('dateFilter');
            if (dateFilterSelect) {
                dateFilterSelect.addEventListener('change', function() {
                    document.getElementById('filterForm').submit();
                });
            }
            
            const statusFilterSelect = document.getElementById('statusFilter');
            if (statusFilterSelect) {
                statusFilterSelect.addEventListener('change', function() {
                    document.getElementById('filterForm').submit();
                });
            }
        });
    </script>
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
                    <a href="index.jsp" class="flex items-center">
                        <i class="fas fa-hotel text-blue-600 text-2xl mr-2"></i>
                        <span class="text-xl font-bold text-gray-800">ZAIRTAM</span>
                    </a>
                </div>
                
                <!-- Right Nav Items -->
                <div class="flex items-center space-x-4">
                    <button class="text-gray-500 hover:text-gray-700 relative">
                        <i class="fas fa-bell text-xl"></i>
                        <span class="absolute top-0 right-0 h-4 w-4 bg-red-500 rounded-full text-xs text-white flex items-center justify-center">3</span>
                    </button>
                    
                    <div class="relative">
                        <button class="flex items-center text-gray-800 hover:text-blue-600">
                            <img src="<%= employeeImage %>" alt="Profile" class="h-8 w-8 rounded-full object-cover">
                            <span class="ml-2 hidden md:block"><%= employeeName %></span>
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
                <div class="mb-4">
                    <div class="text-sm font-medium text-gray-500">Hotel</div>
                    <div class="text-base font-semibold text-gray-900"><%= hotelName %></div>
                    <div class="text-sm text-gray-500"><%= hotelLocation %></div>
                </div>
                
                <div class="mb-4">
                    <div class="text-sm font-medium text-gray-500">Employee</div>
                    <div class="text-base font-semibold text-gray-900"><%= employeeName %></div>
                    <div class="text-sm text-gray-500"><%= employeeRole %></div>
                </div>
                
                <hr class="my-4 border-gray-200">
                
                <nav class="space-y-1">
                    <a href="Dashboard.jsp" class="flex items-center px-2 py-2 text-base font-medium rounded-md text-gray-600 hover:bg-gray-50 hover:text-gray-900">
                        <i class="fas fa-tachometer-alt w-5 h-5 mr-3 text-gray-400"></i>
                        Dashboard
                    </a>
                    
                    <a href="Arrival-History.jsp" class="flex items-center px-2 py-2 text-base font-medium rounded-md text-gray-600 hover:bg-gray-50 hover:text-gray-900">
                        <i class="fas fa-calendar-check w-5 h-5 mr-3 text-gray-400"></i>
                        Arrivals
                    </a>
                    
                    <a href="Payment-History.jsp" class="flex items-center px-2 py-2 text-base font-medium rounded-md bg-blue-50 text-blue-600">
                        <i class="fas fa-money-bill-wave w-5 h-5 mr-3 text-blue-500"></i>
                        Payments
                    </a>
                    
                    <a href="#" class="flex items-center px-2 py-2 text-base font-medium rounded-md text-gray-600 hover:bg-gray-50 hover:text-gray-900">
                        <i class="fas fa-calendar-day w-5 h-5 mr-3 text-gray-400"></i>
                        Reservations
                    </a>
                    
                    <a href="#" class="flex items-center px-2 py-2 text-base font-medium rounded-md text-gray-600 hover:bg-gray-50 hover:text-gray-900">
                        <i class="fas fa-users w-5 h-5 mr-3 text-gray-400"></i>
                        Guests
                    </a>
                    
                    <a href="#" class="flex items-center px-2 py-2 text-base font-medium rounded-md text-gray-600 hover:bg-gray-50 hover:text-gray-900">
                        <i class="fas fa-door-open w-5 h-5 mr-3 text-gray-400"></i>
                        Rooms
                    </a>
                    
                    <a href="#" class="flex items-center px-2 py-2 text-base font-medium rounded-md text-gray-600 hover:bg-gray-50 hover:text-gray-900">
                        <i class="fas fa-chart-line w-5 h-5 mr-3 text-gray-400"></i>
                        Reports
                    </a>
                    
                    <a href="#" class="flex items-center px-2 py-2 text-base font-medium rounded-md text-gray-600 hover:bg-gray-50 hover:text-gray-900">
                        <i class="fas fa-cog w-5 h-5 mr-3 text-gray-400"></i>
                        Settings
                    </a>
                </nav>
            </div>
        </aside>

        <!-- Main Content -->
        <main class="flex-1 p-4 sm:p-6 lg:p-8">
            <div class="mb-6">
                <h1 class="text-2xl font-bold text-gray-900">Payment History</h1>
                <p class="text-sm text-gray-500"><%= formattedDate %></p>
            </div>
            
            <!-- Dashboard Stats -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
                <div class="bg-white rounded-lg shadow-sm p-4">
                    <div class="flex items-center">
                        <div class="flex-shrink-0 bg-blue-100 rounded-full p-3">
                            <i class="fas fa-money-bill-wave text-blue-600 text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <h2 class="text-sm font-medium text-gray-500">Total Payments</h2>
                            <p class="text-xl font-semibold text-gray-900"><%= totalPayments %></p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-4">
                    <div class="flex items-center">
                        <div class="flex-shrink-0 bg-green-100 rounded-full p-3">
                            <i class="fas fa-chart-line text-green-600 text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <h2 class="text-sm font-medium text-gray-500">This Month Revenue</h2>
                            <p class="text-xl font-semibold text-gray-900">€<%= String.format("%.2f", thisMonthRevenue) %></p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-4">
                    <div class="flex items-center">
                        <div class="flex-shrink-0 bg-purple-100 rounded-full p-3">
                            <i class="fas fa-history text-purple-600 text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <h2 class="text-sm font-medium text-gray-500">Last Month Revenue</h2>
                            <p class="text-xl font-semibold text-gray-900">€<%= String.format("%.2f", lastMonthRevenue) %></p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-4">
                    <div class="flex items-center">
                        <div class="flex-shrink-0 bg-yellow-100 rounded-full p-3">
                            <i class="fas fa-exclamation-circle text-yellow-600 text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <h2 class="text-sm font-medium text-gray-500">Pending Payments</h2>
                            <p class="text-xl font-semibold text-gray-900"><%= pendingPayments %></p>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Filters -->
            <div class="bg-white rounded-lg shadow-sm p-4 mb-6">
                <form id="filterForm" action="Payment-History.jsp" method="GET" class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label for="dateFilter" class="block text-sm font-medium text-gray-700 mb-1">Date Filter</label>
                        <select id="dateFilter" name="dateFilter" class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                            <option value="all" <%= "all".equals(dateFilter) ? "selected" : "" %>>All Dates</option>
                            <option value="today" <%= "today".equals(dateFilter) ? "selected" : "" %>>Today</option>
                            <option value="yesterday" <%= "yesterday".equals(dateFilter) ? "selected" : "" %>>Yesterday</option>
                            <option value="thisWeek" <%= "thisWeek".equals(dateFilter) ? "selected" : "" %>>This Week</option>
                            <option value="thisMonth" <%= "thisMonth".equals(dateFilter) ? "selected" : "" %>>This Month</option>
                        </select>
                    </div>
                    
                    <div>
                        <label for="statusFilter" class="block text-sm font-medium text-gray-700 mb-1">Status Filter</label>
                        <select id="statusFilter" name="statusFilter" class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                            <option value="all" <%= "all".equals(statusFilter) ? "selected" : "" %>>All Statuses</option>
                            <option value="completed" <%= "completed".equals(statusFilter) ? "selected" : "" %>>Completed</option>
                            <option value="pending" <%= "pending".equals(statusFilter) ? "selected" : "" %>>Pending</option>
                            <option value="failed" <%= "failed".equals(statusFilter) ? "selected" : "" %>>Failed</option>
                            <option value="refunded" <%= "refunded".equals(statusFilter) ? "selected" : "" %>>Refunded</option>
                        </select>
                    </div>
                    
                    <div>
                        <label for="search" class="block text-sm font-medium text-gray-700 mb-1">Search</label>
                        <div class="relative">
                            <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                <i class="fas fa-search text-gray-400"></i>
                            </div>
                            <input type="text" id="search" name="search" value="<%= searchQuery != null ? searchQuery : "" %>" 
                                   placeholder="Search by name, booking ID or room" 
                                   class="pl-10 w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                        </div>
                    </div>
                </form>
            </div>
            
            <!-- Dashboard Stats -->
            <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Total des Paiements</h3>
                        <div class="bg-blue-100 p-2 rounded-md">
                            <i class="fas fa-credit-card text-blue-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= totalPayments %></p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Transactions totales</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Revenus ce mois</h3>
                        <div class="bg-green-100 p-2 rounded-md">
                            <i class="fas fa-euro-sign text-green-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= String.format("%.2f €", thisMonthRevenue) %></p>
                        <% double revenueDiff = thisMonthRevenue - lastMonthRevenue; %>
                        <p class="<%= revenueDiff >= 0 ? "text-green-600" : "text-red-600" %> text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-<%= revenueDiff >= 0 ? "up" : "down" %> mr-1"></i><%= String.format("%.1f", Math.abs(revenueDiff)) %>
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">vs. mois dernier</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Paiements en attente</h3>
                        <div class="bg-yellow-100 p-2 rounded-md">
                            <i class="fas fa-clock text-yellow-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= pendingPayments %></p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">À traiter</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Méthode préférée</h3>
                        <div class="bg-purple-100 p-2 rounded-md">
                            <i class="fas fa-chart-pie text-purple-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800">Carte</p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Mode de paiement</p>
                </div>
            </div>
            
            <!-- Recent Payments Section -->
            <div class="bg-white rounded-lg shadow-sm mb-8">
                <div class="p-6 border-b border-gray-200">
                    <div class="flex items-center justify-between">
                        <h3 class="text-lg font-semibold text-gray-800">Paiements récents</h3>
                        <span class="date-badge date-today">
                            <i class="far fa-calendar-alt mr-1"></i> <%= formattedDate %>
                        </span>
                    </div>
                </div>
                
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Client
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Réservation
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Montant
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Date
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Méthode
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Statut
                                </th>
                                <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Actions
                                </th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            <% if (recentPaymentsList.isEmpty()) { %>
                                <tr>
                                    <td colspan="7" class="px-6 py-4 text-center text-gray-500">
                                        Aucun paiement récent trouvé
                                    </td>
                                </tr>
                            <% } else { %>
                                <% for (Map<String, Object> payment : recentPaymentsList) { %>
                                    <tr>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="flex items-center">
                                                <div class="flex-shrink-0 h-10 w-10">
                                                    <img class="h-10 w-10 rounded-full" src="<%= payment.get("guestImage") %>" alt="Guest">
                                                </div>
                                                <div class="ml-4">
                                                    <div class="text-sm font-medium text-gray-900"><%= payment.get("guestName") %></div>
                                                    <div class="text-sm text-gray-500"><%= payment.get("guestEmail") %></div>
                                                </div>
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="text-sm text-gray-900"><%= payment.get("bookingId") %></div>
                                            <div class="text-sm text-gray-500">Chambre <%= payment.get("roomNumber") %></div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="text-sm font-medium text-gray-900"><%= String.format("%.2f €", payment.get("amount")) %></div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="text-sm text-gray-900"><%= payment.get("formattedPaymentDate") %></div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <% 
                                                String paymentMethod = (String)payment.get("paymentMethod");
                                                String methodIcon = "fa-credit-card";
                                                
                                                if ("cash".equals(paymentMethod)) {
                                                    methodIcon = "fa-money-bill";
                                                } else if ("bank_transfer".equals(paymentMethod)) {
                                                    methodIcon = "fa-university";
                                                } else if ("paypal".equals(paymentMethod)) {
                                                    methodIcon = "fa-paypal";
                                                }
                                            %>
                                            <div class="text-sm text-gray-900">
                                                <i class="fas <%= methodIcon %> mr-1"></i>
                                                <%= paymentMethod.substring(0, 1).toUpperCase() + paymentMethod.substring(1).replace("_", " ") %>
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <% 
                                                String status = (String)payment.get("status");
                                                String badgeClass = "payment-completed";
                                                
                                                if ("pending".equals(status)) {
                                                    badgeClass = "payment-pending";
                                                } else if ("failed".equals(status)) {
                                                    badgeClass = "payment-failed";
                                                } else if ("refunded".equals(status)) {
                                                    badgeClass = "payment-refunded";
                                                }
                                            %>
                                            <span class="payment-badge <%= badgeClass %>">
                                                <%= status.substring(0, 1).toUpperCase() + status.substring(1) %>
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                            <% if ("pending".equals(status)) { %>
                                                <button class="bg-green-600 hover:bg-green-700 text-white px-3 py-1 rounded-md mr-2">
                                                    <i class="fas fa-check-circle mr-1"></i> Approuver
                                                </button>
                                            <% } %>
                                            <button class="bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded-md">
                                                <i class="fas fa-eye mr-1"></i> Détails
                                            </button>
                                        </td>
                                    </tr>
                                <% } %>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
            
            <!-- Pending Payments Section -->
            <div class="bg-white rounded-lg shadow-sm">
                <div class="p-6 border-b border-gray-200">
                    <div class="flex items-center justify-between">
                        <h3 class="text-lg font-semibold text-gray-800">Paiements en attente</h3>
                        <a href="#" class="text-blue-600 hover:text-blue-800 text-sm font-medium">
                            Voir tout <i class="fas fa-arrow-right ml-1"></i>
                        </a>
                    </div>
                </div>
                
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Client
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Réservation
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Montant
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Date
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Méthode
                                </th>
                                <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Actions
                                </th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            <% if (pendingPaymentsList.isEmpty()) { %>
                                <tr>
                                    <td colspan="6" class="px-6 py-4 text-center text-gray-500">
                                        Aucun paiement en attente trouvé
                                    </td>
                                </tr>
                            <% } else { %>
                                <% for (Map<String, Object> payment : pendingPaymentsList) { %>
                                    <tr>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="flex items-center">
                                                <div class="flex-shrink-0 h-10 w-10">
                                                    <img class="h-10 w-10 rounded-full" src="<%= payment.get("guestImage") %>" alt="Guest">
                                                </div>
                                                <div class="ml-4">
                                                    <div class="text-sm font-medium text-gray-900"><%= payment.get("guestName") %></div>
                                                    <div class="text-sm text-gray-500"><%= payment.get("guestEmail") %></div>
                                                </div>
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="text-sm text-gray-900"><%= payment.get("bookingId") %></div>
                                            <div class="text-sm text-gray-500">Chambre <%= payment.get("roomNumber") %></div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="text-sm font-medium text-gray-900"><%= String.format("%.2f €", payment.get("amount")) %></div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="text-sm text-gray-900"><%= payment.get("formattedPaymentDate") %></div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <% 
                                                String paymentMethod = (String)payment.get("paymentMethod");
                                                String methodIcon = "fa-credit-card";
                                                
                                                if ("cash".equals(paymentMethod)) {
                                                    methodIcon = "fa-money-bill";
                                                } else if ("bank_transfer".equals(paymentMethod)) {
                                                    methodIcon = "fa-university";
                                                } else if ("paypal".equals(paymentMethod)) {
                                                    methodIcon = "fa-paypal";
                                                }
                                            %>
                                            <div class="text-sm text-gray-900">
                                                <i class="fas <%= methodIcon %> mr-1"></i>
                                                <%= paymentMethod.substring(0, 1).toUpperCase() + paymentMethod.substring(1).replace("_", " ") %>
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                            <button class="bg-green-600 hover:bg-green-700 text-white px-3 py-1 rounded-md mr-2">
                                                <i class="fas fa-check-circle mr-1"></i> Approuver
                                            </button>
                                            <button class="bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded-md mr-2">
                                                <i class="fas fa-times-circle mr-1"></i> Rejeter
                                            </button>
                                            <button class="bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded-md">
                                                <i class="fas fa-eye mr-1"></i> Détails
                                            </button>
                                        </td>
                                    </tr>
                                <% } %>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </main>
    </div>

    <!-- JavaScript for Functionality -->
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Approve payment functionality
            const approveButtons = document.querySelectorAll('.bg-green-600');
            approveButtons.forEach(button => {
                button.addEventListener('click', function() {
                    // Here you would normally send an AJAX request to update the payment status
                    alert('Paiement approuvé avec succès!');
                    this.innerHTML = '<i class="fas fa-check"></i> Approuvé';
                    this.classList.remove('bg-green-600', 'hover:bg-green-700');
                    this.classList.add('bg-gray-500', 'hover:bg-gray-600');
                    this.disabled = true;
                });
            });
            
            // Reject payment functionality
            const rejectButtons = document.querySelectorAll('.bg-red-600');
            rejectButtons.forEach(button => {
                button.addEventListener('click', function() {
                    // Here you would normally open a rejection reason modal
                    alert('Paiement rejeté!');
                });
            });
            
            // Add sign out functionality
            const profileButton = document.querySelector('.flex.items-center.text-gray-800');
            if (profileButton) {
                const dropdown = document.createElement('div');
                dropdown.className = 'absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-50 hidden';
                dropdown.innerHTML = `
                    <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Profil</a>
                    <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Paramètres</a>
                    <form id="signOutForm" method="POST" action="../logout.jsp">
                        <button type="submit" class="w-full text-left block px-4 py-2 text-sm text-red-600 hover:bg-gray-100">
                            <i class="fas fa-sign-out-alt mr-2"></i>Déconnexion
                        </button>
                    </form>
                `;
                
                profileButton.parentNode.classList.add('relative', 'group');
                profileButton.parentNode.appendChild(dropdown);
                
                profileButton.addEventListener('click', function(e) {
                    e.preventDefault();
                    dropdown.classList.toggle('hidden');
                });
                
                document.addEventListener('click', function(e) {
                    if (!profileButton.contains(e.target) && !dropdown.contains(e.target)) {
                        dropdown.classList.add('hidden');
                    }
                });
            }
        });
    </script>
</body>
</html>