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
    
    // Initialize variables to store data from database
    int totalHotels = 0;
    int totalUsers = 0;
    int totalBookings = 0;
    double totalRevenue = 0.0;
    
    // Hotel growth percentage
    int hotelGrowthPercent = 0;
    int userGrowthPercent = 0;
    int bookingGrowthPercent = 0;
    int revenueGrowthPercent = 0;
    
    // Lists to store top hotels data
    List<Map<String, Object>> topHotels = new ArrayList<>();
    
    // Monthly revenue data for chart
    List<Double> monthlyRevenue = new ArrayList<>();
    List<String> months = Arrays.asList("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
    
    // Bookings by hotel data for chart
    Map<String, Integer> bookingsByHotel = new HashMap<>();
    
    // Recent activity data
    List<Map<String, Object>> recentActivities = new ArrayList<>();
    
    try {
        // Load the JDBC driver
        Class.forName("com.mysql.jdbc.Driver");
        
        // Establish connection
        Connection conn = DriverManager.getConnection(url, username, password);
        
        // Get total hotels count
        PreparedStatement pstmt = conn.prepareStatement("SELECT COUNT(*) AS total FROM hotels");
        ResultSet rs = pstmt.executeQuery();
        if (rs.next()) {
            totalHotels = rs.getInt("total");
        }
        
        // Get total users count
        pstmt = conn.prepareStatement("SELECT COUNT(*) AS total FROM users");
        rs = pstmt.executeQuery();
        if (rs.next()) {
            totalUsers = rs.getInt("total");
        }
        
        // Get total bookings count
        pstmt = conn.prepareStatement("SELECT COUNT(*) AS total FROM bookings");
        rs = pstmt.executeQuery();
        if (rs.next()) {
            totalBookings = rs.getInt("total");
        }
        
        // Get total revenue
        pstmt = conn.prepareStatement("SELECT SUM(amount) AS total FROM payments");
        rs = pstmt.executeQuery();
        if (rs.next()) {
            totalRevenue = rs.getDouble("total");
        }
        
        // Calculate growth percentages (this would typically compare current month to previous month)
        // For demo purposes, we're using static values
        hotelGrowthPercent = 5;
        userGrowthPercent = 12;
        bookingGrowthPercent = 8;
        revenueGrowthPercent = 15;
        
        // Get top 5 most booked hotels
        pstmt = conn.prepareStatement(
            "SELECT h.id, h.name, h.city, h.country, h.image_url, h.rating, " +
            "COUNT(b.id) AS booking_count, SUM(b.total_price) AS revenue, " +
            "(COUNT(b.id) * 100 / (SELECT COUNT(*) FROM bookings)) AS occupancy_rate " +
            "FROM hotels h " +
            "JOIN bookings b ON h.id = b.hotel_id " +
            "GROUP BY h.id " +
            "ORDER BY booking_count DESC " +
            "LIMIT 5"
        );
        
        rs = pstmt.executeQuery();
        while (rs.next()) {
            Map<String, Object> hotel = new HashMap<>();
            hotel.put("id", rs.getInt("id"));
            hotel.put("name", rs.getString("name"));
            hotel.put("city", rs.getString("city"));
            hotel.put("country", rs.getString("country"));
            hotel.put("imageUrl", rs.getString("image_url"));
            hotel.put("rating", rs.getDouble("rating"));
            hotel.put("bookingCount", rs.getInt("booking_count"));
            hotel.put("revenue", rs.getDouble("revenue"));
            hotel.put("occupancyRate", rs.getInt("occupancy_rate"));
            topHotels.add(hotel);
        }
        
        // Get monthly revenue data for the current year
        int currentYear = Calendar.getInstance().get(Calendar.YEAR);
        pstmt = conn.prepareStatement(
            "SELECT MONTH(payment_date) AS month, SUM(amount) AS revenue " +
            "FROM payments " +
            "WHERE YEAR(payment_date) = ? " +
            "GROUP BY MONTH(payment_date) " +
            "ORDER BY month"
        );
        pstmt.setInt(1, currentYear);
        
        rs = pstmt.executeQuery();
        
        // Initialize all months with 0
        for (int i = 0; i < 12; i++) {
            monthlyRevenue.add(0.0);
        }
        
        // Fill in actual data
        while (rs.next()) {
            int month = rs.getInt("month") - 1; // 0-based index
            double revenue = rs.getDouble("revenue");
            monthlyRevenue.set(month, revenue);
        }
        
        // Get bookings by hotel data
        pstmt = conn.prepareStatement(
            "SELECT h.name, COUNT(b.id) AS booking_count " +
            "FROM hotels h " +
            "JOIN bookings b ON h.id = b.hotel_id " +
            "GROUP BY h.id " +
            "ORDER BY booking_count DESC " +
            "LIMIT 10"
        );
        
        rs = pstmt.executeQuery();
        while (rs.next()) {
            bookingsByHotel.put(rs.getString("name"), rs.getInt("booking_count"));
        }
        
        // Get recent activities
        pstmt = conn.prepareStatement(
            "SELECT 'hotel_registration' AS type, h.name, h.created_at AS timestamp " +
            "FROM hotels h " +
            "UNION ALL " +
            "SELECT 'user_registration' AS type, u.username AS name, u.created_at AS timestamp " +
            "FROM users u " +
            "UNION ALL " +
            "SELECT 'booking' AS type, CONCAT(u.username, ' booked ', h.name) AS name, b.created_at AS timestamp " +
            "FROM bookings b " +
            "JOIN users u ON b.user_id = u.id " +
            "JOIN hotels h ON b.hotel_id = h.id " +
            "ORDER BY timestamp DESC " +
            "LIMIT 10"
        );
        
        rs = pstmt.executeQuery();
        while (rs.next()) {
            Map<String, Object> activity = new HashMap<>();
            activity.put("type", rs.getString("type"));
            activity.put("name", rs.getString("name"));
            activity.put("timestamp", rs.getTimestamp("timestamp"));
            recentActivities.add(activity);
        }
        
        // Close resources
        rs.close();
        pstmt.close();
        conn.close();
    } catch (Exception e) {
        e.printStackTrace();
    }
    
    // Format the total revenue for display
    String formattedRevenue = String.format("$%.1fM", totalRevenue / 1000000);
    
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
    StringBuilder bookingCountsJson = new StringBuilder("[");
    
    for (Map.Entry<String, Integer> entry : bookingsByHotel.entrySet()) {
        hotelNamesJson.append("\"").append(entry.getKey()).append("\",");
        bookingCountsJson.append(entry.getValue()).append(",");
    }
    
    if (hotelNamesJson.charAt(hotelNamesJson.length() - 1) == ',') {
        hotelNamesJson.setLength(hotelNamesJson.length() - 1);
    }
    hotelNamesJson.append("]");
    
    if (bookingCountsJson.charAt(bookingCountsJson.length() - 1) == ',') {
        bookingCountsJson.setLength(bookingCountsJson.length() - 1);
    }
    bookingCountsJson.append("]");
    
    // Format timestamp for display
    SimpleDateFormat dateFormat = new SimpleDateFormat("MMM d, yyyy 'at' h:mm a");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZAIRTAM - Global Admin Dashboard</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
        }
        
        .hotel-card {
            transition: all 0.3s ease;
        }
        
        .hotel-card:hover {
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
                            <a href="#" class="flex items-center px-3 py-2 text-blue-600 bg-blue-50 rounded-md">
                                <i class="fas fa-tachometer-alt w-5 text-center"></i>
                                <span class="ml-2">Dashboard</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-hotel w-5 text-center"></i>
                                <span class="ml-2">Hotels</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-users w-5 text-center"></i>
                                <span class="ml-2">Users</span>
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
                
                <div class="mb-6">
                    <h3 class="text-xs uppercase text-gray-500 font-semibold tracking-wider">Analytics</h3>
                    <ul class="mt-3 space-y-1">
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-chart-line w-5 text-center"></i>
                                <span class="ml-2">Reports</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-money-bill-wave w-5 text-center"></i>
                                <span class="ml-2">Revenue</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
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
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-user-shield w-5 text-center"></i>
                                <span class="ml-2">Admin Users</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-cog w-5 text-center"></i>
                                <span class="ml-2">Settings</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
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
            <div class="mb-8">
                <h1 class="text-2xl font-bold text-gray-800">Global Admin Dashboard</h1>
                <p class="text-gray-600">Welcome back, Admin! Here's an overview of all registered hotels.</p>
            </div>
            
            <!-- Date Filter -->
            <div class="mb-8 bg-white rounded-lg shadow-sm p-4">
                <div class="flex flex-wrap items-center justify-between">
                    <h3 class="text-lg font-semibold text-gray-800 mb-2 md:mb-0">Filter Data</h3>
                    
                    <div class="flex flex-wrap gap-4">
                        <div class="w-full md:w-auto">
                            <label for="hotel-filter" class="block text-sm font-medium text-gray-700 mb-1">Hotel</label>
                            <select id="hotel-filter" class="w-full md:w-48 px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                <option value="all">All Hotels</option>
                                <c:forEach items="${topHotels}" var="hotel">
                                    <option value="${hotel.id}">${hotel.name}</option>
                                </c:forEach>
                            </select>
                        </div>
                        
                        <div class="w-full md:w-auto">
                            <label for="date-range" class="block text-sm font-medium text-gray-700 mb-1">Date Range</label>
                            <select id="date-range" class="w-full md:w-48 px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                <option value="last-7-days">Last 7 Days</option>
                                <option value="last-30-days" selected>Last 30 Days</option>
                                <option value="last-90-days">Last 90 Days</option>
                                <option value="year-to-date">Year to Date</option>
                                <option value="last-year">Last Year</option>
                                <option value="custom">Custom Range</option>
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
            
            <!-- Stats Cards -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Total Hotels</h3>
                        <div class="bg-blue-100 p-2 rounded-md">
                            <i class="fas fa-hotel text-blue-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= totalHotels %></p>
                        <p class="text-green-600 text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-up mr-1"></i><%= hotelGrowthPercent %>%
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Compared to last month</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Total Users</h3>
                        <div class="bg-green-100 p-2 rounded-md">
                            <i class="fas fa-users text-green-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= totalUsers %></p>
                        <p class="text-green-600 text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-up mr-1"></i><%= userGrowthPercent %>%
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Compared to last month</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Total Bookings</h3>
                        <div class="bg-purple-100 p-2 rounded-md">
                            <i class="fas fa-calendar-check text-purple-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= totalBookings %></p>
                        <p class="text-green-600 text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-up mr-1"></i><%= bookingGrowthPercent %>%
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Compared to last month</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Total Revenue</h3>
                        <div class="bg-yellow-100 p-2 rounded-md">
                            <i class="fas fa-dollar-sign text-yellow-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= formattedRevenue %></p>
                        <p class="text-green-600 text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-up mr-1"></i><%= revenueGrowthPercent %>%
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Compared to last month</p>
                </div>
            </div>
            
            <!-- Charts Section -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <h3 class="text-lg font-semibold text-gray-800 mb-4">Monthly Revenue</h3>
                    <div class="h-80">
                        <canvas id="revenueChart"></canvas>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <h3 class="text-lg font-semibold text-gray-800 mb-4">Bookings by Hotel</h3>
                    <div class="h-80">
                        <canvas id="bookingsChart"></canvas>
                    </div>
                </div>
            </div>
            
            <!-- Top Hotels Section -->
            <div class="mb-8">
                <h2 class="text-xl font-bold text-gray-800 mb-6">Top 5 Most Booked Hotels</h2>
                
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    <% for (Map<String, Object> hotel : topHotels) { %>
                    <div class="bg-white rounded-lg shadow-sm overflow-hidden hotel-card">
                        <img src="<%= hotel.get("imageUrl") %>" alt="<%= hotel.get("name") %>" class="w-full h-48 object-cover">
                        <div class="p-5">
                            <div class="flex justify-between items-start mb-4">
                                <div>
                                    <h3 class="font-semibold text-gray-800"><%= hotel.get("name") %></h3>
                                    <p class="text-sm text-gray-500"><%= hotel.get("city") %>, <%= hotel.get("country") %></p>
                                </div>
                                <div class="flex items-center bg-blue-100 px-2 py-1 rounded-full">
                                    <i class="fas fa-star text-yellow-500 mr-1 text-xs"></i>
                                    <span class="text-sm font-medium"><%= hotel.get("rating") %></span>
                                </div>
                            </div>
                            
                            <div class="space-y-2 mb-4">
                                <div class="flex justify-between">
                                    <span class="text-gray-600 text-sm">Total Bookings:</span>
                                    <span class="font-medium text-sm"><%= hotel.get("bookingCount") %></span>
                                </div>
                                <div class="flex justify-between">
                                    <span class="text-gray-600 text-sm">Revenue:</span>
                                    <span class="font-medium text-sm">$<%= String.format("%,.0f", (Double)hotel.get("revenue")) %></span>
                                </div>
                                <div class="flex justify-between">
                                    <span class="text-gray-600 text-sm">Occupancy Rate:</span>
                                    <span class="font-medium text-sm"><%= hotel.get("occupancyRate") %>%</span>
                                </div>
                            </div>
                            
                            <div class="flex space-x-2">
                                <button class="flex-1 bg-gray-100 hover:bg-gray-200 text-gray-800 py-2 rounded-md text-sm font-medium transition duration-200">
                                    <i class="fas fa-chart-line mr-1"></i> View Stats
                                </button>
                                <button class="flex-1 bg-blue-600 hover:bg-blue-700 text-white py-2 rounded-md text-sm font-medium transition duration-200">
                                    <i class="fas fa-external-link-alt mr-1"></i> Details
                                </button>
                            </div>
                        </div>
                    </div>
                    <% } %>
                </div>
                
                <div class="mt-8 text-center">
                    <button class="px-4 py-2 bg-white border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 transition duration-200">
                        View All Hotels <i class="fas fa-arrow-right ml-1"></i>
                    </button>
                </div>
            </div>
            
            <!-- Recent Activity -->
            <div class="mb-8">
                <h2 class="text-xl font-bold text-gray-800 mb-6">Recent Activity</h2>
                
                <div class="bg-white rounded-lg shadow-sm overflow-hidden">
                    <div class="p-6">
                        <div class="space-y-6">
                            <% for (Map<String, Object> activity : recentActivities) { 
                                String iconClass = "";
                                String bgColorClass = "";
                                
                                if (activity.get("type").equals("hotel_registration")) {
                                    iconClass = "fas fa-hotel";
                                    bgColorClass = "bg-blue-100 text-blue-600";
                                } else if (activity.get("type").equals("user_registration")) {
                                    iconClass = "fas fa-user-plus";
                                    bgColorClass = "bg-green-100 text-green-600";
                                } else if (activity.get("type").equals("booking")) {
                                    iconClass = "fas fa-calendar-check";
                                    bgColorClass = "bg-purple-100 text-purple-600";
                                } else {
                                    iconClass = "fas fa-info-circle";
                                    bgColorClass = "bg-gray-100 text-gray-600";
                                }
                                
                                // Format timestamp
                                String formattedTime = "";
                                if (activity.get("timestamp") != null) {
                                    formattedTime = dateFormat.format((Timestamp)activity.get("timestamp"));
                                }
                            %>
                                <div class="flex items-start">
                                    <div class="<%= bgColorClass %> p-3 rounded-full mr-4">
                                        <i class="<%= iconClass %>"></i>
                                    </div>
                                    <div class="flex-1">
                                        <p class="font-medium text-gray-800"><%= activity.get("name") %></p>
                                        <p class="text-sm text-gray-500"><%= formattedTime %></p>
                                    </div>
                                </div>
                            <% } %>
                            
                            <% if (recentActivities.isEmpty()) { %>
                                <div class="text-center py-4">
                                    <p class="text-gray-500">No recent activities found</p>
                                </div>
                            <% } %>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    </div>
    
    <script>
        // Sidebar toggle for mobile
        document.getElementById('sidebar-toggle').addEventListener('click', function() {
            document.getElementById('sidebar').classList.toggle('open');
        });
        
        // Charts
        document.addEventListener('DOMContentLoaded', function() {
            // Monthly Revenue Chart
            const revenueCtx = document.getElementById('revenueChart').getContext('2d');
            const revenueChart = new Chart(revenueCtx, {
                type: 'line',
                data: {
                    labels: <%= Arrays.toString(months.toArray()) %>,
                    datasets: [{
                        label: 'Revenue',
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
                            grid: {
                                drawBorder: false
                            },
                            ticks: {
                                callback: function(value) {
                                    return '$' + value.toLocaleString();
                                }
                            }
                        },
                        x: {
                            grid: {
                                display: false
                            }
                        }
                    }
                }
            });
            
            // Bookings by Hotel Chart
            const bookingsCtx = document.getElementById('bookingsChart').getContext('2d');
            const bookingsChart = new Chart(bookingsCtx, {
                type: 'bar',
                data: {
                    labels: <%= hotelNamesJson.toString() %>,
                    datasets: [{
                        label: 'Bookings',
                        data: <%= bookingCountsJson.toString() %>,
                        backgroundColor: [
                            'rgba(59, 130, 246, 0.7)',
                            'rgba(16, 185, 129, 0.7)',
                            'rgba(139, 92, 246, 0.7)',
                            'rgba(249, 115, 22, 0.7)',
                            'rgba(236, 72, 153, 0.7)',
                            'rgba(245, 158, 11, 0.7)',
                            'rgba(6, 182, 212, 0.7)',
                            'rgba(168, 85, 247, 0.7)',
                            'rgba(239, 68, 68, 0.7)',
                            'rgba(5, 150, 105, 0.7)'
                        ]
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
                            grid: {
                                drawBorder: false
                            }
                        },
                        x: {
                            grid: {
                                display: false
                            }
                        }
                    }
                }
            });
        });
    </script>
</body>
</html>