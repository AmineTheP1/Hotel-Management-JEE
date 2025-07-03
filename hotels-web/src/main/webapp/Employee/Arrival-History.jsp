<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
    // Database connection parameters
    String jdbcURL = "jdbc:mysql://localhost:4200/hotel?useSSL=false";
    String dbUser = "root";
    String dbPassword = "Hamza_13579";
    
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
    int totalArrivals = 0;
    int thisMonthArrivals = 0;
    int lastMonthArrivals = 0;
    int pendingArrivals = 0;
    
    // Arrivals lists
    List<Map<String, Object>> recentArrivalsList = new ArrayList<>();
    List<Map<String, Object>> upcomingArrivalsList = new ArrayList<>();
    
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
        
        // Query for total arrivals count
        String totalArrivalsQuery = "SELECT COUNT(*) FROM bookings WHERE status IN ('confirmed', 'checked_in', 'completed')";
        pstmt = conn.prepareStatement(totalArrivalsQuery);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            totalArrivals = rs.getInt(1);
        }
        
        // Query for this month's arrivals
        String thisMonthQuery = "SELECT COUNT(*) FROM bookings WHERE MONTH(check_in_date) = ? AND YEAR(check_in_date) = ? AND status IN ('confirmed', 'checked_in', 'completed')";
        pstmt = conn.prepareStatement(thisMonthQuery);
        pstmt.setInt(1, currentMonth);
        pstmt.setInt(2, currentYear);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            thisMonthArrivals = rs.getInt(1);
        }
        
        // Query for last month's arrivals
        pstmt = conn.prepareStatement(thisMonthQuery);
        pstmt.setInt(1, lastMonth);
        pstmt.setInt(2, lastMonthYear);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            lastMonthArrivals = rs.getInt(1);
        }
        
        // Query for pending arrivals
        String pendingQuery = "SELECT COUNT(*) FROM bookings WHERE check_in_date >= ? AND status = 'confirmed'";
        pstmt = conn.prepareStatement(pendingQuery);
        pstmt.setDate(1, sqlToday);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            pendingArrivals = rs.getInt(1);
        }
        
        // Base query for arrivals list
        StringBuilder arrivalsListQuery = new StringBuilder(
            "SELECT b.booking_id, g.first_name, g.last_name, g.profile_image, g.email, g.phone, " +
            "r.room_number, r.room_type, b.check_in_date, b.check_out_date, " +
            "b.status, p.status AS payment_status, p.amount_paid, p.amount_due " +
            "FROM bookings b " +
            "JOIN guests g ON b.guest_id = g.guest_id " +
            "JOIN rooms r ON b.room_id = r.room_id " +
            "JOIN payments p ON b.booking_id = p.booking_id " +
            "WHERE 1=1"
        );
        
        // Apply filters
        if (!"all".equals(dateFilter)) {
            if ("today".equals(dateFilter)) {
                arrivalsListQuery.append(" AND b.check_in_date = ?");
            } else if ("yesterday".equals(dateFilter)) {
                Calendar yesterdayCal = Calendar.getInstance();
                yesterdayCal.add(Calendar.DATE, -1);
                java.sql.Date sqlYesterday = new java.sql.Date(yesterdayCal.getTimeInMillis());
                arrivalsListQuery.append(" AND b.check_in_date = ?");
            } else if ("thisWeek".equals(dateFilter)) {
                Calendar weekStartCal = Calendar.getInstance();
                weekStartCal.set(Calendar.DAY_OF_WEEK, weekStartCal.getFirstDayOfWeek());
                java.sql.Date weekStart = new java.sql.Date(weekStartCal.getTimeInMillis());
                arrivalsListQuery.append(" AND b.check_in_date BETWEEN ? AND ?");
            } else if ("thisMonth".equals(dateFilter)) {
                arrivalsListQuery.append(" AND MONTH(b.check_in_date) = ? AND YEAR(b.check_in_date) = ?");
            }
        }
        
        if (!"all".equals(statusFilter)) {
            arrivalsListQuery.append(" AND b.status = ?");
        }
        
        if (searchQuery != null && !searchQuery.trim().isEmpty()) {
            arrivalsListQuery.append(" AND (g.first_name LIKE ? OR g.last_name LIKE ? OR CONCAT('BK-', b.booking_id) LIKE ? OR r.room_number LIKE ?)");
        }
        
        // Query for recent arrivals (last 30 days)
        String recentArrivalsQuery = arrivalsListQuery.toString() + 
            " AND b.check_in_date BETWEEN DATE_SUB(?, INTERVAL 30 DAY) AND ? " +
            "ORDER BY b.check_in_date DESC LIMIT 50";
        
        pstmt = conn.prepareStatement(recentArrivalsQuery);
        
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
        
        // Set date range parameters for recent arrivals
        pstmt.setDate(paramIndex++, sqlToday);
        pstmt.setDate(paramIndex++, sqlToday);
        
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> arrival = new HashMap<>();
            arrival.put("bookingId", "BK-" + rs.getString("booking_id"));
            arrival.put("guestName", rs.getString("first_name") + " " + rs.getString("last_name"));
            arrival.put("guestImage", rs.getString("profile_image"));
            arrival.put("guestEmail", rs.getString("email"));
            arrival.put("guestPhone", rs.getString("phone"));
            arrival.put("roomNumber", rs.getString("room_number"));
            arrival.put("roomType", rs.getString("room_type"));
            arrival.put("checkInDate", rs.getDate("check_in_date"));
            arrival.put("checkOutDate", rs.getDate("check_out_date"));
            arrival.put("status", rs.getString("status"));
            arrival.put("paymentStatus", rs.getString("payment_status"));
            arrival.put("amountPaid", rs.getDouble("amount_paid"));
            arrival.put("amountDue", rs.getDouble("amount_due"));
            
            // Calculate nights
            long diff = rs.getDate("check_out_date").getTime() - rs.getDate("check_in_date").getTime();
            int nights = (int) (diff / (1000 * 60 * 60 * 24));
            arrival.put("nights", nights);
            
            // Format dates for display
            SimpleDateFormat displayDateFormat = new SimpleDateFormat("dd MMM yyyy");
            arrival.put("formattedCheckIn", displayDateFormat.format(rs.getDate("check_in_date")));
            arrival.put("formattedCheckOut", displayDateFormat.format(rs.getDate("check_out_date")));
            
            recentArrivalsList.add(arrival);
        }
        
        // Query for upcoming arrivals
        String upcomingArrivalsQuery = arrivalsListQuery.toString() + 
            " AND b.check_in_date > ? AND b.status = 'confirmed' " +
            "ORDER BY b.check_in_date ASC LIMIT 10";
        
        pstmt = conn.prepareStatement(upcomingArrivalsQuery);
        
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
        
        // Set date parameter for upcoming arrivals
        pstmt.setDate(paramIndex++, sqlToday);
        
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> arrival = new HashMap<>();
            arrival.put("bookingId", "BK-" + rs.getString("booking_id"));
            arrival.put("guestName", rs.getString("first_name") + " " + rs.getString("last_name"));
            arrival.put("guestImage", rs.getString("profile_image"));
            arrival.put("guestEmail", rs.getString("email"));
            arrival.put("guestPhone", rs.getString("phone"));
            arrival.put("roomNumber", rs.getString("room_number"));
            arrival.put("roomType", rs.getString("room_type"));
            arrival.put("checkInDate", rs.getDate("check_in_date"));
            arrival.put("checkOutDate", rs.getDate("check_out_date"));
            arrival.put("status", rs.getString("status"));
            arrival.put("paymentStatus", rs.getString("payment_status"));
            arrival.put("amountPaid", rs.getDouble("amount_paid"));
            arrival.put("amountDue", rs.getDouble("amount_due"));
            
            // Calculate nights
            long diff = rs.getDate("check_out_date").getTime() - rs.getDate("check_in_date").getTime();
            int nights = (int) (diff / (1000 * 60 * 60 * 24));
            arrival.put("nights", nights);
            
            // Format dates for display
            SimpleDateFormat displayDateFormat = new SimpleDateFormat("dd MMM yyyy");
            arrival.put("formattedCheckIn", displayDateFormat.format(rs.getDate("check_in_date")));
            arrival.put("formattedCheckOut", displayDateFormat.format(rs.getDate("check_out_date")));
            
            upcomingArrivalsList.add(arrival);
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
    <title>ZAIRTAM - Historique des Arrivées</title>
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
        
        .payment-paid {
            background-color: #ECFDF5;
            color: #065F46;
        }
        
        .payment-partial {
            background-color: #FEF3C7;
            color: #92400E;
        }
        
        .payment-unpaid {
            background-color: #FEE2E2;
            color: #B91C1C;
        }
        
        .status-badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 500;
        }
        
        .status-confirmed {
            background-color: #E0F2FE;
            color: #0369A1;
        }
        
        .status-checked-in {
            background-color: #ECFDF5;
            color: #065F46;
        }
        
        .status-completed {
            background-color: #F3E8FF;
            color: #6B21A8;
        }
        
        .status-cancelled {
            background-color: #FEE2E2;
            color: #B91C1C;
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
        
        .date-upcoming {
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
                <div class="mb-6">
                    <div class="flex items-center mb-4">
                        <div class="flex-shrink-0">
                            <img src="https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=80&q=80" alt="Hotel" class="h-12 w-12 rounded-md object-cover">
                        </div>
                        <div class="ml-3">
                            <h3 class="text-sm font-medium text-gray-900"><%= hotelName %></h3>
                            <p class="text-xs text-gray-500"><%= hotelLocation %></p>
                        </div>
                    </div>
                    
                    <h3 class="text-xs uppercase text-gray-500 font-semibold tracking-wider">Réception</h3>
                    <ul class="mt-3 space-y-1">
                        <li>
                            <a href="Dashboard.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-tachometer-alt w-5 text-center"></i>
                                <span class="ml-2">Tableau de bord</span>
                            </a>
                        </li>
                        <li>
                            <a href="Arrival-History.jsp" class="flex items-center px-3 py-2 text-blue-600 bg-blue-50 rounded-md">
                                <i class="fas fa-calendar-check w-5 text-center"></i>
                                <span class="ml-2">Historique des arrivées</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-credit-card w-5 text-center"></i>
                                <span class="ml-2">Historique des paiements</span>
                            </a>
                        </li>
                    </ul>
                </div>
                
                <div class="mb-6">
                    <h3 class="text-xs uppercase text-gray-500 font-semibold tracking-wider">Gestion de l'hôtel</h3>
                    <ul class="mt-3 space-y-1">
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-door-open w-5 text-center"></i>
                                <span class="ml-2">Chambres</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-users w-5 text-center"></i>
                                <span class="ml-2">Clients</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-calendar-alt w-5 text-center"></i>
                                <span class="ml-2">Réservations</span>
                            </a>
                        </li>
                    </ul>
                </div>
                
                <div>
                    <h3 class="text-xs uppercase text-gray-500 font-semibold tracking-wider">Support</h3>
                    <ul class="mt-3 space-y-1">
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-question-circle w-5 text-center"></i>
                                <span class="ml-2">Centre d'aide</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-headset w-5 text-center"></i>
                                <span class="ml-2">Contacter le support</span>
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
                    <h1 class="text-2xl font-bold text-gray-800">Historique des Arrivées</h1>
                    <p class="text-gray-600">Consultez et gérez l'historique des arrivées des clients</p>
                </div>
                <div class="flex space-x-3">
                    <form id="filterForm" action="Arrival-History.jsp" method="GET" class="flex space-x-3">
                        <div class="relative">
                            <span class="absolute inset-y-0 left-0 pl-3 flex items-center">
                                <i class="fas fa-search text-gray-400"></i>
                            </span>
                            <input type="text" name="search" placeholder="Rechercher par nom ou ID de réservation" 
                                   value="<%= searchQuery != null ? searchQuery : "" %>"
                                   class="pl-10 pr-4 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 w-64">
                        </div>
                        <select name="dateFilter" id="dateFilter" class="border rounded-lg px-4 py-2 focus:ring-blue-500 focus:border-blue-500">
                            <option value="all" <%= "all".equals(dateFilter) ? "selected" : "" %>>Toutes les dates</option>
                            <option value="today" <%= "today".equals(dateFilter) ? "selected" : "" %>>Aujourd'hui</option>
                            <option value="yesterday" <%= "yesterday".equals(dateFilter) ? "selected" : "" %>>Hier</option>
                            <option value="thisWeek" <%= "thisWeek".equals(dateFilter) ? "selected" : "" %>>Cette semaine</option>
                            <option value="thisMonth" <%= "thisMonth".equals(dateFilter) ? "selected" : "" %>>Ce mois</option>
                        </select>
                        <select name="statusFilter" id="statusFilter" class="border rounded-lg px-4 py-2 focus:ring-blue-500 focus:border-blue-500">
                            <option value="all" <%= "all".equals(statusFilter) ? "selected" : "" %>>Tous les statuts</option>
                            <option value="confirmed" <%= "confirmed".equals(statusFilter) ? "selected" : "" %>>Confirmé</option>
                            <option value="checked_in" <%= "checked_in".equals(statusFilter) ? "selected" : "" %>>Enregistré</option>
                            <option value="completed" <%= "completed".equals(statusFilter) ? "selected" : "" %>>Terminé</option>
                            <option value="cancelled" <%= "cancelled".equals(statusFilter) ? "selected" : "" %>>Annulé</option>
                        </select>
                        <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg transition duration-200">
                            Filtrer
                        </button>
                    </form>
                    <button class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg transition duration-200 flex items-center">
                        <i class="fas fa-plus mr-2"></i> Nouvelle Arrivée
                    </button>
                </div>
            </div>
            
            <!-- Dashboard Stats -->
            <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Total des Arrivées</h3>
                        <div class="bg-blue-100 p-2 rounded-md">
                            <i class="fas fa-users text-blue-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= totalArrivals %></p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Toutes les arrivées</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Arrivées ce mois</h3>
                        <div class="bg-green-100 p-2 rounded-md">
                            <i class="fas fa-calendar-check text-green-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= thisMonthArrivals %></p>
                        <% int monthDiff = thisMonthArrivals - lastMonthArrivals; %>
                        <p class="<%= monthDiff >= 0 ? "text-green-600" : "text-red-600" %> text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-<%= monthDiff >= 0 ? "up" : "down" %> mr-1"></i><%= Math.abs(monthDiff) %>
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">vs. mois dernier</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Arrivées en attente</h3>
                        <div class="bg-yellow-100 p-2 rounded-md">
                            <i class="fas fa-clock text-yellow-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= pendingArrivals %></p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">À venir</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Taux de conversion</h3>
                        <div class="bg-purple-100 p-2 rounded-md">
                            <i class="fas fa-chart-line text-purple-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <% 
                            double conversionRate = 0;
                            if (totalArrivals > 0) {
                                int completedArrivals = 0;
                                for (Map<String, Object> arrival : recentArrivalsList) {
                                    if ("completed".equals(arrival.get("status"))) {
                                        completedArrivals++;
                                    }
                                }
                                conversionRate = (double) completedArrivals / totalArrivals * 100;
                            }
                        %>
                        <p class="text-2xl font-bold text-gray-800"><%= String.format("%.1f", conversionRate) %>%</p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Réservations complétées</p>
                </div>
            </div>
            
            <!-- Recent Arrivals Section -->
            <div class="bg-white rounded-lg shadow-sm mb-8">
                <div class="p-6 border-b border-gray-200">
                    <div class="flex items-center justify-between">
                        <h3 class="text-lg font-semibold text-gray-800">Arrivées récentes</h3>
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
                                    Chambre
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Dates
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Statut
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Paiement
                                </th>
                                <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Actions
                                </th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            <% if (recentArrivalsList.isEmpty()) { %>
                                <tr>
                                    <td colspan="6" class="px-6 py-4 text-center text-gray-500">
                                        Aucune arrivée récente trouvée
                                    </td>
                                </tr>
                            <% } else { %>
                                <% for (Map<String, Object> arrival : recentArrivalsList) { %>
                                    <tr>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="flex items-center">
                                                <div class="flex-shrink-0 h-10 w-10">
                                                    <img class="h-10 w-10 rounded-full" src="<%= arrival.get("guestImage") %>" alt="Guest">
                                                </div>
                                                <div class="ml-4">
                                                    <div class="text-sm font-medium text-gray-900"><%= arrival.get("guestName") %></div>
                                                    <div class="text-sm text-gray-500"><%= arrival.get("bookingId") %></div>
                                                </div>
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="text-sm text-gray-900">Chambre <%= arrival.get("roomNumber") %></div>
                                            <div class="text-sm text-gray-500"><%= arrival.get("roomType") %></div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="text-sm text-gray-900"><%= arrival.get("formattedCheckIn") %> - <%= arrival.get("formattedCheckOut") %></div>
                                            <div class="text-sm text-gray-500"><%= arrival.get("nights") %> nuits</div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <% 
                                                String status = (String)arrival.get("status");
                                                String statusBadgeClass = "status-confirmed";
                                                String statusDisplay = "Confirmé";
                                                
                                                if ("checked_in".equals(status)) {
                                                    statusBadgeClass = "status-checked-in";
                                                    statusDisplay = "Enregistré";
                                                } else if ("completed".equals(status)) {
                                                    statusBadgeClass = "status-completed";
                                                    statusDisplay = "Terminé";
                                                } else if ("cancelled".equals(status)) {
                                                    statusBadgeClass = "status-cancelled";
                                                    statusDisplay = "Annulé";
                                                }
                                            %>
                                            <span class="status-badge <%= statusBadgeClass %>">
                                                <%= statusDisplay %>
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <% 
                                                String paymentStatus = (String)arrival.get("paymentStatus");
                                                String badgeClass = "payment-unpaid";
                                                String paymentDisplay = "Non payé";
                                                
                                                if ("paid".equals(paymentStatus)) {
                                                    badgeClass = "payment-paid";
                                                    paymentDisplay = "Payé";
                                                } else if ("partial".equals(paymentStatus)) {
                                                    badgeClass = "payment-partial";
                                                    paymentDisplay = "Partiel";
                                                }
                                            %>
                                            <span class="payment-badge <%= badgeClass %>">
                                                <%= paymentDisplay %>
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                            <% if ("confirmed".equals(status)) { %>
                                                <button class="bg-green-600 hover:bg-green-700 text-white px-3 py-1 rounded-md mr-2">
                                                    <i class="fas fa-check-circle mr-1"></i> Enregistrer
                                                </button>
                                            <% } %>
                                            <% if (!"paid".equals(paymentStatus)) { %>
                                                <button class="bg-yellow-600 hover:bg-yellow-700 text-white px-3 py-1 rounded-md mr-2">
                                                    <i class="fas fa-euro-sign mr-1"></i> Paiement
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
            
            <!-- Upcoming Arrivals Section -->
            <div class="bg-white rounded-lg shadow-sm">
                <div class="p-6 border-b border-gray-200">
                    <div class="flex items-center justify-between">
                        <h3 class="text-lg font-semibold text-gray-800">Arrivées à venir</h3>
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
                                    Chambre
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Dates
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Paiement
                                </th>
                                <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Actions
                                </th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            <% if (upcomingArrivalsList.isEmpty()) { %>
                                <tr>
                                    <td colspan="5" class="px-6 py-4 text-center text-gray-500">
                                        Aucune arrivée à venir trouvée
                                    </td>
                                </tr>
                            <% } else { %>
                                <% for (Map<String, Object> arrival : upcomingArrivalsList) { %>
                                    <tr>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="flex items-center">
                                                <div class="flex-shrink-0 h-10 w-10">
                                                    <img class="h-10 w-10 rounded-full" src="<%= arrival.get("guestImage") %>" alt="Guest">
                                                </div>
                                                <div class="ml-4">
                                                    <div class="text-sm font-medium text-gray-900"><%= arrival.get("guestName") %></div>
                                                    <div class="text-sm text-gray-500"><%= arrival.get("bookingId") %></div>
                                                </div>
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="text-sm text-gray-900">Chambre <%= arrival.get("roomNumber") %></div>
                                            <div class="text-sm text-gray-500"><%= arrival.get("roomType") %></div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="text-sm text-gray-900"><%= arrival.get("formattedCheckIn") %> - <%= arrival.get("formattedCheckOut") %></div>
                                            <div class="text-sm text-gray-500"><%= arrival.get("nights") %> nuits</div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <% 
                                                String paymentStatus = (String)arrival.get("paymentStatus");
                                                String badgeClass = "payment-unpaid";
                                                String paymentDisplay = "Non payé";
                                                
                                                if ("paid".equals(paymentStatus)) {
                                                    badgeClass = "payment-paid";
                                                    paymentDisplay = "Payé";
                                                } else if ("partial".equals(paymentStatus)) {
                                                    badgeClass = "payment-partial";
                                                    paymentDisplay = "Partiel";
                                                }
                                            %>
                                            <span class="payment-badge <%= badgeClass %>">
                                                <%= paymentDisplay %>
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
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
            // Check-in functionality
            const checkInButtons = document.querySelectorAll('.bg-green-600');
            checkInButtons.forEach(button => {
                button.addEventListener('click', function() {
                    // Here you would normally send an AJAX request to update the booking status
                    alert('Client enregistré avec succès!');
                    this.innerHTML = '<i class="fas fa-check"></i> Enregistré';
                    this.classList.remove('bg-green-600', 'hover:bg-green-700');
                    this.classList.add('bg-gray-500', 'hover:bg-gray-600');
                    this.disabled = true;
                });
            });
            
            // Payment collection functionality
            const paymentButtons = document.querySelectorAll('.bg-yellow-600');
            paymentButtons.forEach(button => {
                button.addEventListener('click', function() {
                    // Here you would normally open a payment modal
                    alert('Collecte de paiement initiée!');
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