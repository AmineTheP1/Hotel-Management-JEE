<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
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
    
    // Lists to store data
    List<Map<String, Object>> bookingsByUserList = new ArrayList<>();
    List<Map<String, Object>> bookingsByCountryList = new ArrayList<>();
    List<Map<String, Object>> occupancyRateByHotelList = new ArrayList<>();
    List<Map<String, Object>> popularRoomTypesList = new ArrayList<>();
    
    // Statistics
    int totalUsers = 0;
    int totalHotels = 0;
    int totalRooms = 0;
    int totalBookings = 0;
    double averageOccupancyRate = 0;
    
    // Monthly data for charts
    List<Integer> monthlyBookings = new ArrayList<>(Arrays.asList(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));
    List<Double> monthlyOccupancyRates = new ArrayList<>(Arrays.asList(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0));
    List<String> months = Arrays.asList("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
    
    // Get current month and year
    Calendar cal = Calendar.getInstance();
    int currentMonth = cal.get(Calendar.MONTH);
    int currentYear = cal.get(Calendar.YEAR);
    
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
        // Get overall statistics
        String statsQuery = "SELECT " +
                           "(SELECT COUNT(*) FROM users) as total_users, " +
                           "(SELECT COUNT(*) FROM hotels) as total_hotels, " +
                           "(SELECT COUNT(*) FROM rooms) as total_rooms, " +
                           "(SELECT COUNT(*) FROM bookings) as total_bookings";
        
        pstmt = conn.prepareStatement(statsQuery);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            totalUsers = rs.getInt("total_users");
            totalHotels = rs.getInt("total_hotels");
            totalRooms = rs.getInt("total_rooms");
            totalBookings = rs.getInt("total_bookings");
        }
        
        rs.close();
        pstmt.close();
        
        // Calculate average occupancy rate
        String occupancyQuery = "SELECT AVG(occupancy_rate) as avg_occupancy " +
                               "FROM (" +
                               "    SELECT h.id, h.name, " +
                               "    (COUNT(b.id) * 100 / (SELECT COUNT(*) FROM rooms WHERE hotel_id = h.id)) AS occupancy_rate " +
                               "    FROM hotels h " +
                               "    JOIN bookings b ON h.id = b.hotel_id " +
                               "    WHERE b.status != 'cancelled' " +
                               "    GROUP BY h.id" +
                               ") as hotel_occupancy";
        
        pstmt = conn.prepareStatement(occupancyQuery);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            averageOccupancyRate = rs.getDouble("avg_occupancy");
        }
        
        rs.close();
        pstmt.close();
        
        // Get bookings by user (top users)
        String userBookingsQuery = "SELECT u.id, u.first_name, u.last_name, u.email, " +
                                  "COUNT(b.id) as booking_count, " +
                                  "SUM(b.total_amount) as total_spent " +
                                  "FROM users u " +
                                  "JOIN bookings b ON u.id = b.user_id " +
                                  "WHERE b.status != 'cancelled' " +
                                  "GROUP BY u.id " +
                                  "ORDER BY booking_count DESC " +
                                  "LIMIT 10";
        
        pstmt = conn.prepareStatement(userBookingsQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> userBookings = new HashMap<>();
            userBookings.put("user_id", rs.getInt("id"));
            userBookings.put("user_name", rs.getString("first_name") + " " + rs.getString("last_name"));
            userBookings.put("email", rs.getString("email"));
            userBookings.put("booking_count", rs.getInt("booking_count"));
            userBookings.put("total_spent", rs.getDouble("total_spent"));
            
            bookingsByUserList.add(userBookings);
        }
        
        rs.close();
        pstmt.close();
        
        // Get bookings by country
        String countryBookingsQuery = "SELECT h.country, " +
                                     "COUNT(b.id) as booking_count, " +
                                     "SUM(b.total_amount) as total_revenue " +
                                     "FROM hotels h " +
                                     "JOIN bookings b ON h.id = b.hotel_id " +
                                     "WHERE b.status != 'cancelled' " +
                                     "GROUP BY h.country " +
                                     "ORDER BY booking_count DESC";
        
        pstmt = conn.prepareStatement(countryBookingsQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> countryBookings = new HashMap<>();
            countryBookings.put("country", rs.getString("country"));
            countryBookings.put("booking_count", rs.getInt("booking_count"));
            countryBookings.put("total_revenue", rs.getDouble("total_revenue"));
            
            bookingsByCountryList.add(countryBookings);
        }
        
        rs.close();
        pstmt.close();
        
        // Get occupancy rate by hotel
        String hotelOccupancyQuery = "SELECT h.id, h.name, h.city, h.country, " +
                                    "COUNT(b.id) as booking_count, " +
                                    "(COUNT(b.id) * 100 / (SELECT COUNT(*) FROM rooms WHERE hotel_id = h.id)) AS occupancy_rate " +
                                    "FROM hotels h " +
                                    "JOIN bookings b ON h.id = b.hotel_id " +
                                    "WHERE b.status != 'cancelled' " +
                                    "GROUP BY h.id " +
                                    "ORDER BY occupancy_rate DESC " +
                                    "LIMIT 10";
        
        pstmt = conn.prepareStatement(hotelOccupancyQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> hotelOccupancy = new HashMap<>();
            hotelOccupancy.put("hotel_name", rs.getString("name"));
            hotelOccupancy.put("location", rs.getString("city") + ", " + rs.getString("country"));
            hotelOccupancy.put("booking_count", rs.getInt("booking_count"));
            hotelOccupancy.put("occupancy_rate", rs.getDouble("occupancy_rate"));
            
            occupancyRateByHotelList.add(hotelOccupancy);
        }
        
        rs.close();
        pstmt.close();
        
        // Get popular room types
        String roomTypesQuery = "SELECT r.room_type, " +
                               "COUNT(b.id) as booking_count, " +
                               "AVG(r.price) as avg_price, " +
                               "(COUNT(b.id) * 100 / (SELECT COUNT(*) FROM bookings)) as popularity_percentage " +
                               "FROM rooms r " +
                               "JOIN bookings b ON r.id = b.room_id " +
                               "WHERE b.status != 'cancelled' " +
                               "GROUP BY r.room_type " +
                               "ORDER BY booking_count DESC";
        
        pstmt = conn.prepareStatement(roomTypesQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> roomType = new HashMap<>();
            roomType.put("room_type", rs.getString("room_type"));
            roomType.put("booking_count", rs.getInt("booking_count"));
            roomType.put("avg_price", rs.getDouble("avg_price"));
            roomType.put("popularity_percentage", rs.getDouble("popularity_percentage"));
            
            popularRoomTypesList.add(roomType);
        }
        
        rs.close();
        pstmt.close();
        
        // Get monthly bookings data for the current year
        String monthlyDataQuery = "SELECT MONTH(booking_date) as month, " +
                                 "COUNT(*) as booking_count " +
                                 "FROM bookings " +
                                 "WHERE YEAR(booking_date) = ? " +
                                 "AND status != 'cancelled' " +
                                 "GROUP BY MONTH(booking_date) " +
                                 "ORDER BY month";
        
        pstmt = conn.prepareStatement(monthlyDataQuery);
        pstmt.setInt(1, currentYear);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            int month = rs.getInt("month") - 1; // 0-based index
            int bookingCount = rs.getInt("booking_count");
            monthlyBookings.set(month, bookingCount);
        }
        
        rs.close();
        pstmt.close();
        
        // Get monthly occupancy rates for the current year
        String monthlyOccupancyQuery = "SELECT MONTH(b.booking_date) as month, " +
                                      "(COUNT(b.id) * 100 / (SELECT COUNT(*) FROM rooms)) as occupancy_rate " +
                                      "FROM bookings b " +
                                      "WHERE YEAR(b.booking_date) = ? " +
                                      "AND b.status != 'cancelled' " +
                                      "GROUP BY MONTH(b.booking_date) " +
                                      "ORDER BY month";
        
        pstmt = conn.prepareStatement(monthlyOccupancyQuery);
        pstmt.setInt(1, currentYear);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            int month = rs.getInt("month") - 1; // 0-based index
            double occupancyRate = rs.getDouble("occupancy_rate");
            monthlyOccupancyRates.set(month, occupancyRate);
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
    
    // Convert data to JSON for charts
    StringBuilder monthlyBookingsJson = new StringBuilder("[");
    for (Integer count : monthlyBookings) {
        monthlyBookingsJson.append(count).append(",");
    }
    if (monthlyBookingsJson.charAt(monthlyBookingsJson.length() - 1) == ',') {
        monthlyBookingsJson.setLength(monthlyBookingsJson.length() - 1);
    }
    monthlyBookingsJson.append("]");
    
    StringBuilder monthlyOccupancyJson = new StringBuilder("[");
    for (Double rate : monthlyOccupancyRates) {
        monthlyOccupancyJson.append(rate).append(",");
    }
    if (monthlyOccupancyJson.charAt(monthlyOccupancyJson.length() - 1) == ',') {
        monthlyOccupancyJson.setLength(monthlyOccupancyJson.length() - 1);
    }
    monthlyOccupancyJson.append("]");
    
    // Country data for charts
    StringBuilder countriesJson = new StringBuilder("[");
    StringBuilder countryBookingsJson = new StringBuilder("[");
    
    for (Map<String, Object> country : bookingsByCountryList) {
        countriesJson.append("\"").append(country.get("country")).append("\",");
        countryBookingsJson.append(country.get("booking_count")).append(",");
    }
    
    if (countriesJson.charAt(countriesJson.length() - 1) == ',') {
        countriesJson.setLength(countriesJson.length() - 1);
    }
    countriesJson.append("]");
    
    if (countryBookingsJson.charAt(countryBookingsJson.length() - 1) == ',') {
        countryBookingsJson.setLength(countryBookingsJson.length() - 1);
    }
    countryBookingsJson.append("]");
    
    // Room type data for charts
    StringBuilder roomTypesJson = new StringBuilder("[");
    StringBuilder roomTypePopularityJson = new StringBuilder("[");
    
    for (Map<String, Object> roomType : popularRoomTypesList) {
        roomTypesJson.append("\"").append(roomType.get("room_type")).append("\",");
        roomTypePopularityJson.append(roomType.get("popularity_percentage")).append(",");
    }
    
    if (roomTypesJson.charAt(roomTypesJson.length() - 1) == ',') {
        roomTypesJson.setLength(roomTypesJson.length() - 1);
    }
    roomTypesJson.append("]");
    
    if (roomTypePopularityJson.charAt(roomTypePopularityJson.length() - 1) == ',') {
        roomTypePopularityJson.setLength(roomTypePopularityJson.length() - 1);
    }
    roomTypePopularityJson.append("]");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZAIRTAM - Statistics Analytics</title>
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
                            <a href="#" class="flex items-center px-3 py-2 text-blue-600 bg-blue-50 rounded-md">
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
        <main class="flex-1 p-4 sm:p-6 lg:p-8">
            <div class="mb-6">
                <h1 class="text-2xl font-bold text-gray-900">Statistics Analytics</h1>
                <p class="text-gray-600">Comprehensive statistics and analytics about hotels, bookings, and users.</p>
            </div>
            
            <!-- Stats Overview Cards -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                <!-- Total Users Card -->
                <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Total Users</h3>
                        <span class="bg-blue-100 text-blue-800 text-xs font-semibold px-2.5 py-0.5 rounded-full">Users</span>
                    </div>
                    <div class="flex items-center">
                        <div class="flex-shrink-0 bg-blue-100 rounded-full p-3">
                            <i class="fas fa-users text-blue-600 text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <h2 class="text-3xl font-bold text-gray-900"><%= totalUsers %></h2>
                            <p class="text-gray-500 text-sm">Registered users</p>
                        </div>
                    </div>
                </div>
                
                <!-- Total Hotels Card -->
                <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Total Hotels</h3>
                        <span class="bg-green-100 text-green-800 text-xs font-semibold px-2.5 py-0.5 rounded-full">Properties</span>
                    </div>
                    <div class="flex items-center">
                        <div class="flex-shrink-0 bg-green-100 rounded-full p-3">
                            <i class="fas fa-hotel text-green-600 text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <h2 class="text-3xl font-bold text-gray-900"><%= totalHotels %></h2>
                            <p class="text-gray-500 text-sm">Active hotels</p>
                        </div>
                    </div>
                </div>
                
                <!-- Total Bookings Card -->
                <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Total Bookings</h3>
                        <span class="bg-purple-100 text-purple-800 text-xs font-semibold px-2.5 py-0.5 rounded-full">Reservations</span>
                    </div>
                    <div class="flex items-center">
                        <div class="flex-shrink-0 bg-purple-100 rounded-full p-3">
                            <i class="fas fa-calendar-check text-purple-600 text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <h2 class="text-3xl font-bold text-gray-900"><%= totalBookings %></h2>
                            <p class="text-gray-500 text-sm">Total reservations</p>
                        </div>
                    </div>
                </div>
                
                <!-- Average Occupancy Rate Card -->
                <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Occupancy Rate</h3>
                        <span class="bg-amber-100 text-amber-800 text-xs font-semibold px-2.5 py-0.5 rounded-full">Utilization</span>
                    </div>
                    <div class="flex items-center">
                        <div class="flex-shrink-0 bg-amber-100 rounded-full p-3">
                            <i class="fas fa-bed text-amber-600 text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <h2 class="text-3xl font-bold text-gray-900"><%= String.format("%.1f%%", averageOccupancyRate) %></h2>
                            <p class="text-gray-500 text-sm">Average occupancy</p>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Charts Section -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
                <!-- Monthly Bookings Chart -->
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <h3 class="text-lg font-semibold text-gray-800 mb-4">Monthly Bookings</h3>
                    <div class="chart-container">
                        <canvas id="bookingsChart"></canvas>
                    </div>
                </div>
                
                <!-- Monthly Occupancy Rate Chart -->
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <h3 class="text-lg font-semibold text-gray-800 mb-4">Monthly Occupancy Rate</h3>
                    <div class="chart-container">
                        <canvas id="occupancyChart"></canvas>
                    </div>
                </div>
                
                <!-- Bookings by Country Chart -->
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <h3 class="text-lg font-semibold text-gray-800 mb-4">Bookings by Country</h3>
                    <div class="chart-container">
                        <canvas id="countryChart"></canvas>
                    </div>
                </div>
                
                <!-- Room Type Popularity Chart -->
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <h3 class="text-lg font-semibold text-gray-800 mb-4">Room Type Popularity</h3>
                    <div class="chart-container">
                        <canvas id="roomTypeChart"></canvas>
                    </div>
                </div>
            </div>
            
            <!-- Top Users Table -->
            <div class="bg-white rounded-lg shadow-sm overflow-hidden mb-8">
                <div class="p-6 border-b">
                    <h3 class="text-lg font-semibold text-gray-800">Top Users by Bookings</h3>
                </div>
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    User
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Email
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Bookings
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Total Spent
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Avg. Booking Value
                                </th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            <% for (Map<String, Object> user : bookingsByUserList) { 
                                double totalSpent = (Double)user.get("total_spent");
                                int bookingCount = (Integer)user.get("booking_count");
                                double avgBookingValue = totalSpent / bookingCount;
                            %>
                            <tr>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm font-medium text-gray-900"><%= user.get("user_name") %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm text-gray-500"><%= user.get("email") %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm text-gray-900"><%= user.get("booking_count") %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm font-medium text-gray-900">$<%= String.format("%,.2f", totalSpent) %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm text-gray-900">$<%= String.format("%,.2f", avgBookingValue) %></div>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
            
            <!-- Hotel Occupancy Rates -->
            <div class="bg-white rounded-lg shadow-sm overflow-hidden mb-8">
                <div class="p-6 border-b">
                    <h3 class="text-lg font-semibold text-gray-800">Hotel Occupancy Rates</h3>
                </div>
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Hotel
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Location
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Bookings
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Occupancy Rate
                                </th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            <% for (Map<String, Object> hotel : occupancyRateByHotelList) { %>
                            <tr>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm font-medium text-gray-900"><%= hotel.get("hotel_name") %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm text-gray-500"><%= hotel.get("location") %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm text-gray-900"><%= hotel.get("booking_count") %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="flex items-center">
                                        <div class="w-full bg-gray-200 rounded-full h-2 mr-2 max-w-[100px]">
                                            <div class="bg-blue-600 h-2 rounded-full" style="width: <%= hotel.get("occupancy_rate") %>%;"></div>
                                        </div>
                                        <span class="text-sm text-gray-500"><%= String.format("%.1f", (Double)hotel.get("occupancy_rate")) %>%</span>
                                    </div>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
            
            <!-- Popular Room Types -->
            <div class="bg-white rounded-lg shadow-sm overflow-hidden mb-8">
                <div class="p-6 border-b">
                    <h3 class="text-lg font-semibold text-gray-800">Popular Room Types</h3>
                </div>
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Room Type
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Bookings
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Average Price
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Popularity
                                </th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            <% for (Map<String, Object> roomType : popularRoomTypesList) { %>
                            <tr>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm font-medium text-gray-900"><%= roomType.get("room_type") %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm text-gray-900"><%= roomType.get("booking_count") %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm font-medium text-gray-900">$<%= String.format("%,.2f", (Double)roomType.get("avg_price")) %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="flex items-center">
                                        <div class="w-full bg-gray-200 rounded-full h-2 mr-2 max-w-[100px]">
                                            <div class="bg-blue-600 h-2 rounded-full" style="width: <%= roomType.get("popularity_percentage") %>%;"></div>
                                        </div>
                                        <span class="text-sm text-gray-500"><%= String.format("%.1f", (Double)roomType.get("popularity_percentage")) %>%</span>
                                    </div>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </main>
    </div>
    
    <!-- JavaScript for Charts -->
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
        
        // Chart.js Configuration
        document.addEventListener('DOMContentLoaded', function() {
            // Monthly Bookings Chart
            const bookingsCtx = document.getElementById('bookingsChart').getContext('2d');
            const bookingsChart = new Chart(bookingsCtx, {
                type: 'bar',
                data: {
                    labels: <%= Arrays.toString(months.toArray()) %>,
                    datasets: [{
                        label: 'Bookings',
                        data: <%= monthlyBookingsJson.toString() %>,
                        backgroundColor: 'rgba(59, 130, 246, 0.7)',
                        borderRadius: 4
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            display: false
                        }
                    },
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
            
            // Monthly Occupancy Rate Chart
            const occupancyCtx = document.getElementById('occupancyChart').getContext('2d');
            const occupancyChart = new Chart(occupancyCtx, {
                type: 'line',
                data: {
                    labels: <%= Arrays.toString(months.toArray()) %>,
                    datasets: [{
                        label: 'Occupancy Rate (%)',
                        data: <%= monthlyOccupancyJson.toString() %>,
                        backgroundColor: 'rgba(16, 185, 129, 0.1)',
                        borderColor: 'rgba(16, 185, 129, 1)',
                        borderWidth: 2,
                        tension: 0.3,
                        fill: true
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            display: false
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            max: 100,
                            ticks: {
                                callback: function(value) {
                                    return value + '%';
                                }
                            }
                        }
                    }
                }
            });
            
            // Bookings by Country Chart
            const countryCtx = document.getElementById('countryChart').getContext('2d');
            const countryChart = new Chart(countryCtx, {
                type: 'bar',
                data: {
                    labels: <%= countriesJson.toString() %>,
                    datasets: [{
                        label: 'Bookings',
                        data: <%= countryBookingsJson.toString() %>,
                        backgroundColor: [
                            'rgba(59, 130, 246, 0.7)',
                            'rgba(16, 185, 129, 0.7)',
                            'rgba(245, 158, 11, 0.7)',
                            'rgba(239, 68, 68, 0.7)',
                            'rgba(139, 92, 246, 0.7)',
                            'rgba(236, 72, 153, 0.7)',
                            'rgba(6, 182, 212, 0.7)',
                            'rgba(249, 115, 22, 0.7)',
                            'rgba(168, 85, 247, 0.7)',
                            'rgba(234, 179, 8, 0.7)'
                        ],
                        borderRadius: 4
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    indexAxis: 'y',
                    plugins: {
                        legend: {
                            display: false
                        }
                    },
                    scales: {
                        x: {
                            beginAtZero: true,
                            ticks: {
                                precision: 0
                            }
                        }
                    }
                }
            });
            
            // Room Type Popularity Chart
            const roomTypeCtx = document.getElementById('roomTypeChart').getContext('2d');
            const roomTypeChart = new Chart(roomTypeCtx, {
                type: 'pie',
                data: {
                    labels: <%= roomTypesJson.toString() %>,
                    datasets: [{
                        data: <%= roomTypePopularityJson.toString() %>,
                        backgroundColor: [
                            'rgba(59, 130, 246, 0.7)',
                            'rgba(16, 185, 129, 0.7)',
                            'rgba(245, 158, 11, 0.7)',
                            'rgba(239, 68, 68, 0.7)',
                            'rgba(139, 92, 246, 0.7)',
                            'rgba(236, 72, 153, 0.7)'
                        ],
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'right'
                        },
                        tooltip: {
                            callbacks: {
                                label: function(context) {
                                    const value = context.raw;
                                    return context.label + ': ' + value.toFixed(1) + '%';
                                }
                            }
                        }
                    }
                }
            });
        });
    </script>
</body>
</html>