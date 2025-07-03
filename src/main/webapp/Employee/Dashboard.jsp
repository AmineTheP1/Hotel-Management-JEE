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
    int todayArrivals = 0;
    int yesterdayArrivals = 0;
    int todayDepartures = 0;
    int yesterdayDepartures = 0;
    int occupiedRooms = 0;
    int totalRooms = 0;
    int pendingPayments = 0;
    double pendingAmount = 0.0;
    
    // Today's arrivals list
    List<Map<String, Object>> todayArrivalsList = new ArrayList<>();
    
    // Upcoming bookings list
    List<Map<String, Object>> upcomingBookingsList = new ArrayList<>();
    
    try {
        // Establish database connection
        Class.forName("com.mysql.jdbc.Driver");
        conn = DriverManager.getConnection(jdbcURL, dbUser, dbPassword);
        
        // Get today's date
        java.util.Date today = new java.util.Date();
        java.sql.Date sqlToday = new java.sql.Date(today.getTime());
        
        // Yesterday's date
        Calendar cal = Calendar.getInstance();
        cal.add(Calendar.DATE, -1);
        java.sql.Date sqlYesterday = new java.sql.Date(cal.getTimeInMillis());
        
        // Query for today's arrivals count
        String arrivalsQuery = "SELECT COUNT(*) FROM bookings WHERE check_in_date = ? AND status = 'confirmed'";
        pstmt = conn.prepareStatement(arrivalsQuery);
        pstmt.setDate(1, sqlToday);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            todayArrivals = rs.getInt(1);
        }
        
        // Query for yesterday's arrivals
        pstmt.setDate(1, sqlYesterday);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            yesterdayArrivals = rs.getInt(1);
        }
        
        // Query for today's departures
        String departuresQuery = "SELECT COUNT(*) FROM bookings WHERE check_out_date = ? AND status = 'checked_in'";
        pstmt = conn.prepareStatement(departuresQuery);
        pstmt.setDate(1, sqlToday);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            todayDepartures = rs.getInt(1);
        }
        
        // Query for yesterday's departures
        pstmt.setDate(1, sqlYesterday);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            yesterdayDepartures = rs.getInt(1);
        }
        
        // Query for occupied rooms and total rooms
        String roomsQuery = "SELECT " +
                           "(SELECT COUNT(*) FROM rooms WHERE status = 'occupied') AS occupied_rooms, " +
                           "(SELECT COUNT(*) FROM rooms) AS total_rooms";
        pstmt = conn.prepareStatement(roomsQuery);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            occupiedRooms = rs.getInt("occupied_rooms");
            totalRooms = rs.getInt("total_rooms");
        }
        
        // Query for pending payments
        String paymentsQuery = "SELECT COUNT(*) AS count, SUM(amount_due) AS total " +
                              "FROM payments WHERE status = 'pending'";
        pstmt = conn.prepareStatement(paymentsQuery);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            pendingPayments = rs.getInt("count");
            pendingAmount = rs.getDouble("total");
        }
        
        // Query for today's arrivals list
        String arrivalsListQuery = "SELECT b.booking_id, g.first_name, g.last_name, g.profile_image, " +
                                  "r.room_number, r.room_type, b.check_in_date, b.check_out_date, " +
                                  "p.status AS payment_status " +
                                  "FROM bookings b " +
                                  "JOIN guests g ON b.guest_id = g.guest_id " +
                                  "JOIN rooms r ON b.room_id = r.room_id " +
                                  "JOIN payments p ON b.booking_id = p.booking_id " +
                                  "WHERE b.check_in_date = ? AND b.status = 'confirmed' " +
                                  "ORDER BY b.booking_id DESC";
        pstmt = conn.prepareStatement(arrivalsListQuery);
        pstmt.setDate(1, sqlToday);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> arrival = new HashMap<>();
            arrival.put("bookingId", "BK-" + rs.getString("booking_id"));
            arrival.put("guestName", rs.getString("first_name") + " " + rs.getString("last_name"));
            arrival.put("guestImage", rs.getString("profile_image"));
            arrival.put("roomNumber", rs.getString("room_number"));
            arrival.put("roomType", rs.getString("room_type"));
            arrival.put("checkInDate", rs.getDate("check_in_date"));
            arrival.put("checkOutDate", rs.getDate("check_out_date"));
            arrival.put("paymentStatus", rs.getString("payment_status"));
            
            // Calculate nights
            long diff = rs.getDate("check_out_date").getTime() - rs.getDate("check_in_date").getTime();
            int nights = (int) (diff / (1000 * 60 * 60 * 24));
            arrival.put("nights", nights);
            
            todayArrivalsList.add(arrival);
        }
        
        // Query for upcoming bookings
        String upcomingQuery = "SELECT b.booking_id, g.first_name, g.last_name, g.profile_image, " +
                              "r.room_number, r.room_type, b.check_in_date, b.check_out_date, " +
                              "p.status AS payment_status " +
                              "FROM bookings b " +
                              "JOIN guests g ON b.guest_id = g.guest_id " +
                              "JOIN rooms r ON b.room_id = r.room_id " +
                              "JOIN payments p ON b.booking_id = p.booking_id " +
                              "WHERE b.check_in_date > ? AND b.status = 'confirmed' " +
                              "ORDER BY b.check_in_date ASC LIMIT 5";
        pstmt = conn.prepareStatement(upcomingQuery);
        pstmt.setDate(1, sqlToday);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> booking = new HashMap<>();
            booking.put("bookingId", "BK-" + rs.getString("booking_id"));
            booking.put("guestName", rs.getString("first_name") + " " + rs.getString("last_name"));
            booking.put("guestImage", rs.getString("profile_image"));
            booking.put("roomNumber", rs.getString("room_number"));
            booking.put("roomType", rs.getString("room_type"));
            booking.put("checkInDate", rs.getDate("check_in_date"));
            booking.put("checkOutDate", rs.getDate("check_out_date"));
            booking.put("paymentStatus", rs.getString("payment_status"));
            
            // Calculate nights
            long diff = rs.getDate("check_out_date").getTime() - rs.getDate("check_in_date").getTime();
            int nights = (int) (diff / (1000 * 60 * 60 * 24));
            booking.put("nights", nights);
            
            upcomingBookingsList.add(booking);
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
    <title>ZAIRTAM - Receptionist Dashboard</title>
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
                    
                    <h3 class="text-xs uppercase text-gray-500 font-semibold tracking-wider">Reception</h3>
                    <ul class="mt-3 space-y-1">
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-blue-600 bg-blue-50 rounded-md">
                                <i class="fas fa-tachometer-alt w-5 text-center"></i>
                                <span class="ml-2">Dashboard</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-calendar-check w-5 text-center"></i>
                                <span class="ml-2">Arrival History</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-credit-card w-5 text-center"></i>
                                <span class="ml-2">Payment History</span>
                            </a>
                        </li>
                    </ul>
                </div>
                
                <div class="mb-6">
                    <h3 class="text-xs uppercase text-gray-500 font-semibold tracking-wider">Hotel Management</h3>
                    <ul class="mt-3 space-y-1">
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-door-open w-5 text-center"></i>
                                <span class="ml-2">Rooms</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-users w-5 text-center"></i>
                                <span class="ml-2">Guests</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-calendar-alt w-5 text-center"></i>
                                <span class="ml-2">Bookings</span>
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
                                <span class="ml-2">Help Center</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
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
                    <h1 class="text-2xl font-bold text-gray-800">Reception Dashboard</h1>
                    <p class="text-gray-600">Manage today's arrivals and upcoming bookings</p>
                </div>
                <div class="flex space-x-3">
                    <div class="relative">
                        <span class="absolute inset-y-0 left-0 pl-3 flex items-center">
                            <i class="fas fa-search text-gray-400"></i>
                        </span>
                        <input type="text" placeholder="Search by name or booking ID" class="pl-10 pr-4 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 w-64">
                    </div>
                    <button class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg transition duration-200 flex items-center">
                        <i class="fas fa-plus mr-2"></i> New Booking
                    </button>
                </div>
            </div>
            
            <!-- Dashboard Stats -->
            <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Today's Arrivals</h3>
                        <div class="bg-blue-100 p-2 rounded-md">
                            <i class="fas fa-user-check text-blue-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= todayArrivals %></p>
                        <% int arrivalDiff = todayArrivals - yesterdayArrivals; %>
                        <p class="<%= arrivalDiff >= 0 ? "text-green-600" : "text-red-600" %> text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-<%= arrivalDiff >= 0 ? "up" : "down" %> mr-1"></i><%= Math.abs(arrivalDiff) %>
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">vs. yesterday</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Today's Departures</h3>
                        <div class="bg-purple-100 p-2 rounded-md">
                            <i class="fas fa-sign-out-alt text-purple-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= todayDepartures %></p>
                        <% int departureDiff = todayDepartures - yesterdayDepartures; %>
                        <p class="<%= departureDiff >= 0 ? "text-green-600" : "text-red-600" %> text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-<%= departureDiff >= 0 ? "up" : "down" %> mr-1"></i><%= Math.abs(departureDiff) %>
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">vs. yesterday</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Occupied Rooms</h3>
                        <div class="bg-green-100 p-2 rounded-md">
                            <i class="fas fa-bed text-green-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= occupiedRooms %></p>
                        <p class="text-gray-500 text-sm ml-2 mb-1">
                            / <%= totalRooms %>
                        </p>
                    </div>
                    <% int occupancyRate = totalRooms > 0 ? (occupiedRooms * 100 / totalRooms) : 0; %>
                    <p class="text-gray-500 text-sm mt-1"><%= occupancyRate %>% occupancy</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Pending Payments</h3>
                        <div class="bg-yellow-100 p-2 rounded-md">
                            <i class="fas fa-credit-card text-yellow-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= pendingPayments %></p>
                        <p class="text-gray-500 text-sm ml-2 mb-1">
                            €<%= String.format("%.2f", pendingAmount) %>
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">to be collected</p>
                </div>
            </div>
            
            <!-- Today's Arrivals Section -->
            <div class="bg-white rounded-lg shadow-sm mb-8">
                <div class="p-6 border-b border-gray-200">
                    <div class="flex items-center justify-between">
                        <h3 class="text-lg font-semibold text-gray-800">Today's Arrivals</h3>
                        <span class="date-badge date-today">
                            <i class="far fa-calendar-alt mr-1"></i> Today, <%= formattedDate %>
                        </span>
                    </div>
                </div>
                
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Guest
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Room
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Dates
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Payment
                                </th>
                                <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Actions
                                </th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            <% if (todayArrivalsList.isEmpty()) { %>
                                <tr>
                                    <td colspan="5" class="px-6 py-4 text-center text-gray-500">
                                        No arrivals scheduled for today
                                    </td>
                                </tr>
                            <% } else { %>
                                <% for (Map<String, Object> arrival : todayArrivalsList) { %>
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
                                            <div class="text-sm text-gray-900">Room <%= arrival.get("roomNumber") %></div>
                                            <div class="text-sm text-gray-500"><%= arrival.get("roomType") %></div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <% 
                                                SimpleDateFormat df = new SimpleDateFormat("MMM dd, yyyy");
                                                String checkIn = df.format((java.util.Date)arrival.get("checkInDate"));
                                                String checkOut = df.format((java.util.Date)arrival.get("checkOutDate"));
                                            %>
                                            <div class="text-sm text-gray-900"><%= checkIn %> - <%= checkOut %></div>
                                            <div class="text-sm text-gray-500"><%= arrival.get("nights") %> nights</div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <% 
                                                String paymentStatus = (String)arrival.get("paymentStatus");
                                                String badgeClass = "payment-unpaid";
                                                if (paymentStatus.equals("paid")) {
                                                    badgeClass = "payment-paid";
                                                } else if (paymentStatus.equals("partial")) {
                                                    badgeClass = "payment-partial";
                                                }
                                            %>
                                            <span class="payment-badge <%= badgeClass %>">
                                                <%= paymentStatus.substring(0, 1).toUpperCase() + paymentStatus.substring(1) %>
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                            <button class="bg-green-600 hover:bg-green-700 text-white px-3 py-1 rounded-md mr-2">
                                                <i class="fas fa-check-circle mr-1"></i> Mark as Arrived
                                            </button>
                                            <% if (!paymentStatus.equals("paid")) { %>
                                                <button class="bg-yellow-600 hover:bg-yellow-700 text-white px-3 py-1 rounded-md">
                                                    <i class="fas fa-euro-sign mr-1"></i> Collect Payment
                                                </button>
                                            <% } else { %>
                                                <button class="text-blue-600 hover:text-blue-900">
                                                    <i class="fas fa-ellipsis-v"></i>
                                                </button>
                                            <% } %>
                                        </td>
                                    </tr>
                                <% } %>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
            
            <!-- Upcoming Bookings Section -->
            <div class="bg-white rounded-lg shadow-sm">
                <div class="p-6 border-b border-gray-200">
                    <div class="flex items-center justify-between">
                        <h3 class="text-lg font-semibold text-gray-800">Upcoming Bookings</h3>
                        <a href="#" class="text-blue-600 hover:text-blue-800 text-sm font-medium">
                            View All <i class="fas fa-arrow-right ml-1"></i>
                        </a>
                    </div>
                </div>
                
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Guest
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Room
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Dates
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Payment
                                </th>
                                <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Actions
                                </th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            <% if (upcomingBookingsList.isEmpty()) { %>
                                <tr>
                                    <td colspan="5" class="px-6 py-4 text-center text-gray-500">
                                        No upcoming bookings found
                                    </td>
                                </tr>
                            <% } else { %>
                                <% for (Map<String, Object> booking : upcomingBookingsList) { %>
                                    <tr>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="flex items-center">
                                                <div class="flex-shrink-0 h-10 w-10">
                                                    <img class="h-10 w-10 rounded-full" src="<%= booking.get("guestImage") %>" alt="Guest">
                                                </div>
                                                <div class="ml-4">
                                                    <div class="text-sm font-medium text-gray-900"><%= booking.get("guestName") %></div>
                                                    <div class="text-sm text-gray-500"><%= booking.get("bookingId") %></div>
                                                </div>
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="text-sm text-gray-900">Room <%= booking.get("roomNumber") %></div>
                                            <div class="text-sm text-gray-500"><%= booking.get("roomType") %></div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <% 
                                                SimpleDateFormat df = new SimpleDateFormat("MMM dd, yyyy");
                                                String checkIn = df.format((java.util.Date)booking.get("checkInDate"));
                                                String checkOut = df.format((java.util.Date)booking.get("checkOutDate"));
                                            %>
                                            <div class="text-sm text-gray-900"><%= checkIn %> - <%= checkOut %></div>
                                            <div class="text-sm text-gray-500"><%= booking.get("nights") %> nights</div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <% 
                                                String paymentStatus = (String)booking.get("paymentStatus");
                                                String badgeClass = "payment-unpaid";
                                                if (paymentStatus.equals("paid")) {
                                                    badgeClass = "payment-paid";
                                                } else if (paymentStatus.equals("partial")) {
                                                    badgeClass = "payment-partial";
                                                }
                                            %>
                                            <span class="payment-badge <%= badgeClass %>">
                                                <%= paymentStatus.substring(0, 1).toUpperCase() + paymentStatus.substring(1) %>
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                            <button class="bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded-md">
                                                <i class="fas fa-eye mr-1"></i> View Details
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

    <!-- JavaScript for Dropdown Functionality -->
    <script>
        // Make dropdown menus work with hover
        document.addEventListener('DOMContentLoaded', function() {
            // Mark as Arrived functionality
            const arrivalButtons = document.querySelectorAll('.bg-green-600');
            arrivalButtons.forEach(button => {
                button.addEventListener('click', function() {
                    // Here you would normally send an AJAX request to update the booking status
                    alert('Guest marked as arrived!');
                    this.innerHTML = '<i class="fas fa-check"></i> Arrived';
                    this.classList.remove('bg-green-600', 'hover:bg-green-700');
                    this.classList.add('bg-gray-500', 'hover:bg-gray-600');
                    this.disabled = true;
                });
            });
            
            // Collect Payment functionality
            const paymentButtons = document.querySelectorAll('.bg-yellow-600');
            paymentButtons.forEach(button => {
                button.addEventListener('click', function() {
                    // Here you would normally open a payment modal
                    alert('Payment collection initiated!');
                });
            });
        });
    </script>
</body>
</html>