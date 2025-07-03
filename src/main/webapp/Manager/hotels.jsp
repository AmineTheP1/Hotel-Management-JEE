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
    
    // Statistics variables
    int activeHotelsCount = 0;
    int pendingHotelsCount = 0;
    double averageRating = 0.0;
    
    // Hotels list
    List<Map<String, Object>> hotelsList = new ArrayList<>();
    
    try {
        // Establish database connection
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(url, username, password);
        
        // Get active hotels count
        pstmt = conn.prepareStatement("SELECT COUNT(*) FROM hotels WHERE status = 'active'");
        rs = pstmt.executeQuery();
        if (rs.next()) {
            activeHotelsCount = rs.getInt(1);
        }
        
        // Get pending hotels count
        pstmt = conn.prepareStatement("SELECT COUNT(*) FROM hotels WHERE status = 'pending'");
        rs = pstmt.executeQuery();
        if (rs.next()) {
            pendingHotelsCount = rs.getInt(1);
        }
        
        // Get average rating
        pstmt = conn.prepareStatement("SELECT AVG(rating) FROM hotels");
        rs = pstmt.executeQuery();
        if (rs.next()) {
            averageRating = rs.getDouble(1);
        }
        
        // Get all hotels
        pstmt = conn.prepareStatement("SELECT h.*, m.name as manager_name, m.email as manager_email " +
                                     "FROM hotels h " +
                                     "LEFT JOIN managers m ON h.manager_id = m.id " +
                                     "ORDER BY h.id DESC");
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> hotel = new HashMap<>();
            hotel.put("id", rs.getString("id"));
            hotel.put("name", rs.getString("name"));
            hotel.put("location", rs.getString("location"));
            hotel.put("city", rs.getString("city"));
            hotel.put("country", rs.getString("country"));
            hotel.put("manager_name", rs.getString("manager_name"));
            hotel.put("manager_email", rs.getString("manager_email"));
            hotel.put("rooms", rs.getInt("rooms"));
            hotel.put("rating", rs.getDouble("rating"));
            hotel.put("status", rs.getString("status"));
            hotel.put("image_url", rs.getString("image_url"));
            
            hotelsList.add(hotel);
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
    <title>ZAIRTAM - Hotels Management</title>
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
        
        .status-pending {
            background-color: #FEF3C7;
            color: #92400E;
        }
        
        .status-inactive {
            background-color: #FEE2E2;
            color: #B91C1C;
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
                    <a href="index.jsp" class="flex items-center">
                        <i class="fas fa-hotel text-blue-600 text-2xl mr-2"></i>
                        <span class="text-xl font-bold text-gray-800">ZAIRTAM</span>
                    </a>
                </div>
                
                <!-- Search -->
                <div class="hidden md:flex items-center flex-1 max-w-md mx-8">
                    <div class="w-full relative">
                        <input type="text" placeholder="Search for hotels by name, location..." class="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
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
                            <a href="hotels.jsp" class="flex items-center px-3 py-2 text-blue-600 bg-blue-50 rounded-md">
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
                
                <!-- ... existing code ... -->
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
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:text-gray-700 relative">
                                <i class="fas fa-user-shield w-5 text-center"></i>
                                <span class="ml-2">Admin Users</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:text-gray-700 relative">
                                <i class="fas fa-cog w-5 text-center"></i>
                                <span class="ml-2">Settings</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:text-gray-700 relative">
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
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:text-gray-700 relative">
                                <i class="fas fa-question-circle w-5 text-center"></i>
                                <span class="ml-2">Help Center</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:text-gray-700 relative">
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
                    <h1 class="text-2xl font-bold text-gray-800">Hotels Management</h1>
                    <p class="text-gray-600">Manage all registered hotels in the system</p>
                </div>
                <button class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg transition duration-200 flex items-center">
                    <i class="fas fa-plus mr-2"></i> Add New Hotel
                </button>
            </div>
            
            <!-- Filters Section -->
            <div class="bg-white rounded-lg shadow-sm p-6 mb-8">
                <div class="flex flex-wrap items-center justify-between">
                    <h3 class="text-lg font-semibold text-gray-800 mb-4 md:mb-0">Filter Hotels</h3>
                    
                    <div class="flex flex-wrap gap-4">
                        <div class="w-full md:w-auto">
                            <label for="location-filter" class="block text-sm font-medium text-gray-700 mb-1">Location</label>
                            <select id="location-filter" class="w-full md:w-48 px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                <option value="all">All Locations</option>
                                <% 
                                // Get unique locations from the database
                                Set<String> locations = new HashSet<>();
                                for (Map<String, Object> hotel : hotelsList) {
                                    if (hotel.get("location") != null) {
                                        locations.add(hotel.get("location").toString());
                                    }
                                }
                                
                                for (String location : locations) {
                                %>
                                <option value="<%= location %>"><%= location %></option>
                                <% } %>
                            </select>
                        </div>
                        
                        <div class="w-full md:w-auto">
                            <label for="status-filter" class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                            <select id="status-filter" class="w-full md:w-48 px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                <option value="all">All Status</option>
                                <option value="active">Active</option>
                                <option value="pending">Pending Approval</option>
                                <option value="inactive">Inactive</option>
                            </select>
                        </div>
                        
                        <div class="w-full md:w-auto">
                            <label for="rating-filter" class="block text-sm font-medium text-gray-700 mb-1">Rating</label>
                            <select id="rating-filter" class="w-full md:w-48 px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                <option value="all">All Ratings</option>
                                <option value="5">5 Stars</option>
                                <option value="4">4 Stars & Up</option>
                                <option value="3">3 Stars & Up</option>
                                <option value="2">2 Stars & Up</option>
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
            
            <!-- Hotels Stats Cards -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Active Hotels</h3>
                        <div class="bg-green-100 p-2 rounded-md">
                            <i class="fas fa-check-circle text-green-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= activeHotelsCount %></p>
                        <p class="text-green-600 text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-up mr-1"></i>4%
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Compared to last month</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Pending Approval</h3>
                        <div class="bg-yellow-100 p-2 rounded-md">
                            <i class="fas fa-clock text-yellow-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= pendingHotelsCount %></p>
                        <p class="text-red-600 text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-up mr-1"></i>12%
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Compared to last month</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Average Rating</h3>
                        <div class="bg-blue-100 p-2 rounded-md">
                            <i class="fas fa-star text-blue-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= String.format("%.1f", averageRating) %></p>
                        <p class="text-green-600 text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-up mr-1"></i>0.2
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Compared to last month</p>
                </div>
            </div>
            
            <!-- Hotels Table -->
            <div class="bg-white rounded-lg shadow-sm overflow-hidden mb-8">
                <div class="p-6 border-b">
                    <h3 class="text-lg font-semibold text-gray-800">All Hotels</h3>
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
                                    Manager
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Rooms
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Rating
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
                            <% for (Map<String, Object> hotel : hotelsList) { %>
                            <tr>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="flex items-center">
                                        <div class="h-10 w-10 flex-shrink-0">
                                            <img class="h-10 w-10 rounded-md object-cover" 
                                                 src="<%= hotel.get("image_url") != null ? hotel.get("image_url") : "https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=150&q=80" %>" 
                                                 alt="<%= hotel.get("name") %>">
                                        </div>
                                        <div class="ml-4">
                                            <div class="text-sm font-medium text-gray-900"><%= hotel.get("name") %></div>
                                            <div class="text-sm text-gray-500">ID: <%= hotel.get("id") %></div>
                                        </div>
                                    </div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm text-gray-900"><%= hotel.get("city") %>, <%= hotel.get("country") %></div>
                                    <div class="text-sm text-gray-500"><%= hotel.get("location") %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm text-gray-900"><%= hotel.get("manager_name") != null ? hotel.get("manager_name") : "Not Assigned" %></div>
                                    <% if (hotel.get("manager_email") != null) { %>
                                    <div class="text-sm text-gray-500"><%= hotel.get("manager_email") %></div>
                                    <% } %>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                    <%= hotel.get("rooms") %>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="flex items-center">
                                        <% 
                                        double rating = (double) hotel.get("rating");
                                        int fullStars = (int) rating;
                                        boolean hasHalfStar = rating - fullStars >= 0.5;
                                        %>
                                        <span class="text-yellow-400 flex">
                                            <% for (int i = 0; i < fullStars; i++) { %>
                                            <i class="fas fa-star mr-1"></i>
                                            <% } %>
                                            
                                            <% if (hasHalfStar) { %>
                                            <i class="fas fa-star-half-alt mr-1"></i>
                                            <% } %>
                                            
                                            <% for (int i = 0; i < (5 - fullStars - (hasHalfStar ? 1 : 0)); i++) { %>
                                            <i class="far fa-star mr-1"></i>
                                            <% } %>
                                        </span>
                                        <span class="ml-1 text-sm text-gray-600"><%= String.format("%.1f", rating) %></span>
                                    </div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <% 
                                    String status = (String) hotel.get("status");
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
                                        <%= status.substring(0, 1).toUpperCase() + status.substring(1) %>
                                    </span>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                    <div class="flex justify-end space-x-2">
                                        <a href="view-hotel.jsp?id=<%= hotel.get("id") %>" class="text-blue-600 hover:text-blue-900">
                                            <i class="fas fa-eye"></i>
                                        </a>
                                        <a href="edit-hotel.jsp?id=<%= hotel.get("id") %>" class="text-indigo-600 hover:text-indigo-900">
                                            <i class="fas fa-edit"></i>
                                        </a>
                                        <% if ("pending".equalsIgnoreCase(status)) { %>
                                        <a href="approve-hotel.jsp?id=<%= hotel.get("id") %>" class="text-green-600 hover:text-green-900">
                                            <i class="fas fa-check"></i>
                                        </a>
                                        <% } %>
                                        <button onclick="confirmDelete('<%= hotel.get("id") %>', '<%= hotel.get("name") %>')" class="text-red-600 hover:text-red-900">
                                            <i class="fas fa-trash"></i>
                                        </button>
                                    </div>
                                </td>
                            </tr>
                            <% } %>
                            
                            <% if (hotelsList.isEmpty()) { %>
                            <tr>
                                <td colspan="7" class="px-6 py-10 text-center text-gray-500">
                                    <i class="fas fa-hotel text-gray-400 text-4xl mb-3"></i>
                                    <p>No hotels found</p>
                                    <p class="text-sm mt-1">Add a new hotel or adjust your filters</p>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
                
                <!-- Pagination -->
                <div class="px-6 py-4 border-t flex items-center justify-between">
                    <div class="text-sm text-gray-500">
                        Showing <span class="font-medium"><%= Math.min(1, hotelsList.size()) %></span> to <span class="font-medium"><%= hotelsList.size() %></span> of <span class="font-medium"><%= hotelsList.size() %></span> hotels
                    </div>
                    <div class="flex space-x-2">
                        <button class="px-3 py-1 border rounded text-gray-600 hover:bg-gray-50 disabled:opacity-50" disabled>
                            <i class="fas fa-chevron-left mr-1"></i> Previous
                        </button>
                        <button class="px-3 py-1 border rounded text-gray-600 hover:bg-gray-50 disabled:opacity-50" disabled>
                            Next <i class="fas fa-chevron-right ml-1"></i>
                        </button>
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
                        <h3 class="text-lg font-bold text-gray-900 mb-1">Delete Hotel</h3>
                        <p class="text-gray-500" id="deleteModalText">Are you sure you want to delete this hotel?</p>
                    </div>
                    <div class="flex space-x-3">
                        <button onclick="closeDeleteModal()" class="flex-1 px-4 py-2 bg-gray-100 hover:bg-gray-200 text-gray-800 rounded-lg transition duration-200">
                            Cancel
                        </button>
                        <form action="delete-hotel.jsp" method="post" class="flex-1">
                            <input type="hidden" name="hotel_id" id="deleteHotelId">
                            <button type="submit" class="w-full px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg transition duration-200">
                                Delete
                            </button>
                        </form>
                    </div>
                </div>
            </div>
            
            <!-- Add JavaScript for sidebar toggle and delete confirmation -->
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
                function confirmDelete(hotelId, hotelName) {
                    document.getElementById('deleteHotelId').value = hotelId;
                    document.getElementById('deleteModalText').textContent = `Are you sure you want to delete "${hotelName}"?`;
                    document.getElementById('deleteModal').classList.remove('hidden');
                    document.getElementById('deleteModal').classList.add('flex');
                }
                
                function closeDeleteModal() {
                    document.getElementById('deleteModal').classList.add('hidden');
                    document.getElementById('deleteModal').classList.remove('flex');
                }
                
                // Filter functionality
                document.querySelector('button.bg-blue-600').addEventListener('click', function() {
                    const locationFilter = document.getElementById('location-filter').value;
                    const statusFilter = document.getElementById('status-filter').value;
                    const ratingFilter = document.getElementById('rating-filter').value;
                    
                    // Redirect with filter parameters
                    window.location.href = `hotels.jsp?location=${locationFilter}&status=${statusFilter}&rating=${ratingFilter}`;
                });
            </script>
        </main>
    </div>
</body>
</html>