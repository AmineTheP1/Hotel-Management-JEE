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
    List<Map<String, Object>> revenueByHotelList = new ArrayList<>();
    List<Map<String, Object>> revenueByMonthList = new ArrayList<>();
    List<Map<String, Object>> revenueByRoomTypeList = new ArrayList<>();
    List<Map<String, Object>> topRevenueBookingsList = new ArrayList<>();
    
    // Statistics
    double totalRevenue = 0;
    double revenueThisMonth = 0;
    double revenueLastMonth = 0;
    double averageBookingValue = 0;
    double revenueGrowthRate = 0;
    
    // Monthly data for charts
    List<Double> monthlyRevenue = new ArrayList<>(Arrays.asList(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0));
    List<String> months = Arrays.asList("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
    
    // Get current month and year
    Calendar cal = Calendar.getInstance();
    int currentMonth = cal.get(Calendar.MONTH);
    int currentYear = cal.get(Calendar.YEAR);
    
    // Get last month
    cal.add(Calendar.MONTH, -1);
    int lastMonth = cal.get(Calendar.MONTH);
    int lastMonthYear = cal.get(Calendar.YEAR);
    
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
        // Get overall revenue statistics
        String statsQuery = "SELECT " +
                           "SUM(total_amount) as total_revenue, " +
                           "AVG(total_amount) as avg_booking_value " +
                           "FROM bookings " +
                           "WHERE status != 'cancelled'";
        
        pstmt = conn.prepareStatement(statsQuery);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            totalRevenue = rs.getDouble("total_revenue");
            averageBookingValue = rs.getDouble("avg_booking_value");
        }
        
        rs.close();
        pstmt.close();
        
        // Get current month revenue
        String currentMonthQuery = "SELECT SUM(total_amount) as revenue " +
                                  "FROM bookings " +
                                  "WHERE MONTH(booking_date) = ? " +
                                  "AND YEAR(booking_date) = ? " +
                                  "AND status != 'cancelled'";
        
        pstmt = conn.prepareStatement(currentMonthQuery);
        pstmt.setInt(1, currentMonth + 1); // JDBC months are 1-based
        pstmt.setInt(2, currentYear);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            revenueThisMonth = rs.getDouble("revenue");
        }
        
        rs.close();
        pstmt.close();
        
        // Get last month revenue
        String lastMonthQuery = "SELECT SUM(total_amount) as revenue " +
                               "FROM bookings " +
                               "WHERE MONTH(booking_date) = ? " +
                               "AND YEAR(booking_date) = ? " +
                               "AND status != 'cancelled'";
        
        pstmt = conn.prepareStatement(lastMonthQuery);
        pstmt.setInt(1, lastMonth + 1); // JDBC months are 1-based
        pstmt.setInt(2, lastMonthYear);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            revenueLastMonth = rs.getDouble("revenue");
        }
        
        rs.close();
        pstmt.close();
        
        // Calculate growth rate
        if (revenueLastMonth > 0) {
            revenueGrowthRate = ((revenueThisMonth - revenueLastMonth) / revenueLastMonth) * 100;
        }
        
        // Get revenue by hotel
        String revenueByHotelQuery = "SELECT h.name as hotel_name, h.city, h.country, " +
                                    "COUNT(b.id) as booking_count, " +
                                    "SUM(b.total_amount) as total_revenue, " +
                                    "AVG(b.total_amount) as avg_booking_value " +
                                    "FROM hotels h " +
                                    "JOIN bookings b ON h.id = b.hotel_id " +
                                    "WHERE b.status != 'cancelled' " +
                                    "GROUP BY h.id " +
                                    "ORDER BY total_revenue DESC " +
                                    "LIMIT 10";
        
        pstmt = conn.prepareStatement(revenueByHotelQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> hotelRevenue = new HashMap<>();
            hotelRevenue.put("hotel_name", rs.getString("hotel_name"));
            hotelRevenue.put("location", rs.getString("city") + ", " + rs.getString("country"));
            hotelRevenue.put("booking_count", rs.getInt("booking_count"));
            hotelRevenue.put("total_revenue", rs.getDouble("total_revenue"));
            hotelRevenue.put("avg_booking_value", rs.getDouble("avg_booking_value"));
            
            revenueByHotelList.add(hotelRevenue);
        }
        
        rs.close();
        pstmt.close();
        
        // Get monthly revenue data for the current year
        String monthlyDataQuery = "SELECT MONTH(booking_date) as month, " +
                                 "SUM(total_amount) as revenue " +
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
            double revenue = rs.getDouble("revenue");
            monthlyRevenue.set(month, revenue);
            
            Map<String, Object> monthData = new HashMap<>();
            monthData.put("month", months.get(month));
            monthData.put("revenue", revenue);
            
            revenueByMonthList.add(monthData);
        }
        
        rs.close();
        pstmt.close();
        
        // Get revenue by room type
        String roomTypeQuery = "SELECT r.room_type, " +
                              "COUNT(b.id) as booking_count, " +
                              "SUM(b.total_amount) as total_revenue, " +
                              "AVG(b.total_amount) as avg_revenue " +
                              "FROM rooms r " +
                              "JOIN bookings b ON r.id = b.room_id " +
                              "WHERE b.status != 'cancelled' " +
                              "GROUP BY r.room_type " +
                              "ORDER BY total_revenue DESC";
        
        pstmt = conn.prepareStatement(roomTypeQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> roomTypeRevenue = new HashMap<>();
            roomTypeRevenue.put("room_type", rs.getString("room_type"));
            roomTypeRevenue.put("booking_count", rs.getInt("booking_count"));
            roomTypeRevenue.put("total_revenue", rs.getDouble("total_revenue"));
            roomTypeRevenue.put("avg_revenue", rs.getDouble("avg_revenue"));
            
            revenueByRoomTypeList.add(roomTypeRevenue);
        }
        
        rs.close();
        pstmt.close();
        
        // Get top revenue bookings
        String topBookingsQuery = "SELECT b.id, b.booking_date, b.total_amount, b.status, " +
                                 "u.first_name, u.last_name, u.email, " +
                                 "h.name as hotel_name, r.room_type " +
                                 "FROM bookings b " +
                                 "JOIN users u ON b.user_id = u.id " +
                                 "JOIN hotels h ON b.hotel_id = h.id " +
                                 "JOIN rooms r ON b.room_id = r.id " +
                                 "WHERE b.status != 'cancelled' " +
                                 "ORDER BY b.total_amount DESC LIMIT 5";
        
        pstmt = conn.prepareStatement(topBookingsQuery);
        rs = pstmt.executeQuery();
        
        SimpleDateFormat dateFormat = new SimpleDateFormat("MMM dd, yyyy");
        
        while (rs.next()) {
            Map<String, Object> booking = new HashMap<>();
            
            booking.put("id", rs.getString("id"));
            booking.put("booking_id", "BK-" + rs.getString("id"));
            booking.put("booking_date", dateFormat.format(rs.getDate("booking_date")));
            booking.put("guest_name", rs.getString("first_name") + " " + rs.getString("last_name"));
            booking.put("guest_email", rs.getString("email"));
            booking.put("hotel_name", rs.getString("hotel_name"));
            booking.put("room_type", rs.getString("room_type"));
            booking.put("amount", rs.getDouble("total_amount"));
            booking.put("status", rs.getString("status"));
            
            topRevenueBookingsList.add(booking);
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
    StringBuilder monthlyRevenueJson = new StringBuilder("[");
    for (Double revenue : monthlyRevenue) {
        monthlyRevenueJson.append(revenue).append(",");
    }
    if (monthlyRevenueJson.charAt(monthlyRevenueJson.length() - 1) == ',') {
        monthlyRevenueJson.setLength(monthlyRevenueJson.length() - 1);
    }
    monthlyRevenueJson.append("]");
    
    StringBuilder hotelNamesJson = new StringBuilder("[");
    StringBuilder hotelRevenueJson = new StringBuilder("[");
    
    for (Map<String, Object> hotel : revenueByHotelList) {
        hotelNamesJson.append("\"").append(hotel.get("hotel_name")).append("\",");
        hotelRevenueJson.append(hotel.get("total_revenue")).append(",");
    }
    
    if (hotelNamesJson.charAt(hotelNamesJson.length() - 1) == ',') {
        hotelNamesJson.setLength(hotelNamesJson.length() - 1);
    }
    hotelNamesJson.append("]");
    
    if (hotelRevenueJson.charAt(hotelRevenueJson.length() - 1) == ',') {
        hotelRevenueJson.setLength(hotelRevenueJson.length() - 1);
    }
    hotelRevenueJson.append("]");
    
    // Room type data for charts
    StringBuilder roomTypesJson = new StringBuilder("[");
    StringBuilder roomTypeRevenueJson = new StringBuilder("[");
    
    for (Map<String, Object> roomType : revenueByRoomTypeList) {
        roomTypesJson.append("\"").append(roomType.get("room_type")).append("\",");
        roomTypeRevenueJson.append(roomType.get("total_revenue")).append(",");
    }
    
    if (roomTypesJson.charAt(roomTypesJson.length() - 1) == ',') {
        roomTypesJson.setLength(roomTypesJson.length() - 1);
    }
    roomTypesJson.append("]");
    
    if (roomTypeRevenueJson.charAt(roomTypeRevenueJson.length() - 1) == ',') {
        roomTypeRevenueJson.setLength(roomTypeRevenueJson.length() - 1);
    }
    roomTypeRevenueJson.append("]");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZAIRTAM - Revenue Analytics</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
        }
        
        .revenue-card {
            transition: all 0.3s ease;
        }
        
        .revenue-card:hover {
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
        
        .status-confirmed {
            background-color: #D1FAE5;
            color: #065F46;
        }
        
        .status-pending {
            background-color: #FEF3C7;
            color: #92400E;
        }
        
        .status-cancelled {
            background-color: #FEE2E2;
            color: #B91C1C;
        }
        
        .status-completed {
            background-color: #E0E7FF;
            color: #3730A3;
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
                            <a href="#" class="flex items-center px-3 py-2 text-blue-600 bg-blue-50 rounded-md">
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
            <div class="flex justify-between items-center mb-6">
                <h1 class="text-2xl font-bold text-gray-900">Revenue Analytics</h1>
                
                <div class="flex space-x-2">
                    <div class="relative">
                        <select class="appearance-none bg-white border rounded-lg px-4 py-2 pr-8 focus:outline-none focus:ring-2 focus:ring-blue-500">
                            <option>Last 30 Days</option>
                            <option>Last 90 Days</option>
                            <option>This Year</option>
                            <option>Last Year</option>
                            <option>All Time</option>
                        </select>
                        <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-gray-700">
                            <i class="fas fa-chevron-down text-xs"></i>
                        </div>
                    </div>
                    
                    <button class="bg-white border rounded-lg px-4 py-2 text-gray-700 hover:bg-gray-50">
                        <i class="fas fa-download mr-2"></i>
                        Export
                    </button>
                </div>
            </div>
            
            <!-- Revenue Overview Cards -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
                <div class="bg-white rounded-lg shadow-sm p-6 revenue-card">
                    <div class="flex justify-between items-start">
                        <div>
                            <p class="text-sm text-gray-500 mb-1">Total Revenue</p>
                            <h3 class="text-2xl font-bold text-gray-900">$<%= String.format("%,.2f", totalRevenue) %></h3>
                            <p class="text-xs text-gray-500 mt-1">All time</p>
                        </div>
                        <div class="bg-blue-100 p-3 rounded-full">
                            <i class="fas fa-dollar-sign text-blue-600"></i>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6 revenue-card">
                    <div class="flex justify-between items-start">
                        <div>
                            <p class="text-sm text-gray-500 mb-1">This Month</p>
                            <h3 class="text-2xl font-bold text-gray-900">$<%= String.format("%,.2f", revenueThisMonth) %></h3>
                            <p class="flex items-center text-xs mt-1 <%= revenueGrowthRate >= 0 ? "text-green-600" : "text-red-600" %>">
                                <i class="fas fa-<%= revenueGrowthRate >= 0 ? "arrow-up" : "arrow-down" %> mr-1"></i>
                                <%= String.format("%.1f", Math.abs(revenueGrowthRate)) %>% from last month
                            </p>
                        </div>
                        <div class="bg-green-100 p-3 rounded-full">
                            <i class="fas fa-chart-line text-green-600"></i>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6 revenue-card">
                    <div class="flex justify-between items-start">
                        <div>
                            <p class="text-sm text-gray-500 mb-1">Average Booking</p>
                            <h3 class="text-2xl font-bold text-gray-900">$<%= String.format("%,.2f", averageBookingValue) %></h3>
                            <p class="text-xs text-gray-500 mt-1">Per reservation</p>
                        </div>
                        <div class="bg-purple-100 p-3 rounded-full">
                            <i class="fas fa-receipt text-purple-600"></i>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6 revenue-card">
                    <div class="flex justify-between items-start">
                        <div>
                            <p class="text-sm text-gray-500 mb-1">Projected Revenue</p>
                            <h3 class="text-2xl font-bold text-gray-900">$<%= String.format("%,.2f", revenueThisMonth * 1.1) %></h3>
                            <p class="text-xs text-gray-500 mt-1">Next month (estimated)</p>
                        </div>
                        <div class="bg-yellow-100 p-3 rounded-full">
                            <i class="fas fa-chart-pie text-yellow-600"></i>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Charts Section -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
                <!-- Monthly Revenue Chart -->
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex justify-between items-center mb-4">
                        <h3 class="font-semibold text-gray-900">Monthly Revenue</h3>
                        <div class="flex space-x-2">
                            <button class="text-xs text-gray-500 hover:text-blue-600 px-2 py-1 rounded">
                                This Year
                            </button>
                            <button class="text-xs text-gray-500 hover:text-blue-600 px-2 py-1 rounded">
                                Last Year
                            </button>
                        </div>
                    </div>
                    <div class="chart-container">
                        <canvas id="revenueChart"></canvas>
                    </div>
                </div>
                
                <!-- Revenue by Hotel Chart -->
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex justify-between items-center mb-4">
                        <h3 class="font-semibold text-gray-900">Revenue by Hotel</h3>
                        <div class="flex space-x-2">
                            <button class="text-xs text-gray-500 hover:text-blue-600 px-2 py-1 rounded">
                                Top 5
                            </button>
                            <button class="text-xs text-gray-500 hover:text-blue-600 px-2 py-1 rounded">
                                Top 10
                            </button>
                            <button class="text-xs bg-blue-100 text-blue-600 px-2 py-1 rounded">
                                All
                            </button>
                        </div>
                    </div>
                    <div class="chart-container">
                        <canvas id="hotelRevenueChart"></canvas>
                    </div>
                </div>
                
                <!-- Revenue by Room Type -->
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex justify-between items-center mb-4">
                        <h3 class="font-semibold text-gray-900">Revenue by Room Type</h3>
                        <div class="flex space-x-2">
                            <button class="text-xs bg-blue-100 text-blue-600 px-2 py-1 rounded">
                                Pie Chart
                            </button>
                            <button class="text-xs text-gray-500 hover:text-blue-600 px-2 py-1 rounded">
                                Bar Chart
                            </button>
                        </div>
                    </div>
                    <div class="chart-container">
                        <canvas id="roomTypeChart"></canvas>
                    </div>
                </div>
            </div>
            
            <!-- Revenue Breakdown Table -->
            <div class="bg-white rounded-lg shadow-sm overflow-hidden mb-8">
                <div class="p-6 border-b">
                    <h3 class="text-lg font-semibold text-gray-800">Revenue Breakdown</h3>
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
                                    Total Revenue
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Avg. Booking Value
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    % of Total
                                </th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            <% 
                            for (Map<String, Object> hotel : revenueByHotelList) {
                                double hotelRevenue = (Double)hotel.get("total_revenue");
                                double percentOfTotal = (hotelRevenue / totalRevenue) * 100;
                            %>
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
                                    <div class="text-sm font-medium text-gray-900">$<%= String.format("%,.2f", hotelRevenue) %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm text-gray-900">$<%= String.format("%,.2f", (Double)hotel.get("avg_booking_value")) %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="flex items-center">
                                        <div class="w-full bg-gray-200 rounded-full h-2 mr-2 max-w-[100px]">
                                            <div class="bg-blue-600 h-2 rounded-full" style="width: <%= percentOfTotal %>%;"></div>
                                        </div>
                                        <span class="text-sm text-gray-500"><%= String.format("%.1f", percentOfTotal) %>%</span>
                                    </div>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
            
            <!-- Top Revenue Bookings -->
            <div class="bg-white rounded-lg shadow-sm overflow-hidden mb-8">
                <div class="p-6 border-b flex justify-between items-center">
                    <h3 class="text-lg font-semibold text-gray-800">Top Revenue Bookings</h3>
                    <a href="bookings.jsp" class="text-blue-600 hover:text-blue-800 text-sm font-medium">View All Bookings</a>
                </div>
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Booking ID
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Guest
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Hotel
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Room Type
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Amount
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Status
                                </th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            <% for (Map<String, Object> booking : topRevenueBookingsList) { %>
                            <tr>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm font-medium text-gray-900"><%= booking.get("booking_id") %></div>
                                    <div class="text-xs text-gray-500"><%= booking.get("booking_date") %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm font-medium text-gray-900"><%= booking.get("guest_name") %></div>
                                    <div class="text-xs text-gray-500"><%= booking.get("guest_email") %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm text-gray-900"><%= booking.get("hotel_name") %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm text-gray-900"><%= booking.get("room_type") %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm font-medium text-gray-900">$<%= String.format("%,.2f", (Double)booking.get("amount")) %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <% 
                                    String statusClass = "";
                                    String status = (String)booking.get("status");
                                    
                                    if (status.equalsIgnoreCase("confirmed")) {
                                        statusClass = "status-confirmed";
                                    } else if (status.equalsIgnoreCase("pending")) {
                                        statusClass = "status-pending";
                                    } else if (status.equalsIgnoreCase("cancelled")) {
                                        statusClass = "status-cancelled";
                                    } else if (status.equalsIgnoreCase("completed")) {
                                        statusClass = "status-completed";
                                    }
                                    %>
                                    <span class="status-badge <%= statusClass %>">
                                        <%= status.substring(0, 1).toUpperCase() + status.substring(1) %>
                                    </span>
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
            // Monthly Revenue Chart
            const revenueCtx = document.getElementById('revenueChart').getContext('2d');
            const revenueChart = new Chart(revenueCtx, {
                type: 'line',
                data: {
                    labels: <%= Arrays.toString(months.toArray()) %>,
                    datasets: [{
                        label: 'Revenue ($)',
                        data: <%= monthlyRevenueJson.toString() %>,
                        backgroundColor: 'rgba(59, 130, 246, 0.1)',
                        borderColor: 'rgba(59, 130, 246, 1)',
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
                            ticks: {
                                callback: function(value) {
                                    return '$' + value.toLocaleString();
                                }
                            }
                        }
                    }
                }
            });
            
            // Hotel Revenue Chart
            const hotelRevenueCtx = document.getElementById('hotelRevenueChart').getContext('2d');
            const hotelRevenueChart = new Chart(hotelRevenueCtx, {
                type: 'bar',
                data: {
                    labels: <%= hotelNamesJson.toString() %>,
                    datasets: [{
                        label: 'Revenue ($)',
                        data: <%= hotelRevenueJson.toString() %>,
                        backgroundColor: 'rgba(59, 130, 246, 0.7)',
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
                                callback: function(value) {
                                    return '$' + value.toLocaleString();
                                }
                            }
                        }
                    }
                }
            });
            
            // Room Type Revenue Chart
            const roomTypeCtx = document.getElementById('roomTypeChart').getContext('2d');
            const roomTypeChart = new Chart(roomTypeCtx, {
                type: 'pie',
                data: {
                    labels: <%= roomTypesJson.toString() %>,
                    datasets: [{
                        data: <%= roomTypeRevenueJson.toString() %>,
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
                                    const total = context.dataset.data.reduce((a, b) => a + b, 0);
                                    const percentage = ((value / total) * 100).toFixed(1);
                                    return `$${value.toLocaleString()} (${percentage}%)`;
                                }
                            }
                        }
                    }
                }
            });
            
            // Filter buttons functionality
            const topFiveBtn = document.querySelector('button:contains("Top 5")');
            const topTenBtn = document.querySelector('button:contains("Top 10")');
            const allBtn = document.querySelector('button:contains("All")');
            
            if (topFiveBtn && topTenBtn && allBtn) {
                // Implementation would filter the data and update charts
                // This is a placeholder for actual implementation
            }
            
            // Chart type toggle
            const pieChartBtn = document.querySelector('button:contains("Pie Chart")');
            const barChartBtn = document.querySelector('button:contains("Bar Chart")');
            
            if (pieChartBtn && barChartBtn) {
                barChartBtn.addEventListener('click', function() {
                    // Switch to bar chart
                    roomTypeChart.destroy();
                    
                    const newRoomTypeChart = new Chart(roomTypeCtx, {
                        type: 'bar',
                        data: {
                            labels: <%= roomTypesJson.toString() %>,
                            datasets: [{
                                label: 'Revenue ($)',
                                data: <%= roomTypeRevenueJson.toString() %>,
                                backgroundColor: [
                                    'rgba(59, 130, 246, 0.7)',
                                    'rgba(16, 185, 129, 0.7)',
                                    'rgba(245, 158, 11, 0.7)',
                                    'rgba(239, 68, 68, 0.7)',
                                    'rgba(139, 92, 246, 0.7)',
                                    'rgba(236, 72, 153, 0.7)'
                                ],
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
                                        callback: function(value) {
                                            return '$' + value.toLocaleString();
                                        }
                                    }
                                }
                            }
                        }
                    });
                    
                    // Update button styles
                    pieChartBtn.classList.remove('bg-blue-100', 'text-blue-600');
                    pieChartBtn.classList.add('text-gray-500', 'hover:text-blue-600');
                    
                    barChartBtn.classList.remove('text-gray-500', 'hover:text-blue-600');
                    barChartBtn.classList.add('bg-blue-100', 'text-blue-600');
                });
                
                pieChartBtn.addEventListener('click', function() {
                    // Switch back to pie chart
                    // Implementation would recreate the pie chart
                    // This is a placeholder for actual implementation
                    
                    // Update button styles
                    barChartBtn.classList.remove('bg-blue-100', 'text-blue-600');
                    barChartBtn.classList.add('text-gray-500', 'hover:text-blue-600');
                    
                    pieChartBtn.classList.remove('text-gray-500', 'hover:text-blue-600');
                    pieChartBtn.classList.add('bg-blue-100', 'text-blue-600');
                });
            }
        });
    </script>
</body>
</html>