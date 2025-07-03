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
    int totalRooms = 0;
    int availableRooms = 0;
    int occupiedRooms = 0;
    int maintenanceRooms = 0;
    
    // Rooms lists
    List<Map<String, Object>> allRoomsList = new ArrayList<>();
    List<Map<String, Object>> availableRoomsList = new ArrayList<>();
    
    // Filter parameters
    String typeFilter = request.getParameter("typeFilter");
    String statusFilter = request.getParameter("statusFilter");
    String searchQuery = request.getParameter("search");
    
    if (typeFilter == null) typeFilter = "all";
    if (statusFilter == null) statusFilter = "all";
    
    try {
        // Establish database connection
        Class.forName("com.mysql.jdbc.Driver");
        conn = DriverManager.getConnection(jdbcURL, dbUser, dbPassword);
        
        // Query for total rooms count
        String totalRoomsQuery = "SELECT COUNT(*) FROM rooms";
        pstmt = conn.prepareStatement(totalRoomsQuery);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            totalRooms = rs.getInt(1);
        }
        
        // Query for available rooms
        String availableRoomsQuery = "SELECT COUNT(*) FROM rooms WHERE status = 'available'";
        pstmt = conn.prepareStatement(availableRoomsQuery);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            availableRooms = rs.getInt(1);
        }
        
        // Query for occupied rooms
        String occupiedRoomsQuery = "SELECT COUNT(*) FROM rooms WHERE status = 'occupied'";
        pstmt = conn.prepareStatement(occupiedRoomsQuery);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            occupiedRooms = rs.getInt(1);
        }
        
        // Query for maintenance rooms
        String maintenanceRoomsQuery = "SELECT COUNT(*) FROM rooms WHERE status = 'maintenance'";
        pstmt = conn.prepareStatement(maintenanceRoomsQuery);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            maintenanceRooms = rs.getInt(1);
        }
        
        // Base query for rooms list
        StringBuilder roomsListQuery = new StringBuilder(
            "SELECT r.room_id, r.room_number, r.room_type, r.floor, r.status, r.price_per_night, " +
            "r.max_occupancy, r.description, r.amenities, r.last_cleaned, r.last_maintenance, " +
            "h.hotel_name, h.location " +
            "FROM rooms r " +
            "JOIN hotels h ON r.hotel_id = h.hotel_id " +
            "WHERE 1=1"
        );
        
        // Apply filters
        if (!"all".equals(typeFilter)) {
            roomsListQuery.append(" AND r.room_type = ?");
        }
        
        if (!"all".equals(statusFilter)) {
            roomsListQuery.append(" AND r.status = ?");
        }
        
        if (searchQuery != null && !searchQuery.trim().isEmpty()) {
            roomsListQuery.append(" AND (r.room_number LIKE ? OR r.room_type LIKE ? OR r.floor LIKE ?)");
        }
        
        // Query for all rooms
        String allRoomsQuery = roomsListQuery.toString() + " ORDER BY r.room_number ASC";
        
        pstmt = conn.prepareStatement(allRoomsQuery);
        
        int paramIndex = 1;
        
        // Set type filter parameter
        if (!"all".equals(typeFilter)) {
            pstmt.setString(paramIndex++, typeFilter);
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
        }
        
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> room = new HashMap<>();
            room.put("roomId", rs.getInt("room_id"));
            room.put("roomNumber", rs.getString("room_number"));
            room.put("roomType", rs.getString("room_type"));
            room.put("floor", rs.getString("floor"));
            room.put("status", rs.getString("status"));
            room.put("pricePerNight", rs.getDouble("price_per_night"));
            room.put("maxOccupancy", rs.getInt("max_occupancy"));
            room.put("description", rs.getString("description"));
            
            // Parse amenities from comma-separated string to list
            String amenitiesStr = rs.getString("amenities");
            List<String> amenitiesList = new ArrayList<>();
            if (amenitiesStr != null && !amenitiesStr.isEmpty()) {
                String[] amenitiesArray = amenitiesStr.split(",");
                for (String amenity : amenitiesArray) {
                    amenitiesList.add(amenity.trim());
                }
            }
            room.put("amenities", amenitiesList);
            
            // Format dates for display
            SimpleDateFormat displayDateFormat = new SimpleDateFormat("dd MMM yyyy");
            
            Timestamp lastCleaned = rs.getTimestamp("last_cleaned");
            if (lastCleaned != null) {
                room.put("lastCleaned", lastCleaned);
                room.put("formattedLastCleaned", displayDateFormat.format(lastCleaned));
            } else {
                room.put("formattedLastCleaned", "Not recorded");
            }
            
            Timestamp lastMaintenance = rs.getTimestamp("last_maintenance");
            if (lastMaintenance != null) {
                room.put("lastMaintenance", lastMaintenance);
                room.put("formattedLastMaintenance", displayDateFormat.format(lastMaintenance));
            } else {
                room.put("formattedLastMaintenance", "Not recorded");
            }
            
            room.put("hotelName", rs.getString("hotel_name"));
            room.put("location", rs.getString("location"));
            
            allRoomsList.add(room);
        }
        
        // Query for available rooms
        String availableRoomsListQuery = roomsListQuery.toString() + " AND r.status = 'available' ORDER BY r.room_number ASC LIMIT 10";
        
        pstmt = conn.prepareStatement(availableRoomsListQuery);
        
        paramIndex = 1;
        
        // Set type filter parameter
        if (!"all".equals(typeFilter)) {
            pstmt.setString(paramIndex++, typeFilter);
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
        }
        
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> room = new HashMap<>();
            room.put("roomId", rs.getInt("room_id"));
            room.put("roomNumber", rs.getString("room_number"));
            room.put("roomType", rs.getString("room_type"));
            room.put("floor", rs.getString("floor"));
            room.put("status", rs.getString("status"));
            room.put("pricePerNight", rs.getDouble("price_per_night"));
            room.put("maxOccupancy", rs.getInt("max_occupancy"));
            room.put("description", rs.getString("description"));
            
            // Parse amenities from comma-separated string to list
            String amenitiesStr = rs.getString("amenities");
            List<String> amenitiesList = new ArrayList<>();
            if (amenitiesStr != null && !amenitiesStr.isEmpty()) {
                String[] amenitiesArray = amenitiesStr.split(",");
                for (String amenity : amenitiesArray) {
                    amenitiesList.add(amenity.trim());
                }
            }
            room.put("amenities", amenitiesList);
            
            // Format dates for display
            SimpleDateFormat displayDateFormat = new SimpleDateFormat("dd MMM yyyy");
            
            Timestamp lastCleaned = rs.getTimestamp("last_cleaned");
            if (lastCleaned != null) {
                room.put("lastCleaned", lastCleaned);
                room.put("formattedLastCleaned", displayDateFormat.format(lastCleaned));
            } else {
                room.put("formattedLastCleaned", "Not recorded");
            }
            
            Timestamp lastMaintenance = rs.getTimestamp("last_maintenance");
            if (lastMaintenance != null) {
                room.put("lastMaintenance", lastMaintenance);
                room.put("formattedLastMaintenance", displayDateFormat.format(lastMaintenance));
            } else {
                room.put("formattedLastMaintenance", "Not recorded");
            }
            
            room.put("hotelName", rs.getString("hotel_name"));
            room.put("location", rs.getString("location"));
            
            availableRoomsList.add(room);
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
    <title>ZAIRTAM - Room Management</title>
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
        
        .room-badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 500;
        }
        
        .room-available {
            background-color: #ECFDF5;
            color: #065F46;
        }
        
        .room-occupied {
            background-color: #FEF3C7;
            color: #92400E;
        }
        
        .room-maintenance {
            background-color: #FEE2E2;
            color: #B91C1C;
        }
        
        .room-reserved {
            background-color: #E0F2FE;
            color: #0369A1;
        }
        
        .room-type-badge {
            display: inline-block;
            padding: 0.25rem 0.5rem;
            border-radius: 0.25rem;
            font-size: 0.75rem;
            font-weight: 500;
        }
        
        .room-standard {
            background-color: #E0F2FE;
            color: #0369A1;
        }
        
        .room-deluxe {
            background-color: #F3E8FF;
            color: #6B21A8;
        }
        
        .room-suite {
            background-color: #FEF3C7;
            color: #92400E;
        }
        
        .room-executive {
            background-color: #ECFDF5;
            color: #065F46;
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
            
            // Initialize filters
            const typeFilterSelect = document.getElementById('typeFilter');
            if (typeFilterSelect) {
                typeFilterSelect.addEventListener('change', function() {
                    document.getElementById('filterForm').submit();
                });
            }
            
            const statusFilterSelect = document.getElementById('statusFilter');
            if (statusFilterSelect) {
                statusFilterSelect.addEventListener('change', function() {
                    document.getElementById('filterForm').submit();
                });
            }
            
            // Room status update
            const statusUpdateButtons = document.querySelectorAll('.status-update-btn');
            statusUpdateButtons.forEach(button => {
                button.addEventListener('click', function() {
                    const roomId = this.getAttribute('data-room-id');
                    const newStatus = this.getAttribute('data-status');
                    
                    // Here you would typically make an AJAX call to update the room status
                    // For demo purposes, we'll just show an alert
                    alert(`Room ID ${roomId} status would be updated to ${newStatus}`);
                    
                    // Reload the page to reflect changes
                    // window.location.reload();
                });
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
                <div class="mb-4">
                    <div class="text-sm font-medium text-gray-500">Hotel</div>
                    <div class="text-base font-semibold text-gray-900"><%= hotelName %></div>
                    <div class="text-sm text-gray-500"><%= hotelLocation %></div>
                </div>
                
                <div class="mb-6">
                    <div class="text-sm font-medium text-gray-500">Employee</div>
                    <div class="text-base font-semibold text-gray-900"><%= employeeName %></div>
                    <div class="text-sm text-gray-500"><%= employeeRole %></div>
                </div>
                
                <nav class="space-y-1">
                    <a href="Dashboard.jsp" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                        <i class="fas fa-tachometer-alt w-5 h-5 mr-3 text-gray-400"></i>
                        Dashboard
                    </a>
                    <a href="Rooms.jsp" class="flex items-center px-3 py-2 text-sm font-medium text-blue-600 bg-blue-50 rounded-md">
                        <i class="fas fa-bed w-5 h-5 mr-3 text-blue-500"></i>
                        Room Management
                    </a>
                    <a href="Arrival-History.jsp" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                        <i class="fas fa-calendar-check w-5 h-5 mr-3 text-gray-400"></i>
                        Arrivals & Departures
                    </a>
                    <a href="Payment-History.jsp" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                        <i class="fas fa-credit-card w-5 h-5 mr-3 text-gray-400"></i>
                        Payment History
                    </a>
                    <a href="#" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                        <i class="fas fa-concierge-bell w-5 h-5 mr-3 text-gray-400"></i>
                        Services & Amenities
                    </a>
                    <a href="#" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                        <i class="fas fa-user-friends w-5 h-5 mr-3 text-gray-400"></i>
                        Guest Management
                    </a>
                    <a href="#" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                        <i class="fas fa-chart-line w-5 h-5 mr-3 text-gray-400"></i>
                        Reports
                    </a>
                </nav>
            </div>
        </aside>

        <!-- Main Content -->
        <main class="flex-1 p-4 sm:p-6 lg:p-8">
            <div class="mb-6">
                <h1 class="text-2xl font-bold text-gray-900">Room Management</h1>
                <p class="text-sm text-gray-500"><%= formattedDate %></p>
            </div>
            
            <!-- Stats Cards -->
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
                <div class="bg-white rounded-lg shadow-sm p-4">
                    <div class="flex items-center">
                        <div class="flex-shrink-0 bg-blue-100 rounded-full p-3">
                            <i class="fas fa-door-open text-blue-600 text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <h2 class="text-sm font-medium text-gray-500">Total Rooms</h2>
                            <p class="text-2xl font-semibold text-gray-900"><%= totalRooms %></p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-4">
                    <div class="flex items-center">
                        <div class="flex-shrink-0 bg-green-100 rounded-full p-3">
                            <i class="fas fa-check-circle text-green-600 text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <h2 class="text-sm font-medium text-gray-500">Available Rooms</h2>
                            <p class="text-2xl font-semibold text-gray-900"><%= availableRooms %></p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-4">
                    <div class="flex items-center">
                        <div class="flex-shrink-0 bg-yellow-100 rounded-full p-3">
                            <i class="fas fa-users text-yellow-600 text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <h2 class="text-sm font-medium text-gray-500">Occupied Rooms</h2>
                            <p class="text-2xl font-semibold text-gray-900"><%= occupiedRooms %></p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-4">
                    <div class="flex items-center">
                        <div class="flex-shrink-0 bg-red-100 rounded-full p-3">
                            <i class="fas fa-tools text-red-600 text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <h2 class="text-sm font-medium text-gray-500">Maintenance</h2>
                            <p class="text-2xl font-semibold text-gray-900"><%= maintenanceRooms %></p>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Filters and Search -->
            <div class="bg-white rounded-lg shadow-sm p-4 mb-6">
                <form id="filterForm" action="Rooms.jsp" method="GET" class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label for="typeFilter" class="block text-sm font-medium text-gray-700 mb-1">Room Type</label>
                        <select id="typeFilter" name="typeFilter" class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-500 focus:ring-opacity-50">
                            <option value="all" <%= "all".equals(typeFilter) ? "selected" : "" %>>All Types</option>
                            <option value="standard" <%= "standard".equals(typeFilter) ? "selected" : "" %>>Standard</option>
                            <option value="deluxe" <%= "deluxe".equals(typeFilter) ? "selected" : "" %>>Deluxe</option>
                            <option value="suite" <%= "suite".equals(typeFilter) ? "selected" : "" %>>Suite</option>
                            <option value="executive" <%= "executive".equals(typeFilter) ? "selected" : "" %>>Executive</option>
                        </select>
                    </div>
                    
                    <div>
                        <label for="statusFilter" class="block text-sm font-medium text-gray-700 mb-1">Status Filter</label>
                        <select id="statusFilter" name="statusFilter" class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-500 focus:ring-opacity-50">
                            <option value="all" <%= "all".equals(statusFilter) ? "selected" : "" %>>All Statuses</option>
                            <option value="available" <%= "available".equals(statusFilter) ? "selected" : "" %>>Available</option>
                            <option value="occupied" <%= "occupied".equals(statusFilter) ? "selected" : "" %>>Occupied</option>
                            <option value="maintenance" <%= "maintenance".equals(statusFilter) ? "selected" : "" %>>Maintenance</option>
                            <option value="reserved" <%= "reserved".equals(statusFilter) ? "selected" : "" %>>Reserved</option>
                        </select>
                    </div>
                    
                    <div>
                        <label for="search" class="block text-sm font-medium text-gray-700 mb-1">Search</label>
                        <div class="relative">
                            <input type="text" id="search" name="search" value="<%= searchQuery != null ? searchQuery : "" %>" placeholder="Room number, type, floor..." class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-500 focus:ring-opacity-50 pl-10">
                            <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                <i class="fas fa-search text-gray-400"></i>
                            </div>
                            <button type="submit" class="absolute inset-y-0 right-0 pr-3 flex items-center text-blue-600 hover:text-blue-800">
                                <i class="fas fa-arrow-right"></i>
                            </button>
                        </div>
                    </div>
                </form>
            </div>
            
            <!-- Available Rooms Section -->
            <div class="bg-white rounded-lg shadow-sm p-4 mb-6">
                <div class="flex justify-between items-center mb-4">
                    <h2 class="text-lg font-semibold text-gray-900">Available Rooms</h2>
                    <a href="#" class="text-sm text-blue-600 hover:text-blue-800">View All</a>
                </div>
                
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Room</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Floor</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Price</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Last Cleaned</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            <% if (availableRoomsList.isEmpty()) { %>
                                <tr>
                                    <td colspan="6" class="px-6 py-4 text-center text-sm text-gray-500">No available rooms found matching your criteria.</td>
                                </tr>
                            <% } else { %>
                                <% for (Map<String, Object> room : availableRoomsList) { %>
                                    <tr>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="flex items-center">
                                                <div class="flex-shrink-0 h-10 w-10 bg-blue-100 rounded-md flex items-center justify-center">
                                                    <i class="fas fa-bed text-blue-600"></i>
                                                </div>
                                                <div class="ml-4">
                                                    <div class="text-sm font-medium text-gray-900">Room <%= room.get("roomNumber") %></div>
                                                    <div class="text-sm text-gray-500">Floor <%= room.get("floor") %></div>
                                                </div>
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <% 
                                                String roomType = (String)room.get("roomType");
                                                String typeBadgeClass = "room-standard";
                                                
                                                if ("deluxe".equals(roomType)) {
                                                    typeBadgeClass = "room-deluxe";
                                                } else if ("suite".equals(roomType)) {
                                                    typeBadgeClass = "room-suite";
                                                } else if ("executive".equals(roomType)) {
                                                    typeBadgeClass = "room-executive";
                                                }
                                            %>
                                            <span class="room-type-badge <%= typeBadgeClass %>">
                                                <%= roomType.substring(0, 1).toUpperCase() + roomType.substring(1) %>
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="text-sm text-gray-900"><%= String.format("%.2f €", room.get("pricePerNight")) %></div>
                                            <div class="text-xs text-gray-500">per night</div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="text-sm text-gray-900"><%= room.get("maxOccupancy") %> Guests</div>
                                            <div class="text-xs text-gray-500">
                                                <% 
                                                    List<String> amenities = (List<String>)room.get("amenities");
                                                    if (amenities != null && !amenities.isEmpty()) {
                                                        int displayCount = Math.min(2, amenities.size());
                                                        for (int i = 0; i < displayCount; i++) {
                                                            out.print(amenities.get(i));
                                                            if (i < displayCount - 1) {
                                                                out.print(", ");
                                                            }
                                                        }
                                                        if (amenities.size() > 2) {
                                                            out.print(" + " + (amenities.size() - 2) + " more");
                                                        }
                                                    }
                                                %>
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <span class="room-badge room-available">
                                                Available
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                            <button class="bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded-md mr-2">
                                                <i class="fas fa-edit mr-1"></i> Edit
                                            </button>
                                            <div class="relative inline-block text-left">
                                                <button class="bg-gray-100 hover:bg-gray-200 text-gray-700 px-3 py-1 rounded-md dropdown-toggle">
                                                    <i class="fas fa-ellipsis-v"></i>
                                                </button>
                                                <div class="hidden origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 dropdown-menu">
                                                    <div class="py-1" role="menu" aria-orientation="vertical">
                                                        <button class="status-update-btn block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100" data-room-id="<%= room.get("roomId") %>" data-status="occupied">
                                                            <i class="fas fa-user-check mr-2 text-yellow-600"></i> Mark as Occupied
                                                        </button>
                                                        <button class="status-update-btn block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100" data-room-id="<%= room.get("roomId") %>" data-status="maintenance">
                                                            <i class="fas fa-tools mr-2 text-red-600"></i> Mark for Maintenance
                                                        </button>
                                                        <button class="status-update-btn block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100" data-room-id="<%= room.get("roomId") %>" data-status="reserved">
                                                            <i class="fas fa-calendar-check mr-2 text-blue-600"></i> Mark as Reserved
                                                        </button>
                                                        <button class="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                                                            <i class="fas fa-broom mr-2 text-green-600"></i> Update Cleaning Status
                                                        </button>
                                                    </div>
                                                </div>
                                            </div>
                                        </td>
                                    </tr>
                                <% } %>
                            <% } %>
                        </tbody>
                    </table>
                </div>
                
                <% if (!availableRoomsList.isEmpty()) { %>
                    <div class="px-6 py-4 bg-gray-50 border-t border-gray-200 flex items-center justify-between">
                        <div class="text-sm text-gray-500">
                            Showing <span class="font-medium"><%= availableRoomsList.size() %></span> available rooms
                        </div>
                        <div>
                            <a href="#" class="text-blue-600 hover:text-blue-800 text-sm font-medium">
                                View All Available Rooms <i class="fas fa-arrow-right ml-1"></i>
                            </a>
                        </div>
                    </div>
                <% } %>
            </div>
            
            <!-- All Rooms Section -->
            <div class="bg-white rounded-lg shadow-sm">
                <div class="p-6 border-b border-gray-200">
                    <div class="flex items-center justify-between">
                        <h3 class="text-lg font-semibold text-gray-800">All Rooms</h3>
                        <button class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium">
                            <i class="fas fa-plus mr-2"></i> Add New Room
                        </button>
                    </div>
                </div>
                
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Room
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Type
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Price
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Capacity
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Status
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Last Cleaned
                                </th>
                                <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Actions
                                </th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            <% if (allRoomsList.isEmpty()) { %>
                                <tr>
                                    <td colspan="7" class="px-6 py-4 text-center text-sm text-gray-500">No rooms found matching your criteria.</td>
                                </tr>
                            <% } else { %>
                                <% for (Map<String, Object> room : allRoomsList) { %>
                                    <tr>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="flex items-center">
                                                <div class="flex-shrink-0 h-10 w-10 bg-blue-100 rounded-md flex items-center justify-center">
                                                    <i class="fas fa-bed text-blue-600"></i>
                                                </div>
                                                <div class="ml-4">
                                                    <div class="text-sm font-medium text-gray-900">Room <%= room.get("roomNumber") %></div>
                                                    <div class="text-sm text-gray-500">Floor <%= room.get("floor") %></div>
                                                </div>
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <% 
                                                String roomType = (String)room.get("roomType");
                                                String typeBadgeClass = "room-standard";
                                                
                                                if ("deluxe".equals(roomType)) {
                                                    typeBadgeClass = "room-deluxe";
                                                } else if ("suite".equals(roomType)) {
                                                    typeBadgeClass = "room-suite";
                                                } else if ("executive".equals(roomType)) {
                                                    typeBadgeClass = "room-executive";
                                                }
                                            %>
                                            <span class="room-type-badge <%= typeBadgeClass %>">
                                                <%= roomType.substring(0, 1).toUpperCase() + roomType.substring(1) %>
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="text-sm text-gray-900"><%= String.format("%.2f €", room.get("pricePerNight")) %></div>
                                            <div class="text-xs text-gray-500">per night</div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="text-sm text-gray-900"><%= room.get("maxOccupancy") %> Guests</div>
                                            <div class="text-xs text-gray-500">
                                                <% 
                                                    List<String> amenities = (List<String>)room.get("amenities");
                                                    if (amenities != null && !amenities.isEmpty()) {
                                                        int displayCount = Math.min(2, amenities.size());
                                                        for (int i = 0; i < displayCount; i++) {
                                                            out.print(amenities.get(i));
                                                            if (i < displayCount - 1) {
                                                                out.print(", ");
                                                            }
                                                        }
                                                        if (amenities.size() > 2) {
                                                            out.print(" + " + (amenities.size() - 2) + " more");
                                                        }
                                                    }
                                                %>
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <% 
                                                String status = (String)room.get("status");
                                                String statusBadgeClass = "room-available";
                                                
                                                if ("occupied".equals(status)) {
                                                    statusBadgeClass = "room-occupied";
                                                } else if ("maintenance".equals(status)) {
                                                    statusBadgeClass = "room-maintenance";
                                                } else if ("reserved".equals(status)) {
                                                    statusBadgeClass = "room-reserved";
                                                }
                                            %>
                                            <span class="room-badge <%= statusBadgeClass %>">
                                                <%= status.substring(0, 1).toUpperCase() + status.substring(1) %>
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="text-sm text-gray-900"><%= room.get("formattedLastCleaned") %></div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                            <button class="bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded-md mr-2">
                                                <i class="fas fa-edit mr-1"></i> Edit
                                            </button>
                                            <div class="relative inline-block text-left">
                                                <button class="bg-gray-100 hover:bg-gray-200 text-gray-700 px-3 py-1 rounded-md dropdown-toggle">
                                                    <i class="fas fa-ellipsis-v"></i>
                                                </button>
                                                <div class="hidden origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 dropdown-menu">
                                                    <div class="py-1" role="menu" aria-orientation="vertical">
                                                        <% if (!"occupied".equals(status)) { %>
                                                            <button class="status-update-btn block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100" data-room-id="<%= room.get("roomId") %>" data-status="occupied">
                                                                <i class="fas fa-user-check mr-2 text-yellow-600"></i> Mark as Occupied
                                                            </button>
                                                        <% } %>
                                                        <% if (!"available".equals(status)) { %>
                                                            <button class="status-update-btn block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100" data-room-id="<%= room.get("roomId") %>" data-status="available">
                                                                <i class="fas fa-check-circle mr-2 text-green-600"></i> Mark as Available
                                                            </button>
                                                        <% } %>
                                                        <% if (!"maintenance".equals(status)) { %>
                                                            <button class="status-update-btn block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100" data-room-id="<%= room.get("roomId") %>" data-status="maintenance">
                                                                <i class="fas fa-tools mr-2 text-red-600"></i> Mark for Maintenance
                                                            </button>
                                                        <% } %>
                                                        <% if (!"reserved".equals(status)) { %>
                                                            <button class="status-update-btn block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100" data-room-id="<%= room.get("roomId") %>" data-status="reserved">
                                                                <i class="fas fa-calendar-check mr-2 text-blue-600"></i> Mark as Reserved
                                                            </button>
                                                        <% } %>
                                                        <button class="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                                                            <i class="fas fa-broom mr-2 text-green-600"></i> Update Cleaning Status
                                                        </button>
                                                    </div>
                                                </div>
                                            </div>
                                        </td>
                                    </tr>
                                <% } %>
                            <% } %>
                        </tbody>
                    </table>
                </div>
                
                <div class="px-6 py-4 bg-gray-50 border-t border-gray-200 flex items-center justify-between">
                    <div class="text-sm text-gray-500">
                        Showing <span class="font-medium"><%= allRoomsList.size() %></span> of <span class="font-medium"><%= totalRooms %></span> rooms
                    </div>
                    <div class="flex-1 flex justify-between sm:justify-end">
                        <a href="#" class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                            Previous
                        </a>
                        <a href="#" class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                            Next
                        </a>
                    </div>
                </div>
            </div>
        </main>
    </div>

    <!-- JavaScript for Functionality -->
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Dropdown toggle
            const dropdownToggles = document.querySelectorAll('.dropdown-toggle');
            dropdownToggles.forEach(toggle => {
                toggle.addEventListener('click', function(e) {
                    e.stopPropagation();
                    const menu = this.nextElementSibling;
                    menu.classList.toggle('hidden');
                    
                    // Close other open dropdowns
                    document.querySelectorAll('.dropdown-menu').forEach(dropdown => {
                        if (dropdown !== menu && !dropdown.classList.contains('hidden')) {
                            dropdown.classList.add('hidden');
                        }
                    });
                });
            });
            
            // Close dropdowns when clicking outside
            document.addEventListener('click', function() {
                document.querySelectorAll('.dropdown-menu').forEach(dropdown => {
                    dropdown.classList.add('hidden');
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