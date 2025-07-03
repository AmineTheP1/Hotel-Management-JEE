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
    List<Map<String, Object>> revenueByHotelList = new ArrayList<>();
    List<Map<String, Object>> bookingsByMonthList = new ArrayList<>();
    List<Map<String, Object>> topPerformingHotelsList = new ArrayList<>();
    List<Map<String, Object>> recentBookingsList = new ArrayList<>();
    
    // Statistics
    double totalRevenue = 0;
    int totalBookings = 0;
    double averageBookingValue = 0;
    int totalCancelledBookings = 0;
    
    // Monthly data for charts
    List<Double> monthlyRevenue = new ArrayList<>(Arrays.asList(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0));
    List<Integer> monthlyBookings = new ArrayList<>(Arrays.asList(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));
    List<String> months = Arrays.asList("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
    
    try {
        // Establish database connection
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(url, username, password);
        
        // Get overall statistics
        String statsQuery = "SELECT " +
                           "COUNT(*) as total_bookings, " +
                           "SUM(total_amount) as total_revenue, " +
                           "AVG(total_amount) as avg_booking_value, " +
                           "SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled_bookings " +
                           "FROM bookings";
        
        pstmt = conn.prepareStatement(statsQuery);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            totalBookings = rs.getInt("total_bookings");
            totalRevenue = rs.getDouble("total_revenue");
            averageBookingValue = rs.getDouble("avg_booking_value");
            totalCancelledBookings = rs.getInt("cancelled_bookings");
        }
        
        rs.close();
        pstmt.close();
        
        // Get revenue by hotel
        String revenueByHotelQuery = "SELECT h.name as hotel_name, h.city, h.country, " +
                                    "COUNT(b.id) as booking_count, " +
                                    "SUM(b.total_amount) as total_revenue, " +
                                    "AVG(b.total_amount) as avg_booking_value " +
                                    "FROM hotels h " +
                                    "JOIN bookings b ON h.id = b.hotel_id " +
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
        
        // Get monthly bookings and revenue data for the current year
        int currentYear = Calendar.getInstance().get(Calendar.YEAR);
        String monthlyDataQuery = "SELECT MONTH(booking_date) as month, " +
                                 "COUNT(*) as booking_count, " +
                                 "SUM(total_amount) as revenue " +
                                 "FROM bookings " +
                                 "WHERE YEAR(booking_date) = ? " +
                                 "GROUP BY MONTH(booking_date) " +
                                 "ORDER BY month";
        
        pstmt = conn.prepareStatement(monthlyDataQuery);
        pstmt.setInt(1, currentYear);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            int month = rs.getInt("month") - 1; // 0-based index
            monthlyBookings.set(month, rs.getInt("booking_count"));
            monthlyRevenue.set(month, rs.getDouble("revenue"));
            
            Map<String, Object> monthData = new HashMap<>();
            monthData.put("month", months.get(month));
            monthData.put("booking_count", rs.getInt("booking_count"));
            monthData.put("revenue", rs.getDouble("revenue"));
            
            bookingsByMonthList.add(monthData);
        }
        
        rs.close();
        pstmt.close();
        
        // Get top performing hotels (by occupancy rate)
        String topHotelsQuery = "SELECT h.id, h.name, h.city, h.country, h.image_url, h.rating, " +
                               "COUNT(b.id) AS booking_count, " +
                               "SUM(b.total_amount) AS revenue, " +
                               "(COUNT(b.id) * 100 / (SELECT COUNT(*) FROM bookings)) AS occupancy_rate " +
                               "FROM hotels h " +
                               "JOIN bookings b ON h.id = b.hotel_id " +
                               "GROUP BY h.id " +
                               "ORDER BY occupancy_rate DESC " +
                               "LIMIT 5";
        
        pstmt = conn.prepareStatement(topHotelsQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> hotel = new HashMap<>();
            hotel.put("id", rs.getInt("id"));
            hotel.put("name", rs.getString("name"));
            hotel.put("location", rs.getString("city") + ", " + rs.getString("country"));
            hotel.put("image_url", rs.getString("image_url"));
            hotel.put("rating", rs.getDouble("rating"));
            hotel.put("booking_count", rs.getInt("booking_count"));
            hotel.put("revenue", rs.getDouble("revenue"));
            hotel.put("occupancy_rate", rs.getInt("occupancy_rate"));
            
            topPerformingHotelsList.add(hotel);
        }
        
        rs.close();
        pstmt.close();
        
        // Get recent bookings
        String recentBookingsQuery = "SELECT b.id, b.booking_date, b.total_amount, b.status, " +
                                    "u.first_name, u.last_name, u.email, " +
                                    "h.name as hotel_name, r.room_type " +
                                    "FROM bookings b " +
                                    "JOIN users u ON b.user_id = u.id " +
                                    "JOIN hotels h ON b.hotel_id = h.id " +
                                    "JOIN rooms r ON b.room_id = r.id " +
                                    "ORDER BY b.booking_date DESC LIMIT 5";
        
        pstmt = conn.prepareStatement(recentBookingsQuery);
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
            
            recentBookingsList.add(booking);
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
    
    StringBuilder monthlyBookingsJson = new StringBuilder("[");
    for (Integer count : monthlyBookings) {
        monthlyBookingsJson.append(count).append(",");
    }
    if (monthlyBookingsJson.charAt(monthlyBookingsJson.length() - 1) == ',') {
        monthlyBookingsJson.setLength(monthlyBookingsJson.length() - 1);
    }
    monthlyBookingsJson.append("]");
    
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
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZAIRTAM - Reports & Analytics</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
        }
        
        .report-card {
            transition: all 0.3s ease;
        }
        
        .report-card:hover {
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
                        <input type="text" placeholder="Search for reports..." class="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
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
                            <a href="Reports.jsp" class="flex items-center px-3 py-2 text-blue-600 bg-blue-50 rounded-md">
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
            <div class="flex justify-between items-center mb-8">
                <div>
                    <h1 class="text-2xl font-bold text-gray-800">Reports & Analytics</h1>
                    <p class="text-gray-600">Comprehensive reports and analytics for your hotel network</p>
                </div>
                <div class="flex space-x-3">
                    <button class="bg-white border border-gray-300 text-gray-700 px-4 py-2 rounded-lg transition duration-200 flex items-center hover:bg-gray-50">
                        <i class="fas fa-download mr-2"></i> Export
                    </button>
                    <button class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg transition duration-200 flex items-center">
                        <i class="fas fa-plus mr-2"></i> Create Report
                    </button>
                </div>
            </div>
            
            <!-- Date Range Filter -->
            <div class="bg-white rounded-lg shadow-sm p-6 mb-8">
                <div class="flex flex-wrap items-center justify-between">
                    <h3 class="text-lg font-semibold text-gray-800 mb-4 md:mb-0">Report Period</h3>
                    
                    <div class="flex flex-wrap gap-4">
                        <div class="w-full md:w-auto">
                            <label for="date-range" class="block text-sm font-medium text-gray-700 mb-1">Date Range</label>
                            <select id="date-range" class="w-full md:w-48 px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                <option value="this-month">This Month</option>
                                <option value="last-month">Last Month</option>
                                <option value="last-3-months">Last 3 Months</option>
                                <option value="last-6-months">Last 6 Months</option>
                                <option value="this-year">This Year</option>
                                <option value="last-year">Last Year</option>
                                <option value="custom">Custom Range</option>
                            </select>
                        </div>
                        
                        <div class="w-full md:w-auto">
                            <label for="hotel-filter" class="block text-sm font-medium text-gray-700 mb-1">Hotel</label>
                            <select id="hotel-filter" class="w-full md:w-48 px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                <option value="all">All Hotels</option>
                                <% 
                                // Get unique hotels from revenue list
                                Set<String> hotels = new HashSet<>();
                                for (Map<String, Object> hotel : revenueByHotelList) {
                                    hotels.add((String)hotel.get("hotel_name"));
                                }
                                
                                for (String hotel : hotels) {
                                %>
                                <option value="<%= hotel.toLowerCase().replace(" ", "-") %>"><%= hotel %></option>
                                <% } %>
                            </select>
                        </div>
                        
                        <div class="w-full md:w-auto">
                            <label for="report-type" class="block text-sm font-medium text-gray-700 mb-1">Report Type</label>
                            <select id="report-type" class="w-full md:w-48 px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                <option value="all">All Reports</option>
                                <option value="revenue">Revenue</option>
                                <option value="bookings">Bookings</option>
                                <option value="occupancy">Occupancy</option>
                                <option value="performance">Performance</option>
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
            <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Total Revenue</h3>
                        <div class="bg-green-100 p-2 rounded-md">
                            <i class="fas fa-dollar-sign text-green-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800">$<%= String.format("%.2f", totalRevenue) %></p>
                        <p class="text-green-600 text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-up mr-1"></i>15%
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Compared to last month</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Total Bookings</h3>
                        <div class="bg-blue-100 p-2 rounded-md">
                            <i class="fas fa-calendar-check text-blue-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= totalBookings %></p>
                        <p class="text-green-600 text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-up mr-1"></i>8%
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Compared to last month</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Avg. Booking Value</h3>
                        <div class="bg-purple-100 p-2 rounded-md">
                            <i class="fas fa-chart-line text-purple-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800">$<%= String.format("%.2f", averageBookingValue) %></p>
                        <p class="text-green-600 text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-up mr-1"></i>5%
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Compared to last month</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Cancellation Rate</h3>
                        <div class="bg-red-100 p-2 rounded-md">
                            <i class="fas fa-ban text-red-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= String.format("%.1f", (totalCancelledBookings * 100.0 / totalBookings)) %>%</p>
                        <p class="text-red-600 text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-down mr-1"></i>2.5%
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Compared to last month</p>
                </div>
            </div>
            
            <!-- Revenue & Bookings Charts -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <h3 class="text-lg font-semibold text-gray-800 mb-4">Monthly Revenue</h3>
                    <div class="chart-container">
                        <canvas id="revenueChart"></canvas>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <h3 class="text-lg font-semibold text-gray-800 mb-4">Monthly Bookings</h3>
                    <div class="chart-container">
                        <canvas id="bookingsChart"></canvas>
                    </div>
                </div>
            </div>
            
            <!-- Revenue by Hotel -->
            <div class="bg-white rounded-lg shadow-sm p-6 mb-8">
                <h3 class="text-lg font-semibold text-gray-800 mb-6">Revenue by Hotel</h3>
                <div class="chart-container">
                    <canvas id="hotelRevenueChart"></canvas>
                </div>
            </div>
            
            <!-- Top Performing Hotels -->
            <div class="bg-white rounded-lg shadow-sm p-6 mb-8">
                <div class="flex justify-between items-center mb-6">
                    <h3 class="text-lg font-semibold text-gray-800">Top Performing Hotels</h3>
                    <a href="#" class="text-blue-600 hover:text-blue-800 text-sm font-medium">View All</a>
                </div>
                
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    <% for (Map<String, Object> hotel : topPerformingHotelsList) { %>
                    <div class="bg-white border rounded-lg overflow-hidden report-card">
                        <img src="<%= hotel.get("image_url") %>" alt="<%= hotel.get("name") %>" class="w-full h-40 object-cover">
                        <div class="p-4">
                            <div class="flex justify-between items-start mb-2">
                                <h4 class="text-gray-900 font-semibold"><%= hotel.get("name") %></h4>
                                <div class="flex items-center bg-blue-50 text-blue-700 px-2 py-1 rounded text-xs font-medium">
                                    <i class="fas fa-star text-yellow-400 mr-1"></i>
                                    <%= hotel.get("rating") %>
                                </div>
                            </div>
                            <p class="text-gray-500 text-sm mb-3"><i class="fas fa-map-marker-alt mr-1"></i> <%= hotel.get("location") %></p>
                            
                            <div class="grid grid-cols-2 gap-2 mb-3">
                                <div>
                                    <p class="text-xs text-gray-500">Bookings</p>
                                    <p class="font-semibold"><%= hotel.get("booking_count") %></p>
                                </div>
                                <div>
                                    <p class="text-xs text-gray-500">Revenue</p>
                                    <p class="font-semibold">$<%= String.format("%,.2f", (Double)hotel.get("revenue")) %></p>
                                </div>
                            </div>
                            
                            <div class="mt-3">
                                <p class="text-xs text-gray-500 mb-1">Occupancy Rate</p>
                                <div class="w-full bg-gray-200 rounded-full h-2">
                                    <div class="bg-blue-600 h-2 rounded-full" style="width: <%= hotel.get("occupancy_rate") %>%;"></div>
                                </div>
                                <p class="text-xs text-right mt-1"><%= hotel.get("occupancy_rate") %>%</p>
                            </div>
                        </div>
                    </div>
                    <% } %>
                </div>
            </div>
            
            <!-- Recent Bookings -->
            <div class="bg-white rounded-lg shadow-sm overflow-hidden mb-8">
                <div class="p-6 border-b flex justify-between items-center">
                    <h3 class="text-lg font-semibold text-gray-800">Recent Bookings</h3>
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
                            <% for (Map<String, Object> booking : recentBookingsList) { %>
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
            
            // Monthly Bookings Chart
            const bookingsCtx = document.getElementById('bookingsChart').getContext('2d');
            const bookingsChart = new Chart(bookingsCtx, {
                type: 'bar',
                data: {
                    labels: <%= Arrays.toString(months.toArray()) %>,
                    datasets: [{
                        label: 'Bookings',
                        data: <%= monthlyBookingsJson.toString() %>,
                        backgroundColor: 'rgba(16, 185, 129, 0.7)',
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
            
            // Hotel Revenue Chart
            const hotelRevenueCtx = document.getElementById('hotelRevenueChart').getContext('2d');
            const hotelRevenueChart = new Chart(hotelRevenueCtx, {
                type: 'bar',
                data: {
                    labels: <%= hotelNamesJson.toString() %>,
                    datasets: [{
                        label: 'Revenue ($)',
                        data: <%= hotelRevenueJson.toString() %>,
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
                                callback: function(value) {
                                    return '$' + value.toLocaleString();
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