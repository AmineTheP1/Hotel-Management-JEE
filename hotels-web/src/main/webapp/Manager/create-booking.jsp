<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="java.sql.Connection,java.sql.DriverManager,java.sql.PreparedStatement,java.sql.ResultSet,java.sql.SQLException,java.sql.Timestamp" %>
<%@ page import="java.util.Calendar,java.util.List,java.util.Map,java.util.ArrayList,java.util.HashMap,java.util.Date,java.text.SimpleDateFormat" %>

<%
    // Database connection parameters
    String url = "jdbc:mysql://localhost:4200/hotel?useSSL=false";
    String username = "root";
    String password = "Hamza_13579";
    
    // User information - Get from session if available
    String adminName = (String) session.getAttribute("adminName");
    String adminImage = (String) session.getAttribute("adminImage");
    
    // Set default values if not in session
    if (adminName == null) adminName = "Admin";
    if (adminImage == null) adminImage = "";
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // Lists to store data
    List<Map<String, Object>> hotelsList = new ArrayList<>();
    List<Map<String, Object>> usersList = new ArrayList<>();
    
    // Message variables
    String successMessage = "";
    String errorMessage = "";
    
    // Process form submission
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        try {
            // Establish database connection
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(url, username, password);
            
            // Get form data
            long userId = Long.parseLong(request.getParameter("user_id"));
            long hotelId = Long.parseLong(request.getParameter("hotel_id"));
            long roomId = Long.parseLong(request.getParameter("room_id"));
            String checkInDate = request.getParameter("check_in_date");
            String checkOutDate = request.getParameter("check_out_date");
            double totalAmount = Double.parseDouble(request.getParameter("total_amount"));
            String status = request.getParameter("status");
            
            // Insert booking
            String insertQuery = "INSERT INTO bookings (user_id, hotel_id, room_id, check_in_date, check_out_date, booking_date, total_amount, status) " +
                                "VALUES (?, ?, ?, ?, ?, NOW(), ?, ?)";
            
            pstmt = conn.prepareStatement(insertQuery);
            pstmt.setLong(1, userId);
            pstmt.setLong(2, hotelId);
            pstmt.setLong(3, roomId);
            pstmt.setString(4, checkInDate);
            pstmt.setString(5, checkOutDate);
            pstmt.setDouble(6, totalAmount);
            pstmt.setString(7, status);
            
            int result = pstmt.executeUpdate();
            
            if (result > 0) {
                successMessage = "Booking created successfully!";
            } else {
                errorMessage = "Failed to create booking.";
            }
            
        } catch (Exception e) {
            errorMessage = "Error: " + e.getMessage();
            e.printStackTrace();
        }
    }
    
    try {
        // Establish database connection
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(url, username, password);
        
        // Get hotels list
        String hotelsQuery = "SELECT hotel_id, name, city, country FROM hotels WHERE status = 'active'";
        pstmt = conn.prepareStatement(hotelsQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> hotel = new HashMap<>();
            hotel.put("id", rs.getLong("hotel_id"));
            hotel.put("name", rs.getString("name"));
            hotel.put("location", rs.getString("city") + ", " + rs.getString("country"));
            hotelsList.add(hotel);
        }
        
        rs.close();
        pstmt.close();
        
        // Get users list
        String usersQuery = "SELECT u.user_id, u.first_name, u.last_name, u.email, r.name as role_name " +
                           "FROM users u " +
                           "JOIN roles r ON u.role_id = r.role_id " +
                           "WHERE r.name = 'client' AND u.is_active = 1";
        
        pstmt = conn.prepareStatement(usersQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> user = new HashMap<>();
            user.put("id", rs.getLong("user_id"));
            user.put("name", rs.getString("first_name") + " " + rs.getString("last_name"));
            user.put("email", rs.getString("email"));
            usersList.add(user);
        }
        
    } catch (Exception e) {
        errorMessage = "Error: " + e.getMessage();
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
    <title>ZAIRTAM - Create New Booking</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">
    <script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
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
                            <a href="bookings.jsp" class="flex items-center px-3 py-2 text-blue-600 bg-blue-50 rounded-md">
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
            <div class="flex justify-between items-center mb-8">
                <div>
                    <h1 class="text-2xl font-bold text-gray-800">Create New Booking</h1>
                    <p class="text-gray-600">Add a new reservation to the system</p>
                </div>
                <a href="bookings.jsp" class="bg-gray-200 hover:bg-gray-300 text-gray-700 px-4 py-2 rounded-lg transition duration-200 flex items-center">
                    <i class="fas fa-arrow-left mr-2"></i> Back to Bookings
                </a>
            </div>
            
            <!-- Alert Messages -->
            <% if (!successMessage.isEmpty()) { %>
                <div class="bg-green-100 border-l-4 border-green-500 text-green-700 p-4 mb-6" role="alert">
                    <p><i class="fas fa-check-circle mr-2"></i> <%= successMessage %></p>
                </div>
            <% } %>
            
            <% if (!errorMessage.isEmpty()) { %>
                <div class="bg-red-100 border-l-4 border-red-500 text-red-700 p-4 mb-6" role="alert">
                    <p><i class="fas fa-exclamation-circle mr-2"></i> <%= errorMessage %></p>
                </div>
            <% } %>
            
            <!-- Booking Form -->
            <div class="bg-white rounded-lg shadow-sm p-6 mb-8">
                <form action="create-booking.jsp" method="post" id="bookingForm">
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <!-- Guest Information -->
                        <div>
                            <h3 class="text-lg font-semibold text-gray-800 mb-4">Guest Information</h3>
                            
                            <div class="mb-4">
                                <label for="user_id" class="block text-sm font-medium text-gray-700 mb-1">Select Guest</label>
                                <select id="user_id" name="user_id" class="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500" required>
                                    <option value="">-- Select a guest --</option>
                                    <% for (Map<String, Object> user : usersList) { %>
                                        <option value="<%= user.get("id") %>"><%= user.get("name") %> (<%= user.get("email") %>)</option>
                                    <% } %>
                                </select>
                            </div>
                            
                            <div class="mb-4">
                                <button type="button" id="newGuestBtn" class="text-blue-600 hover:text-blue-800 text-sm font-medium">
                                    <i class="fas fa-plus mr-1"></i> Add New Guest
                                </button>
                            </div>
                        </div>
                        
                        <!-- Hotel & Room Selection -->
                        <div>
                            <h3 class="text-lg font-semibold text-gray-800 mb-4">Hotel & Room</h3>
                            
                            <div class="mb-4">
                                <label for="hotel_id" class="block text-sm font-medium text-gray-700 mb-1">Select Hotel</label>
                                <select id="hotel_id" name="hotel_id" class="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500" required>
                                    <option value="">-- Select a hotel --</option>
                                    <% for (Map<String, Object> hotel : hotelsList) { %>
                                        <option value="<%= hotel.get("id") %>"><%= hotel.get("name") %> (<%= hotel.get("location") %>)</option>
                                    <% } %>
                                </select>
                            </div>
                            
                            <div class="mb-4">
                                <label for="room_id" class="block text-sm font-medium text-gray-700 mb-1">Select Room</label>
                                <select id="room_id" name="room_id" class="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500" required disabled>
                                    <option value="">-- Select a hotel first --</option>
                                </select>
                            </div>
                            
                            <div class="mb-4">
                                <p id="room_details" class="text-sm text-gray-600 hidden">
                                    Room details will appear here once selected.
                                </p>
                            </div>
                        </div>
                        
                        <!-- Booking Details -->
                        <div>
                            <h3 class="text-lg font-semibold text-gray-800 mb-4">Booking Details</h3>
                            
                            <div class="mb-4">
                                <label for="check_in_date" class="block text-sm font-medium text-gray-700 mb-1">Check-in Date</label>
                                <input type="text" id="check_in_date" name="check_in_date" class="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 datepicker" placeholder="Select date" required>
                            </div>
                            
                            <div class="mb-4">
                                <label for="check_out_date" class="block text-sm font-medium text-gray-700 mb-1">Check-out Date</label>
                                <input type="text" id="check_out_date" name="check_out_date" class="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 datepicker" placeholder="Select date" required>
                            </div>
                            
                            <div class="mb-4">
                                <label for="total_nights" class="block text-sm font-medium text-gray-700 mb-1">Total Nights</label>
                                <input type="text" id="total_nights" class="w-full px-3 py-2 border rounded-lg bg-gray-100" readonly>
                            </div>
                        </div>
                        
                        <!-- Payment Information -->
                        <div>
                            <h3 class="text-lg font-semibold text-gray-800 mb-4">Payment Information</h3>
                            
                            <div class="mb-4">
                                <label for="room_price" class="block text-sm font-medium text-gray-700 mb-1">Room Price (per night)</label>
                                <input type="text" id="room_price" class="w-full px-3 py-2 border rounded-lg bg-gray-100" readonly>
                            </div>
                            
                            <div class="mb-4">
                                <label for="total_amount" class="block text-sm font-medium text-gray-700 mb-1">Total Amount</label>
                                <input type="text" id="total_amount" name="total_amount" class="w-full px-3 py-2 border rounded-lg bg-gray-100" readonly>
                            </div>
                            
                            <div class="mb-4">
                                <label for="status" class="block text-sm font-medium text-gray-700 mb-1">Booking Status</label>
                                <select id="status" name="status" class="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500" required>
                                    <option value="pending">Pending</option>
                                    <option value="confirmed">Confirmed</option>
                                    <option value="cancelled">Cancelled</option>
                                </select>
                            </div>
                        </div>
                    </div>
                    
                    <div class="mt-8 flex justify-end">
                        <a href="bookings.jsp" class="bg-gray-200 hover:bg-gray-300 text-gray-700 px-4 py-2 rounded-lg mr-4">
                            Cancel
                        </a>
                        <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg">
                            Create Booking
                        </button>
                    </div>
                </form>
            </div>
        </main>
    </div>

    <script>
        // Toggle sidebar on mobile
        document.getElementById('sidebar-toggle').addEventListener('click', function() {
            document.getElementById('sidebar').classList.toggle('open');
        });
        
        // Initialize date pickers
        flatpickr(".datepicker", {
            dateFormat: "Y-m-d",
            minDate: "today"
        });
        
        // Calculate total nights and amount when dates change
        const checkInDate = document.getElementById('check_in_date');
        const checkOutDate = document.getElementById('check_out_date');
        const totalNights = document.getElementById('total_nights');
        const roomPrice = document.getElementById('room_price');
        const totalAmount = document.getElementById('total_amount');
        
        function calculateTotalNights() {
            if (checkInDate.value && checkOutDate.value) {
                const startDate = new Date(checkInDate.value);
                const endDate = new Date(checkOutDate.value);
                
                if (endDate > startDate) {
                    const diffTime = Math.abs(endDate - startDate);
                    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                    
                    totalNights.value = diffDays;
                    
                    // Calculate total amount if room price is available
                    if (roomPrice.value) {
                        const price = parseFloat(roomPrice.value.replace(/[^0-9.-]+/g, ''));
                        totalAmount.value = (price * diffDays).toFixed(2);
                    }
                } else {
                    totalNights.value = "Check-out must be after check-in";
                    totalAmount.value = "";
                }
            }
        }
        
        checkInDate.addEventListener('change', calculateTotalNights);
        checkOutDate.addEventListener('change', calculateTotalNights);
        
        // Handle hotel selection to load rooms
        const hotelSelect = document.getElementById('hotel_id');
        const roomSelect = document.getElementById('room_id');
        const roomDetails = document.getElementById('room_details');
        
        hotelSelect.addEventListener('change', function() {
            if (this.value) {
                // Enable room selection
                roomSelect.disabled = false;
                roomSelect.innerHTML = '<option value="">-- Loading rooms... --</option>';
                
                // In a real application, you would fetch rooms from the server based on the hotel ID
                // For this example, we'll simulate it with setTimeout
                setTimeout(() => {
                    roomSelect.innerHTML = `
                        <option value="">-- Select a room --</option>
                        <option value="1">Standard Room</option>
                        <option value="2">Deluxe Room</option>
                        <option value="3">Suite</option>
                        <option value="4">Executive Suite</option>
                    `;
                }, 500);
            } else {
                roomSelect.disabled = true;
                roomSelect.innerHTML = '<option value="">-- Select a hotel first --</option>';
                roomDetails.classList.add('hidden');
            }
        });
        
        // Handle room selection to show details and price
        roomSelect.addEventListener('change', function() {
            if (this.value) {
                roomDetails.classList.remove('hidden');
                
                // In a real application, you would fetch room details from the server
                // For this example, we'll use hardcoded values
                const roomTypes = {
                    '1': { type: 'Standard Room', price: 100, description: 'Comfortable room with basic amenities.' },
                    '2': { type: 'Deluxe Room', price: 150, description: 'Spacious room with premium amenities.' },
                    '3': { type: 'Suite', price: 250, description: 'Luxury suite with separate living area.' },
                    '4': { type: 'Executive Suite', price: 350, description: 'Premium suite with panoramic views.' }
                };
                
                const room = roomTypes[this.value];
                
                roomDetails.innerHTML = `
                    <div class="p-3 bg-gray-50 rounded-md">
                        <p class="font-medium">${room.type}</p>
                        <p class="text-sm text-gray-600">${room.description}</p>
                    </div>
                `;
                
                roomPrice.value = `$${room.price.toFixed(2)}`;
                
                // Recalculate total amount
                calculateTotalNights();
            } else {
                roomDetails.classList.add('hidden');
                roomPrice.value = "";
                totalAmount.value = "";
            }
        });
    </script>
</body>
</html>