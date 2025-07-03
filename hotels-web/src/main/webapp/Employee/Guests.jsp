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
    
    // Guest information (would normally come from session)
    String guestName = "";
    String guestEmail = "";
    String guestImage = "https://randomuser.me/api/portraits/men/32.jpg";
    
    // Check if user is logged in
    String userId = (String) session.getAttribute("userId");
    if (userId != null) {
        try {
            // Establish database connection
            Class.forName("com.mysql.jdbc.Driver");
            conn = DriverManager.getConnection(jdbcURL, dbUser, dbPassword);
            
            // Fetch user information
            String userQuery = "SELECT * FROM users WHERE id = ?";
            pstmt = conn.prepareStatement(userQuery);
            pstmt.setString(1, userId);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                guestName = rs.getString("first_name") + " " + rs.getString("last_name");
                guestEmail = rs.getString("email");
                if (rs.getString("profile_image") != null && !rs.getString("profile_image").isEmpty()) {
                    guestImage = rs.getString("profile_image");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                if (rs != null) rs.close();
                if (pstmt != null) pstmt.close();
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
    
    // Hotel information
    String hotelName = "ZAIRTAM Grand Hotel";
    String hotelLocation = "Paris, France";
    
    // Room statistics
    int totalRooms = 0;
    int availableRooms = 0;
    
    // Rooms lists
    List<Map<String, Object>> availableRoomsList = new ArrayList<>();
    
    // Filter parameters
    String typeFilter = request.getParameter("typeFilter");
    String priceFilter = request.getParameter("priceFilter");
    String searchQuery = request.getParameter("search");
    String checkInDate = request.getParameter("checkInDate");
    String checkOutDate = request.getParameter("checkOutDate");
    String guestsCount = request.getParameter("guestsCount");
    
    if (typeFilter == null) typeFilter = "all";
    if (priceFilter == null) priceFilter = "all";
    if (guestsCount == null) guestsCount = "1";
    
    // Default dates if not provided
    if (checkInDate == null || checkInDate.isEmpty()) {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
        Calendar cal = Calendar.getInstance();
        checkInDate = sdf.format(cal.getTime());
        
        cal.add(Calendar.DATE, 1);
        checkOutDate = sdf.format(cal.getTime());
    }
    
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
        
        // Base query for available rooms list
        StringBuilder roomsListQuery = new StringBuilder(
            "SELECT r.room_id, r.room_number, r.room_type, r.floor, r.status, r.price_per_night, " +
            "r.max_occupancy, r.description, r.amenities, r.last_cleaned, " +
            "h.hotel_name, h.location, h.hotel_id, h.image_url " +
            "FROM rooms r " +
            "JOIN hotels h ON r.hotel_id = h.hotel_id " +
            "WHERE r.status = 'available'"
        );
        
        // Apply filters
        if (!"all".equals(typeFilter)) {
            roomsListQuery.append(" AND r.room_type = ?");
        }
        
        if (!"all".equals(priceFilter)) {
            if ("0-100".equals(priceFilter)) {
                roomsListQuery.append(" AND r.price_per_night BETWEEN 0 AND 100");
            } else if ("100-200".equals(priceFilter)) {
                roomsListQuery.append(" AND r.price_per_night BETWEEN 100 AND 200");
            } else if ("200-300".equals(priceFilter)) {
                roomsListQuery.append(" AND r.price_per_night BETWEEN 200 AND 300");
            } else if ("300+".equals(priceFilter)) {
                roomsListQuery.append(" AND r.price_per_night > 300");
            }
        }
        
        if (searchQuery != null && !searchQuery.trim().isEmpty()) {
            roomsListQuery.append(" AND (r.room_number LIKE ? OR r.room_type LIKE ? OR h.hotel_name LIKE ? OR h.location LIKE ?)");
        }
        
        // Filter by occupancy
        if (guestsCount != null && !guestsCount.isEmpty()) {
            try {
                int guests = Integer.parseInt(guestsCount);
                roomsListQuery.append(" AND r.max_occupancy >= ?");
            } catch (NumberFormatException e) {
                // Invalid number, ignore filter
            }
        }
        
        // Check if room is not booked for the selected dates
        if (checkInDate != null && !checkInDate.isEmpty() && checkOutDate != null && !checkOutDate.isEmpty()) {
            roomsListQuery.append(" AND r.room_id NOT IN (SELECT room_id FROM bookings WHERE " +
                                 "((check_in_date <= ? AND check_out_date >= ?) OR " +
                                 "(check_in_date <= ? AND check_out_date >= ?) OR " +
                                 "(check_in_date >= ? AND check_out_date <= ?)) " +
                                 "AND status IN ('confirmed', 'checked_in'))");
        }
        
        // Order by price
        roomsListQuery.append(" ORDER BY r.price_per_night ASC");
        
        // Query for available rooms
        String availableRoomsListQuery = roomsListQuery.toString();
        
        pstmt = conn.prepareStatement(availableRoomsListQuery);
        
        int paramIndex = 1;
        
        // Set type filter parameter
        if (!"all".equals(typeFilter)) {
            pstmt.setString(paramIndex++, typeFilter);
        }
        
        // Set search parameters
        if (searchQuery != null && !searchQuery.trim().isEmpty()) {
            String searchPattern = "%" + searchQuery.trim() + "%";
            pstmt.setString(paramIndex++, searchPattern);
            pstmt.setString(paramIndex++, searchPattern);
            pstmt.setString(paramIndex++, searchPattern);
            pstmt.setString(paramIndex++, searchPattern);
        }
        
        // Set guests count parameter
        if (guestsCount != null && !guestsCount.isEmpty()) {
            try {
                int guests = Integer.parseInt(guestsCount);
                pstmt.setInt(paramIndex++, guests);
            } catch (NumberFormatException e) {
                // Invalid number, ignore filter
            }
        }
        
        // Set date parameters for booking check
        if (checkInDate != null && !checkInDate.isEmpty() && checkOutDate != null && !checkOutDate.isEmpty()) {
            pstmt.setString(paramIndex++, checkOutDate);  // End date of booking must be after our check-in
            pstmt.setString(paramIndex++, checkInDate);   // Start date of booking must be before our check-out
            pstmt.setString(paramIndex++, checkInDate);   // Our check-in must be after booking start
            pstmt.setString(paramIndex++, checkOutDate);  // Our check-out must be before booking end
            pstmt.setString(paramIndex++, checkInDate);   // Booking start must be after our check-in
            pstmt.setString(paramIndex++, checkOutDate);  // Booking end must be before our check-out
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
            room.put("hotelId", rs.getInt("hotel_id"));
            room.put("hotelName", rs.getString("hotel_name"));
            room.put("location", rs.getString("location"));
            room.put("hotelImage", rs.getString("image_url"));
            
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
                room.put("formattedLastCleaned", "Recently cleaned");
            }
            
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
    <title>ZAIRTAM - Available Rooms</title>
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
        
        .hotel-card {
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        
        .hotel-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
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
            
            const priceFilterSelect = document.getElementById('priceFilter');
            if (priceFilterSelect) {
                priceFilterSelect.addEventListener('change', function() {
                    document.getElementById('filterForm').submit();
                });
            }
            
            // Date range picker initialization
            const checkInDateInput = document.getElementById('checkInDate');
            const checkOutDateInput = document.getElementById('checkOutDate');
            
            if (checkInDateInput && checkOutDateInput) {
                checkInDateInput.addEventListener('change', function() {
                    // Ensure check-out date is after check-in date
                    const checkInDate = new Date(this.value);
                    const checkOutDate = new Date(checkOutDateInput.value);
                    
                    if (checkOutDate <= checkInDate) {
                        // Set check-out date to day after check-in
                        checkInDate.setDate(checkInDate.getDate() + 1);
                        const year = checkInDate.getFullYear();
                        const month = String(checkInDate.getMonth() + 1).padStart(2, '0');
                        const day = String(checkInDate.getDate()).padStart(2, '0');
                        checkOutDateInput.value = `${year}-${month}-${day}`;
                    }
                });
            }
            
            // Book now buttons
            const bookButtons = document.querySelectorAll('.book-now-btn');
            bookButtons.forEach(button => {
                button.addEventListener('click', function(e) {
                    e.preventDefault();
                    const roomId = this.getAttribute('data-room-id');
                    const checkIn = document.getElementById('checkInDate').value;
                    const checkOut = document.getElementById('checkOutDate').value;
                    const guests = document.getElementById('guestsCount').value;
                    
                    // Redirect to booking page with parameters
                    window.location.href = `Booking.jsp?roomId=${roomId}&checkIn=${checkIn}&checkOut=${checkOut}&guests=${guests}`;
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
                    <% if (userId != null) { %>
                        <a href="Reservations.jsp" class="text-gray-500 hover:text-gray-700">
                            <i class="fas fa-calendar-check text-xl"></i>
                        </a>
                        <div class="relative">
                            <button class="flex items-center text-gray-800 hover:text-blue-600">
                                <img src="<%= guestImage %>" alt="Profile" class="h-8 w-8 rounded-full object-cover">
                                <span class="ml-2 hidden md:block"><%= guestName %></span>
                                <i class="fas fa-chevron-down ml-1 text-xs hidden md:block"></i>
                            </button>
                        </div>
                    <% } else { %>
                        <a href="../login.jsp" class="text-gray-600 hover:text-blue-600">
                            <i class="fas fa-sign-in-alt mr-1"></i> Login
                        </a>
                        <a href="../register.jsp" class="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
                            Register
                        </a>
                    <% } %>
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
                
                <% if (userId != null) { %>
                <div class="mb-6">
                    <div class="text-sm font-medium text-gray-500">Guest</div>
                    <div class="text-base font-semibold text-gray-900"><%= guestName %></div>
                    <div class="text-sm text-gray-500"><%= guestEmail %></div>
                </div>
                <% } %>
                
                <nav class="space-y-1">
                    <a href="index.jsp" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                        <i class="fas fa-home w-5 h-5 mr-3 text-gray-400"></i>
                        Home
                    </a>
                    <a href="Guests.jsp" class="flex items-center px-3 py-2 text-sm font-medium text-blue-600 bg-blue-50 rounded-md">
                        <i class="fas fa-bed w-5 h-5 mr-3 text-blue-500"></i>
                        Browse Rooms
                    </a>
                    <% if (userId != null) { %>
                    <a href="Reservations.jsp" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                        <i class="fas fa-calendar-check w-5 h-5 mr-3 text-gray-400"></i>
                        My Reservations
                    </a>
                    <a href="Profile.jsp" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                        <i class="fas fa-user w-5 h-5 mr-3 text-gray-400"></i>
                        My Profile
                    </a>
                    <a href="Account-Settings.jsp" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                        <i class="fas fa-cog w-5 h-5 mr-3 text-gray-400"></i>
                        Account Settings
                    </a>
                    <a href="Payment-Methods.jsp" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                        <i class="fas fa-credit-card w-5 h-5 mr-3 text-gray-400"></i>
                        Payment Methods
                    </a>
                    <% } else { %>
                    <a href="../login.jsp" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                        <i class="fas fa-sign-in-alt w-5 h-5 mr-3 text-gray-400"></i>
                        Login
                    </a>
                    <a href="../register.jsp" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                        <i class="fas fa-user-plus w-5 h-5 mr-3 text-gray-400"></i>
                        Register
                    </a>
                    <% } %>
                </nav>
            </div>
        </aside>

        <!-- Main Content -->
        <main class="flex-1 p-4 sm:p-6 lg:p-8">
            <div class="mb-6">
                <h1 class="text-2xl font-bold text-gray-900">Available Rooms</h1>
                <p class="text-gray-600">Find and book your perfect room for your stay</p>
            </div>
            
            <!-- Search and Filter Section -->
            <div class="bg-white rounded-lg shadow-sm p-4 mb-6">
                <form id="filterForm" action="Guests.jsp" method="GET" class="space-y-4">
                    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                        <div>
                            <label for="checkInDate" class="block text-sm font-medium text-gray-700 mb-1">Check-in Date</label>
                            <input type="date" id="checkInDate" name="checkInDate" value="<%= checkInDate %>" 
                                   class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                        </div>
                        <div>
                            <label for="checkOutDate" class="block text-sm font-medium text-gray-700 mb-1">Check-out Date</label>
                            <input type="date" id="checkOutDate" name="checkOutDate" value="<%= checkOutDate %>" 
                                   class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                        </div>
                        <div>
                            <label for="guestsCount" class="block text-sm font-medium text-gray-700 mb-1">Guests</label>
                            <select id="guestsCount" name="guestsCount" 
                                    class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                                <option value="1" <%= "1".equals(guestsCount) ? "selected" : "" %>>1 Guest</option>
                                <option value="2" <%= "2".equals(guestsCount) ? "selected" : "" %>>2 Guests</option>
                                <option value="3" <%= "3".equals(guestsCount) ? "selected" : "" %>>3 Guests</option>
                                <option value="4" <%= "4".equals(guestsCount) ? "selected" : "" %>>4 Guests</option>
                                <option value="5" <%= "5".equals(guestsCount) ? "selected" : "" %>>5+ Guests</option>
                            </select>
                        </div>
                        <div>
                            <label for="search" class="block text-sm font-medium text-gray-700 mb-1">Search</label>
                            <div class="relative">
                                <input type="text" id="search" name="search" value="<%= searchQuery != null ? searchQuery : "" %>" 
                                       placeholder="Search rooms, amenities..." 
                                       class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 pl-10">
                                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                    <i class="fas fa-search text-gray-400"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                        <div>
                            <label for="typeFilter" class="block text-sm font-medium text-gray-700 mb-1">Room Type</label>
                            <select id="typeFilter" name="typeFilter" 
                                    class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                                <option value="all" <%= "all".equals(typeFilter) ? "selected" : "" %>>All Types</option>
                                <option value="standard" <%= "standard".equals(typeFilter) ? "selected" : "" %>>Standard</option>
                                <option value="deluxe" <%= "deluxe".equals(typeFilter) ? "selected" : "" %>>Deluxe</option>
                                <option value="suite" <%= "suite".equals(typeFilter) ? "selected" : "" %>>Suite</option>
                                <option value="executive" <%= "executive".equals(typeFilter) ? "selected" : "" %>>Executive</option>
                            </select>
                        </div>
                        <div>
                            <label for="priceFilter" class="block text-sm font-medium text-gray-700 mb-1">Price Range</label>
                            <select id="priceFilter" name="priceFilter" 
                                    class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                                <option value="all" <%= "all".equals(priceFilter) ? "selected" : "" %>>All Prices</option>
                                <option value="0-100" <%= "0-100".equals(priceFilter) ? "selected" : "" %>>€0 - €100</option>
                                <option value="100-200" <%= "100-200".equals(priceFilter) ? "selected" : "" %>>€100 - €200</option>
                                <option value="200-300" <%= "200-300".equals(priceFilter) ? "selected" : "" %>>€200 - €300</option>
                                <option value="300+" <%= "300+".equals(priceFilter) ? "selected" : "" %>>€300+</option>
                            </select>
                        </div>
                        <div class="flex items-end">
                            <button type="submit" class="w-full bg-blue-600 hover:bg-blue-700 text-white py-2 px-4 rounded-md">
                                <i class="fas fa-search mr-2"></i> Search Rooms
                            </button>
                        </div>
                    </div>
                </form>
            </div>
            
            <!-- Statistics Cards -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
                <div class="bg-white rounded-lg shadow-sm p-4">
                    <div class="flex items-center">
                        <div class="flex-shrink-0 bg-blue-100 rounded-md p-3">
                            <i class="fas fa-bed text-blue-600 text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <h2 class="text-sm font-medium text-gray-500">Available Rooms</h2>
                            <p class="text-lg font-semibold text-gray-900"><%= availableRooms %> of <%= totalRooms %></p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-4">
                    <div class="flex items-center">
                        <div class="flex-shrink-0 bg-green-100 rounded-md p-3">
                            <i class="fas fa-calendar-alt text-green-600 text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <h2 class="text-sm font-medium text-gray-500">Your Stay</h2>
                            <p class="text-lg font-semibold text-gray-900">
                                <% 
                                    if (checkInDate != null && checkOutDate != null) {
                                        SimpleDateFormat displayFormat = new SimpleDateFormat("MMM dd");
                                        SimpleDateFormat parseFormat = new SimpleDateFormat("yyyy-MM-dd");
                                        try {
                                            Date checkIn = parseFormat.parse(checkInDate);
                                            Date checkOut = parseFormat.parse(checkOutDate);
                                            
                                            // Calculate nights
                                            long diffInMillies = checkOut.getTime() - checkIn.getTime();
                                            int nights = (int) (diffInMillies / (1000 * 60 * 60 * 24));
                                            
                                            out.print(displayFormat.format(checkIn) + " - " + displayFormat.format(checkOut) + " · " + nights + " night" + (nights > 1 ? "s" : ""));
                                        } catch (Exception e) {
                                            out.print("Select dates");
                                        }
                                    } else {
                                        out.print("Select dates");
                                    }
                                %>
                            </p>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Search and Filter Section -->
            <div class="bg-white rounded-lg shadow-sm mb-6">
                <div class="p-4 border-b border-gray-200">
                    <h3 class="text-lg font-semibold text-gray-800">Find Your Perfect Room</h3>
                </div>
                
                <div class="p-4">
                    <form id="filterForm" action="Guests.jsp" method="GET" class="space-y-4">
                        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
                            <div>
                                <label for="checkInDate" class="block text-sm font-medium text-gray-700 mb-1">Check-in Date</label>
                                <input type="date" id="checkInDate" name="checkInDate" value="<%= checkInDate %>" 
                                       class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                            </div>
                            
                            <div>
                                <label for="checkOutDate" class="block text-sm font-medium text-gray-700 mb-1">Check-out Date</label>
                                <input type="date" id="checkOutDate" name="checkOutDate" value="<%= checkOutDate %>" 
                                       class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                            </div>
                            
                            <div>
                                <label for="guestsCount" class="block text-sm font-medium text-gray-700 mb-1">Guests</label>
                                <select id="guestsCount" name="guestsCount" 
                                        class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                                    <% for (int i = 1; i <= 6; i++) { %>
                                        <option value="<%= i %>" <%= guestsCount.equals(String.valueOf(i)) ? "selected" : "" %>><%= i %> <%= i == 1 ? "Guest" : "Guests" %></option>
                                    <% } %>
                                </select>
                            </div>
                            
                            <div>
                                <label for="search" class="block text-sm font-medium text-gray-700 mb-1">Search</label>
                                <div class="relative">
                                    <input type="text" id="search" name="search" value="<%= searchQuery != null ? searchQuery : "" %>" 
                                           placeholder="Search rooms, amenities..." 
                                           class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 pl-10">
                                    <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                        <i class="fas fa-search text-gray-400"></i>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                            <div>
                                <label for="typeFilter" class="block text-sm font-medium text-gray-700 mb-1">Room Type</label>
                                <select id="typeFilter" name="typeFilter" 
                                        class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                                    <option value="all" <%= "all".equals(typeFilter) ? "selected" : "" %>>All Types</option>
                                    <option value="standard" <%= "standard".equals(typeFilter) ? "selected" : "" %>>Standard</option>
                                    <option value="deluxe" <%= "deluxe".equals(typeFilter) ? "selected" : "" %>>Deluxe</option>
                                    <option value="suite" <%= "suite".equals(typeFilter) ? "selected" : "" %>>Suite</option>
                                    <option value="executive" <%= "executive".equals(typeFilter) ? "selected" : "" %>>Executive</option>
                                </select>
                            </div>
                            
                            <div>
                                <label for="priceFilter" class="block text-sm font-medium text-gray-700 mb-1">Price Range</label>
                                <select id="priceFilter" name="priceFilter" 
                                        class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                                    <option value="all" <%= "all".equals(priceFilter) ? "selected" : "" %>>All Prices</option>
                                    <option value="0-100" <%= "0-100".equals(priceFilter) ? "selected" : "" %>>€0 - €100</option>
                                    <option value="100-200" <%= "100-200".equals(priceFilter) ? "selected" : "" %>>€100 - €200</option>
                                    <option value="200-300" <%= "200-300".equals(priceFilter) ? "selected" : "" %>>€200 - €300</option>
                                    <option value="300+" <%= "300+".equals(priceFilter) ? "selected" : "" %>>€300+</option>
                                </select>
                            </div>
                            
                            <div class="flex items-end">
                                <button type="submit" class="w-full bg-blue-600 hover:bg-blue-700 text-white py-2 px-4 rounded-md">
                                    <i class="fas fa-search mr-2"></i> Search Rooms
                                </button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
            
            <!-- Available Rooms Section -->
            <div class="mb-6">
                <h2 class="text-xl font-bold text-gray-800 mb-4">Available Rooms</h2>
                
                <% if (availableRoomsList.isEmpty()) { %>
                    <div class="bg-white rounded-lg shadow-sm p-6 text-center">
                        <div class="text-gray-500 mb-4">
                            <i class="fas fa-bed text-4xl"></i>
                        </div>
                        <h3 class="text-lg font-medium text-gray-900 mb-2">No Available Rooms Found</h3>
                        <p class="text-gray-500 mb-4">Try adjusting your search criteria or dates to find available rooms.</p>
                        <button onclick="document.getElementById('filterForm').reset();" class="text-blue-600 hover:text-blue-800">
                            <i class="fas fa-redo mr-1"></i> Reset Filters
                        </button>
                    </div>
                <% } else { %>
                    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        <% for (Map<String, Object> room : availableRoomsList) { %>
                            <div class="bg-white rounded-lg shadow-sm overflow-hidden hotel-card">
                                <div class="relative h-48 bg-gray-200">
                                    <img src="<%= room.get("hotelImage") != null ? room.get("hotelImage") : "../assets/images/room-placeholder.jpg" %>" 
                                         alt="<%= room.get("roomType") %> Room" 
                                         class="w-full h-full object-cover">
                                    <div class="absolute top-0 right-0 m-2">
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
                                    </div>
                                </div>
                                
                                <div class="p-4">
                                    <div class="flex justify-between items-start mb-2">
                                        <h3 class="text-lg font-semibold text-gray-900">Room <%= room.get("roomNumber") %></h3>
                                        <span class="text-lg font-bold text-blue-600">€<%= String.format("%.2f", room.get("pricePerNight")) %></span>
                                    </div>
                                    
                                    <p class="text-sm text-gray-500 mb-3"><%= room.get("hotelName") %> - <%= room.get("location") %></p>
                                    
                                    <div class="mb-3">
                                        <p class="text-sm text-gray-600 line-clamp-2"><%= room.get("description") %></p>
                                    </div>
                                    
                                    <div class="flex flex-wrap gap-2 mb-4">
                                        <% 
                                            List<String> amenities = (List<String>)room.get("amenities");
                                            if (amenities != null) {
                                                int displayCount = Math.min(3, amenities.size());
                                                for (int i = 0; i < displayCount; i++) {
                                        %>
                                            <span class="inline-flex items-center px-2 py-1 bg-gray-100 text-xs text-gray-800 rounded">
                                                <% 
                                                    String amenity = amenities.get(i);
                                                    String iconClass = "fa-check";
                                                    
                                                    if (amenity.toLowerCase().contains("wifi")) {
                                                        iconClass = "fa-wifi";
                                                    } else if (amenity.toLowerCase().contains("tv")) {
                                                        iconClass = "fa-tv";
                                                    } else if (amenity.toLowerCase().contains("breakfast")) {
                                                        iconClass = "fa-coffee";
                                                    } else if (amenity.toLowerCase().contains("air")) {
                                                        iconClass = "fa-snowflake";
                                                    } else if (amenity.toLowerCase().contains("bath")) {
                                                        iconClass = "fa-bath";
                                                    }
                                                %>
                                                <i class="fas <%= iconClass %> mr-1"></i> <%= amenity %>
                                            </span>
                                        <% 
                                                }
                                                if (amenities.size() > 3) {
                                        %>
                                            <span class="inline-flex items-center px-2 py-1 bg-gray-100 text-xs text-gray-800 rounded">
                                                +<%= amenities.size() - 3 %> more
                                            </span>
                                        <% 
                                                }
                                            }
                                        %>
                                    </div>
                                    
                                    <div class="flex items-center justify-between">
                                        <div class="text-sm text-gray-500">
                                            <i class="fas fa-user mr-1"></i> Up to <%= room.get("maxOccupancy") %> guests
                                        </div>
                                        <button class="book-now-btn bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium" 
                                                data-room-id="<%= room.get("roomId") %>">
                                            Book Now
                                        </button>
                                    </div>
                                </div>
                            </div>
                        <% } %>
                    </div>
                <% } %>
            </div>
            
            <!-- Why Choose Us Section -->
            <div class="bg-white rounded-lg shadow-sm p-6 mb-6">
                <h2 class="text-xl font-bold text-gray-800 mb-4">Why Choose ZAIRTAM Hotels</h2>
                
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div class="text-center">
                        <div class="inline-flex items-center justify-center h-12 w-12 rounded-full bg-blue-100 text-blue-600 mb-4">
                            <i class="fas fa-medal text-xl"></i>
                        </div>
                        <h3 class="text-lg font-medium text-gray-900 mb-2">Best Price Guarantee</h3>
                        <p class="text-gray-500">Find a lower price? We'll match it and give you an additional 10% off.</p>
                    </div>
                    
                    <div class="text-center">
                        <div class="inline-flex items-center justify-center h-12 w-12 rounded-full bg-blue-100 text-blue-600 mb-4">
                            <i class="fas fa-calendar-check text-xl"></i>
                        </div>
                        <h3 class="text-lg font-medium text-gray-900 mb-2">Free Cancellation</h3>
                        <p class="text-gray-500">Plans change. That's why we offer free cancellation on most rooms.</p>
                    </div>
                    
                    <div class="text-center">
                        <div class="inline-flex items-center justify-center h-12 w-12 rounded-full bg-blue-100 text-blue-600 mb-4">
                            <i class="fas fa-concierge-bell text-xl"></i>
                        </div>
                        <h3 class="text-lg font-medium text-gray-900 mb-2">24/7 Customer Service</h3>
                        <p class="text-gray-500">Our friendly staff is available around the clock to assist you.</p>
                    </div>
                </div>
            </div>
            
            <!-- Footer -->
            <footer class="bg-white rounded-lg shadow-sm p-6">
                <div class="flex flex-col md:flex-row justify-between items-center">
                    <div class="mb-4 md:mb-0">
                        <div class="flex items-center">
                            <i class="fas fa-hotel text-blue-600 text-2xl mr-2"></i>
                            <span class="text-xl font-bold text-gray-800">ZAIRTAM</span>
                        </div>
                        <p class="text-sm text-gray-500 mt-2">© 2023 ZAIRTAM Hotels. All rights reserved.</p>
                    </div>
                    
                    <div class="flex space-x-4">
                        <a href="#" class="text-gray-400 hover:text-blue-600">
                            <i class="fab fa-facebook-f text-xl"></i>
                        </a>
                        <a href="#" class="text-gray-400 hover:text-blue-600">
                            <i class="fab fa-twitter text-xl"></i>
                        </a>
                        <a href="#" class="text-gray-400 hover:text-blue-600">
                            <i class="fab fa-instagram text-xl"></i>
                        </a>
                        <a href="#" class="text-gray-400 hover:text-blue-600">
                            <i class="fab fa-linkedin-in text-xl"></i>
                        </a>
                    </div>
                </div>
                
                <div class="mt-6 border-t border-gray-200 pt-6">
                    <div class="flex flex-wrap justify-center space-x-6">
                        <a href="#" class="text-sm text-gray-500 hover:text-blue-600 mb-2">About Us</a>
                        <a href="#" class="text-sm text-gray-500 hover:text-blue-600 mb-2">Contact</a>
                        <a href="#" class="text-sm text-gray-500 hover:text-blue-600 mb-2">Terms & Conditions</a>
                        <a href="#" class="text-sm text-gray-500 hover:text-blue-600 mb-2">Privacy Policy</a>
                        <a href="#" class="text-sm text-gray-500 hover:text-blue-600 mb-2">FAQs</a>
                    </div>
                </div>
            </footer>
        </main>
    </div>
</body>
</html>