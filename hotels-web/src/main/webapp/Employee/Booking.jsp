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
    if (userId == null) {
        // Redirect to login page if not logged in
        response.sendRedirect("../login.jsp");
        return;
    }
    
    // Get room ID and booking details from request parameters
    String roomId = request.getParameter("roomId");
    String checkIn = request.getParameter("checkIn");
    String checkOut = request.getParameter("checkOut");
    String guests = request.getParameter("guests");
    
    if (roomId == null || checkIn == null || checkOut == null) {
        // Redirect to rooms page if parameters are missing
        response.sendRedirect("Guests.jsp");
        return;
    }
    
    // Room details
    Map<String, Object> roomDetails = new HashMap<>();
    
    // Booking calculation variables
    int numberOfNights = 0;
    double roomPrice = 0.0;
    double totalPrice = 0.0;
    double taxAmount = 0.0;
    double serviceCharge = 0.0;
    
    // Messages for form submission
    String successMessage = "";
    String errorMessage = "";
    
    // Process booking form submission
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        
        if ("confirm_booking".equals(action)) {
            try {
                // Establish database connection
                Class.forName("com.mysql.jdbc.Driver");
                conn = DriverManager.getConnection(jdbcURL, dbUser, dbPassword);
                
                // Generate booking reference (simple implementation)
                String bookingReference = "BK" + System.currentTimeMillis();
                
                // Insert booking into database
                String insertBookingQuery = "INSERT INTO bookings (booking_reference, user_id, room_id, check_in_date, " +
                                          "check_out_date, guests_count, total_price, status, created_at) " +
                                          "VALUES (?, ?, ?, ?, ?, ?, ?, 'confirmed', NOW())";
                
                pstmt = conn.prepareStatement(insertBookingQuery);
                pstmt.setString(1, bookingReference);
                pstmt.setString(2, userId);
                pstmt.setString(3, roomId);
                pstmt.setString(4, checkIn);
                pstmt.setString(5, checkOut);
                pstmt.setString(6, guests);
                pstmt.setDouble(7, totalPrice);
                
                int rowsAffected = pstmt.executeUpdate();
                
                if (rowsAffected > 0) {
                    // Booking successful
                    successMessage = "Your booking has been confirmed! Booking reference: " + bookingReference;
                    
                    // Redirect to reservations page after a short delay
                    response.setHeader("Refresh", "3;url=Reservations.jsp");
                } else {
                    errorMessage = "Failed to process your booking. Please try again.";
                }
                
            } catch (Exception e) {
                errorMessage = "Error: " + e.getMessage();
                e.printStackTrace();
            }
        }
    }
    
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
        
        // Fetch room details
        String roomQuery = "SELECT r.*, h.hotel_name, h.location, h.image_url FROM rooms r " +
                          "JOIN hotels h ON r.hotel_id = h.hotel_id " +
                          "WHERE r.room_id = ?";
        
        pstmt = conn.prepareStatement(roomQuery);
        pstmt.setString(1, roomId);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            roomDetails.put("roomId", rs.getInt("room_id"));
            roomDetails.put("roomNumber", rs.getString("room_number"));
            roomDetails.put("roomType", rs.getString("room_type"));
            roomDetails.put("floor", rs.getString("floor"));
            roomDetails.put("status", rs.getString("status"));
            roomDetails.put("pricePerNight", rs.getDouble("price_per_night"));
            roomDetails.put("maxOccupancy", rs.getInt("max_occupancy"));
            roomDetails.put("description", rs.getString("description"));
            roomDetails.put("hotelId", rs.getInt("hotel_id"));
            roomDetails.put("hotelName", rs.getString("hotel_name"));
            roomDetails.put("location", rs.getString("location"));
            roomDetails.put("hotelImage", rs.getString("image_url"));
            
            // Parse amenities from comma-separated string to list
            String amenitiesStr = rs.getString("amenities");
            List<String> amenitiesList = new ArrayList<>();
            if (amenitiesStr != null && !amenitiesStr.isEmpty()) {
                String[] amenitiesArray = amenitiesStr.split(",");
                for (String amenity : amenitiesArray) {
                    amenitiesList.add(amenity.trim());
                }
            }
            roomDetails.put("amenities", amenitiesList);
            
            // Store room price for calculations
            roomPrice = rs.getDouble("price_per_night");
        } else {
            // Room not found, redirect to rooms page
            response.sendRedirect("Guests.jsp");
            return;
        }
        
        // Calculate number of nights
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
        Date checkInDate = sdf.parse(checkIn);
        Date checkOutDate = sdf.parse(checkOut);
        
        long diffInMillies = Math.abs(checkOutDate.getTime() - checkInDate.getTime());
        numberOfNights = (int) (diffInMillies / (1000 * 60 * 60 * 24));
        
        // Calculate total price
        double subtotal = roomPrice * numberOfNights;
        taxAmount = subtotal * 0.10; // 10% tax
        serviceCharge = subtotal * 0.05; // 5% service charge
        totalPrice = subtotal + taxAmount + serviceCharge;
        
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
    
    // Format dates for display
    SimpleDateFormat displayDateFormat = new SimpleDateFormat("dd MMM yyyy");
    String formattedCheckIn = "";
    String formattedCheckOut = "";
    
    try {
        Date checkInDate = new SimpleDateFormat("yyyy-MM-dd").parse(checkIn);
        Date checkOutDate = new SimpleDateFormat("yyyy-MM-dd").parse(checkOut);
        formattedCheckIn = displayDateFormat.format(checkInDate);
        formattedCheckOut = displayDateFormat.format(checkOutDate);
    } catch (Exception e) {
        e.printStackTrace();
    }
    
    // Hotel information
    String hotelName = (String) roomDetails.get("hotelName");
    String hotelLocation = (String) roomDetails.get("location");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZAIRTAM - Room Booking</title>
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
        
        .booking-summary {
            border-radius: 0.5rem;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
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
            
            // Payment method selection
            const paymentMethods = document.querySelectorAll('.payment-method');
            paymentMethods.forEach(method => {
                method.addEventListener('click', function() {
                    // Remove selected class from all methods
                    paymentMethods.forEach(m => {
                        m.classList.remove('border-blue-500', 'bg-blue-50');
                        m.classList.add('border-gray-200');
                    });
                    
                    // Add selected class to clicked method
                    this.classList.remove('border-gray-200');
                    this.classList.add('border-blue-500', 'bg-blue-50');
                    
                    // Set the selected payment method value
                    document.getElementById('selectedPaymentMethod').value = this.getAttribute('data-method');
                });
            });
            
            // Form validation
            const bookingForm = document.getElementById('bookingForm');
            if (bookingForm) {
                bookingForm.addEventListener('submit', function(event) {
                    // Get selected payment method
                    const selectedPaymentMethod = document.getElementById('selectedPaymentMethod').value;
                    
                    // Check if payment method is selected
                    if (!selectedPaymentMethod) {
                        event.preventDefault();
                        alert('Please select a payment method');
                        return false;
                    }
                    
                    // Additional validation for credit card if selected
                    if (selectedPaymentMethod === 'credit_card') {
                        const cardNumber = document.getElementById('cardNumber');
                        const cardName = document.getElementById('cardName');
                        const expiryDate = document.getElementById('expiryDate');
                        const cvv = document.getElementById('cvv');
                        
                        if (!cardNumber || !cardName || !expiryDate || !cvv) {
                            return true; // Fields not found, skip validation
                        }
                        
                        // Simple validation
                        if (!cardNumber.value || cardNumber.value.length < 16) {
                            event.preventDefault();
                            alert('Please enter a valid card number');
                            cardNumber.focus();
                            return false;
                        }
                        
                        if (!cardName.value) {
                            event.preventDefault();
                            alert('Please enter the name on card');
                            cardName.focus();
                            return false;
                        }
                        
                        if (!expiryDate.value) {
                            event.preventDefault();
                            alert('Please enter the expiry date');
                            expiryDate.focus();
                            return false;
                        }
                        
                        if (!cvv.value || cvv.value.length < 3) {
                            event.preventDefault();
                            alert('Please enter a valid CVV');
                            cvv.focus();
                            return false;
                        }
                    }
                    
                    // Show loading state
                    const submitButton = document.querySelector('button[type="submit"]');
                    if (submitButton) {
                        submitButton.disabled = true;
                        submitButton.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i> Processing...';
                    }
                    
                    return true;
                });
            }
            
            // Format credit card number with spaces
            const cardNumberInput = document.getElementById('cardNumber');
            if (cardNumberInput) {
                cardNumberInput.addEventListener('input', function(e) {
                    // Remove non-digits
                    let value = this.value.replace(/\D/g, '');
                    
                    // Add a space after every 4 digits
                    value = value.replace(/(\d{4})(?=\d)/g, '$1 ');
                    
                    // Update the input value
                    this.value = value;
                });
            }
            
            // Format expiry date (MM/YY)
            const expiryDateInput = document.getElementById('expiryDate');
            if (expiryDateInput) {
                expiryDateInput.addEventListener('input', function(e) {
                    // Remove non-digits
                    let value = this.value.replace(/\D/g, '');
                    
                    // Add slash after 2 digits (MM/YY)
                    if (value.length > 2) {
                        value = value.substring(0, 2) + '/' + value.substring(2, 4);
                    }
                    
                    // Update the input value
                    this.value = value;
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
                    <a href="Guests.jsp" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                        <i class="fas fa-bed w-5 h-5 mr-3 text-gray-400"></i>
                        Rooms
                    </a>
                    <a href="Reservations.jsp" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                        <i class="fas fa-calendar-check w-5 h-5 mr-3 text-gray-400"></i>
                        My Reservations
                    </a>
                    <a href="Profile.jsp" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                        <i class="fas fa-user w-5 h-5 mr-3 text-gray-400"></i>
                        Profile
                    </a>
                    <a href="Account-Settings.jsp" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                        <i class="fas fa-cog w-5 h-5 mr-3 text-gray-400"></i>
                        Settings
                    </a>
                    <a href="Payment-Methods.jsp" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                        <i class="fas fa-credit-card w-5 h-5 mr-3 text-gray-400"></i>
                        Payment Methods
                    </a>
                </nav>
            </div>
        </aside>

        <!-- Main Content -->
        <main class="flex-1 p-4 lg:p-8">
            <!-- Page Header -->
            <div class="mb-6">
                <h1 class="text-2xl font-bold text-gray-900">Complete Your Booking</h1>
                <p class="text-gray-600">Review your booking details and confirm your reservation</p>
            </div>
            
            <% if (!successMessage.isEmpty()) { %>
            <div class="bg-green-50 border-l-4 border-green-500 p-4 mb-6">
                <div class="flex">
                    <div class="flex-shrink-0">
                        <i class="fas fa-check-circle text-green-500"></i>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm text-green-700"><%= successMessage %></p>
                    </div>
                </div>
            </div>
            <% } %>
            
            <% if (!errorMessage.isEmpty()) { %>
            <div class="bg-red-50 border-l-4 border-red-500 p-4 mb-6">
                <div class="flex">
                    <div class="flex-shrink-0">
                        <i class="fas fa-exclamation-circle text-red-500"></i>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm text-red-700"><%= errorMessage %></p>
                    </div>
                </div>
            </div>
            <% } %>
            
            <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
                <!-- Booking Form -->
                <div class="lg:col-span-2">
                    <div class="bg-white rounded-lg shadow-sm p-6">
                        <h2 class="text-lg font-semibold text-gray-900 mb-4">Room Details</h2>
                        
                        <div class="flex flex-col md:flex-row mb-6">
                            <div class="md:w-1/3 mb-4 md:mb-0">
                                <img src="<%= roomDetails.get("hotelImage") %>" alt="Room" class="w-full h-48 object-cover rounded-lg">
                            </div>
                            <div class="md:w-2/3 md:pl-6">
                                <h3 class="text-lg font-semibold text-gray-900"><%= roomDetails.get("hotelName") %></h3>
                                <p class="text-gray-600 mb-2"><i class="fas fa-map-marker-alt text-gray-400 mr-1"></i> <%= roomDetails.get("location") %></p>
                                
                                <div class="mb-2">
                                    <span class="room-type-badge <%= "room-" + roomDetails.get("roomType").toString().toLowerCase() %>">
                                        <%= roomDetails.get("roomType") %> Room
                                    </span>
                                    <span class="room-badge room-available ml-2">
                                        Available
                                    </span>
                                </div>
                                
                                <div class="mt-2">
                                    <div class="flex items-center text-sm text-gray-600">
                                        <i class="fas fa-calendar-alt text-gray-400 mr-2"></i>
                                        <span><%= formattedCheckIn %> to <%= formattedCheckOut %></span>
                                    </div>
                                    <div class="flex items-center text-sm text-gray-600 mt-1">
                                        <i class="fas fa-user-friends text-gray-400 mr-2"></i>
                                        <span><%= guests %> Guest<%= Integer.parseInt(guests) > 1 ? "s" : "" %></span>
                                    </div>
                                    <div class="flex items-center text-sm text-gray-600 mt-1">
                                        <i class="fas fa-moon text-gray-400 mr-2"></i>
                                        <span><%= numberOfNights %> Night<%= numberOfNights > 1 ? "s" : "" %></span>
                                    </div>
                                </div>
                                
                                <div class="mt-3">
                                    <div class="text-sm font-medium text-gray-900">Room Amenities:</div>
                                    <div class="mt-1 flex flex-wrap gap-2">
                                        <% 
                                        List<String> amenities = (List<String>) roomDetails.get("amenities");
                                        if (amenities != null && !amenities.isEmpty()) {
                                            for (String amenity : amenities) {
                                        %>
                                        <span class="inline-flex items-center px-2 py-1 rounded-md text-xs font-medium bg-gray-100 text-gray-800">
                                            <% 
                                            String iconClass = "fas fa-check";
                                            if (amenity.toLowerCase().contains("wifi")) {
                                                iconClass = "fas fa-wifi";
                                            } else if (amenity.toLowerCase().contains("tv")) {
                                                iconClass = "fas fa-tv";
                                            } else if (amenity.toLowerCase().contains("breakfast")) {
                                                iconClass = "fas fa-coffee";
                                            } else if (amenity.toLowerCase().contains("air")) {
                                                iconClass = "fas fa-wind";
                                            } else if (amenity.toLowerCase().contains("bath")) {
                                                iconClass = "fas fa-bath";
                                            }
                                            %>
                                            <i class="<%= iconClass %> mr-1 text-blue-500"></i> <%= amenity %>
                                        </span>
                                        <% 
                                            }
                                        } else {
                                        %>
                                        <span class="text-sm text-gray-500">No amenities listed</span>
                                        <% } %>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <hr class="my-6">
                        
                        <h2 class="text-lg font-semibold text-gray-900 mb-4">Booking Information</h2>
                        
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
                            <div>
                                <label class="block text-sm font-medium text-gray-700 mb-1">Check-in Date</label>
                                <div class="flex items-center border border-gray-300 rounded-md px-3 py-2 bg-gray-50">
                                    <i class="fas fa-calendar-alt text-gray-400 mr-2"></i>
                                    <span class="text-gray-900"><%= formattedCheckIn %></span>
                                </div>
                            </div>
                            <div>
                                <label class="block text-sm font-medium text-gray-700 mb-1">Check-out Date</label>
                                <div class="flex items-center border border-gray-300 rounded-md px-3 py-2 bg-gray-50">
                                    <i class="fas fa-calendar-alt text-gray-400 mr-2"></i>
                                    <span class="text-gray-900"><%= formattedCheckOut %></span>
                                </div>
                            </div>
                            <div>
                                <label class="block text-sm font-medium text-gray-700 mb-1">Number of Nights</label>
                                <div class="flex items-center border border-gray-300 rounded-md px-3 py-2 bg-gray-50">
                                    <i class="fas fa-moon text-gray-400 mr-2"></i>
                                    <span class="text-gray-900"><%= numberOfNights %> night<%= numberOfNights > 1 ? "s" : "" %></span>
                                </div>
                            </div>
                            <div>
                                <label class="block text-sm font-medium text-gray-700 mb-1">Number of Guests</label>
                                <div class="flex items-center border border-gray-300 rounded-md px-3 py-2 bg-gray-50">
                                    <i class="fas fa-user-friends text-gray-400 mr-2"></i>
                                    <span class="text-gray-900"><%= guests %> guest<%= Integer.parseInt(guests) > 1 ? "s" : "" %></span>
                                </div>
                            </div>
                        </div>
                        
                        <hr class="my-6">
                        
                        <h2 class="text-lg font-semibold text-gray-900 mb-4">Payment Method</h2>
                        
                        <form method="post" action="Booking.jsp">
                            <input type="hidden" name="action" value="confirm_booking">
                            <input type="hidden" name="roomId" value="<%= roomId %>">
                            <input type="hidden" name="checkIn" value="<%= checkIn %>">
                            <input type="hidden" name="checkOut" value="<%= checkOut %>">
                            <input type="hidden" name="guests" value="<%= guests %>">
                            <input type="hidden" id="selectedPaymentMethod" name="paymentMethod" value="credit_card">
                            
                            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                                <div class="payment-method border-2 border-blue-500 bg-blue-50 rounded-lg p-4 cursor-pointer" data-method="credit_card">
                                    <div class="flex items-center justify-center mb-2">
                                        <i class="fas fa-credit-card text-2xl text-blue-600"></i>
                                    </div>
                                    <p class="text-center text-sm font-medium">Credit Card</p>
                                </div>
                                <div class="payment-method border-2 border-gray-200 rounded-lg p-4 cursor-pointer" data-method="paypal">
                                    <div class="flex items-center justify-center mb-2">
                                        <i class="fab fa-paypal text-2xl text-blue-600"></i>
                                    </div>
                                    <p class="text-center text-sm font-medium">PayPal</p>
                                </div>
                                <div class="payment-method border-2 border-gray-200 rounded-lg p-4 cursor-pointer" data-method="bank_transfer">
                                    <div class="flex items-center justify-center mb-2">
                                        <i class="fas fa-university text-2xl text-blue-600"></i>
                                    </div>
                                    <p class="text-center text-sm font-medium">Bank Transfer</p>
                                </div>
                            </div>
                            
                            <div class="flex justify-end">
                                <a href="Guests.jsp" class="bg-gray-100 text-gray-700 px-4 py-2 rounded-md mr-2 hover:bg-gray-200">
                                    Cancel
                                </a>
                                <button type="submit" class="bg-blue-600 text-white px-6 py-2 rounded-md hover:bg-blue-700">
                                    Confirm Booking
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
                
                <!-- Booking Summary -->
                <div class="lg:col-span-1">
                    <div class="bg-white rounded-lg shadow-sm p-6 booking-summary sticky top-24">
                        <h2 class="text-lg font-semibold text-gray-900 mb-4">Booking Summary</h2>
                        
                        <div class="space-y-3 mb-6">
                            <div class="flex justify-between">
                                <span class="text-gray-600">Room Price</span>
                                <span class="text-gray-900 font-medium">$<%= String.format("%.2f", roomPrice) %> × <%= numberOfNights %> nights</span>
                            </div>
                            <div class="flex justify-between">
                                <span class="text-gray-600">Subtotal</span>
                                <span class="text-gray-900 font-medium">$<%= String.format("%.2f", roomPrice * numberOfNights) %></span>
                            </div>
                            <div class="flex justify-between">
                                <span class="text-gray-600">Tax (10%)</span>
                                <span class="text-gray-900 font-medium">$<%= String.format("%.2f", taxAmount) %></span>
                            </div>
                            <div class="flex justify-between">
                                <span class="text-gray-600">Service Charge (5%)</span>
                                <span class="text-gray-900 font-medium">$<%= String.format("%.2f", serviceCharge) %></span>
                            </div>
                        </div>
                        
                        <div class="border-t border-gray-200 pt-4 mb-6">
                            <div class="flex justify-between items-center">
                                <span class="text-lg font-semibold text-gray-900">Total</span>
                                <span class="text-xl font-bold text-blue-600">$<%= String.format("%.2f", totalPrice) %></span>
                            </div>
                        </div>
                        
                        <div class="bg-blue-50 rounded-md p-4">
                            <h3 class="text-sm font-semibold text-blue-800 mb-2">Booking Policy</h3>
                            <ul class="text-xs text-blue-700 space-y-1">
                                <li><i class="fas fa-check text-blue-500 mr-1"></i> Free cancellation up to 24 hours before check-in</li>
                                <li><i class="fas fa-check text-blue-500 mr-1"></i> Pay at the hotel or secure online payment</li>
                                <li><i class="fas fa-check text-blue-500 mr-1"></i> Best price guarantee</li>
                                <li><i class="fas fa-check text-blue-500 mr-1"></i> No hidden fees or charges</li>
                                <li><i class="fas fa-check text-blue-500 mr-1"></i> 24/7 customer support</li>
                            </ul>
                        </div>
                        
                        <div class="mt-6">
                            <h3 class="text-sm font-semibold text-gray-800 mb-2">Payment Method</h3>
                            <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
                                <div class="payment-method border border-gray-200 rounded-md p-3 cursor-pointer hover:border-blue-500 border-blue-500 bg-blue-50">
                                    <div class="flex items-center" data-method="credit_card">
                                        <i class="fas fa-credit-card text-blue-600 mr-2"></i>
                                        <span class="text-sm font-medium">Credit Card</span>
                                    </div>
                                </div>
                                <div class="payment-method border border-gray-200 rounded-md p-3 cursor-pointer hover:border-blue-500">
                                    <div class="flex items-center" data-method="paypal">
                                        <i class="fab fa-paypal text-blue-600 mr-2"></i>
                                        <span class="text-sm font-medium">PayPal</span>
                                    </div>
                                </div>
                                <div class="payment-method border border-gray-200 rounded-md p-3 cursor-pointer hover:border-blue-500">
                                    <div class="flex items-center" data-method="hotel">
                                        <i class="fas fa-hotel text-blue-600 mr-2"></i>
                                        <span class="text-sm font-medium">Pay at Hotel</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="mt-6">
                            <h3 class="text-sm font-semibold text-gray-800 mb-2">Guest Information</h3>
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <div>
                                    <label for="fullName" class="block text-sm font-medium text-gray-700 mb-1">Full Name</label>
                                    <input type="text" id="fullName" name="fullName" value="<%= guestName %>" 
                                           class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                                           readonly>
                                </div>
                                <div>
                                    <label for="email" class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                                    <input type="email" id="email" name="email" value="<%= guestEmail %>" 
                                           class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                                           readonly>
                                </div>
                                <div>
                                    <label for="phone" class="block text-sm font-medium text-gray-700 mb-1">Phone Number</label>
                                    <input type="tel" id="phone" name="phone" placeholder="Enter your phone number" 
                                           class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                                           required>
                                </div>
                                <div>
                                    <label for="specialRequests" class="block text-sm font-medium text-gray-700 mb-1">Special Requests (Optional)</label>
                                    <input type="text" id="specialRequests" name="specialRequests" placeholder="Any special requests?" 
                                           class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                                </div>
                            </div>
                        </div>
                        
                        <div class="mt-6">
                            <h3 class="text-sm font-semibold text-gray-800 mb-2">Terms and Conditions</h3>
                            <div class="flex items-start">
                                <div class="flex items-center h-5">
                                    <input id="terms" name="terms" type="checkbox" required
                                           class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded">
                                </div>
                                <div class="ml-3 text-sm">
                                    <label for="terms" class="font-medium text-gray-700">I agree to the terms and conditions</label>
                                    <p class="text-gray-500">By checking this box, you agree to our <a href="#" class="text-blue-600 hover:underline">Terms of Service</a> and <a href="#" class="text-blue-600 hover:underline">Privacy Policy</a>.</p>
                                </div>
                            </div>
                        </div>
                        
                        <input type="hidden" id="selectedPaymentMethod" name="selectedPaymentMethod" value="credit_card">
                        
                        <div class="mt-8">
                            <button type="submit" name="action" value="confirm_booking" class="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 px-4 rounded-md font-medium">
                                Confirm and Pay
                            </button>
                        </div>
                    </div>
                </div>
                
                <!-- Booking Summary -->
                <div class="lg:col-span-1">
                    <div class="bg-white rounded-lg shadow-sm p-6 booking-summary sticky top-24">
                        <h2 class="text-lg font-semibold text-gray-900 mb-4">Booking Summary</h2>
                        
                        <div class="border-b border-gray-200 pb-4">
                            <div class="flex justify-between items-center mb-2">
                                <span class="text-sm text-gray-600">Room Type</span>
                                <span class="text-sm font-medium text-gray-900"><%= roomDetails.get("roomType") %> Room</span>
                            </div>
                            <div class="flex justify-between items-center mb-2">
                                <span class="text-sm text-gray-600">Check-in</span>
                                <span class="text-sm font-medium text-gray-900"><%= formattedCheckIn %></span>
                            </div>
                            <div class="flex justify-between items-center mb-2">
                                <span class="text-sm text-gray-600">Check-out</span>
                                <span class="text-sm font-medium text-gray-900"><%= formattedCheckOut %></span>
                            </div>
                            <div class="flex justify-between items-center mb-2">
                                <span class="text-sm text-gray-600">Guests</span>
                                <span class="text-sm font-medium text-gray-900"><%= guests %> Guest<%= Integer.parseInt(guests) > 1 ? "s" : "" %></span>
                            </div>
                            <div class="flex justify-between items-center">
                                <span class="text-sm text-gray-600">Duration</span>
                                <span class="text-sm font-medium text-gray-900"><%= numberOfNights %> Night<%= numberOfNights > 1 ? "s" : "" %></span>
                            </div>
                        </div>
                        
                        <div class="py-4 border-b border-gray-200">
                            <div class="flex justify-between items-center mb-2">
                                <span class="text-sm text-gray-600">Room Rate</span>
                                <span class="text-sm font-medium text-gray-900">$<%= String.format("%.2f", roomPrice) %> / night</span>
                            </div>
                            <div class="flex justify-between items-center mb-2">
                                <span class="text-sm text-gray-600">Room Total</span>
                                <span class="text-sm font-medium text-gray-900">$<%= String.format("%.2f", roomPrice * numberOfNights) %></span>
                            </div>
                            <div class="flex justify-between items-center mb-2">
                                <span class="text-sm text-gray-600">Taxes (10%)</span>
                                <span class="text-sm font-medium text-gray-900">$<%= String.format("%.2f", taxAmount) %></span>
                            </div>
                            <div class="flex justify-between items-center">
                                <span class="text-sm text-gray-600">Service Fee (5%)</span>
                                <span class="text-sm font-medium text-gray-900">$<%= String.format("%.2f", serviceCharge) %></span>
                            </div>
                        </div>
                        
                        <div class="pt-4">
                            <div class="flex justify-between items-center">
                                <span class="text-base font-semibold text-gray-900">Total</span>
                                <span class="text-lg font-bold text-blue-600">$<%= String.format("%.2f", totalPrice) %></span>
                            </div>
                            <p class="text-xs text-gray-500 mt-2">Prices are in USD and include all applicable taxes and fees.</p>
                        </div>
                        
                        <div class="mt-6">
                            <div class="bg-gray-50 rounded-md p-3">
                                <div class="flex items-center">
                                    <i class="fas fa-shield-alt text-green-500 mr-2"></i>
                                    <div>
                                        <h3 class="text-xs font-semibold text-gray-900">Secure Booking</h3>
                                        <p class="text-xs text-gray-600">Your payment information is encrypted and secure.</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    </div>
    
    <footer class="bg-white border-t border-gray-200 mt-8">
        <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
            <div class="flex flex-col md:flex-row justify-between items-center">
                <div class="flex items-center mb-4 md:mb-0">
                    <i class="fas fa-hotel text-blue-600 text-2xl mr-2"></i>
                    <span class="text-xl font-bold text-gray-800">ZAIRTAM</span>
                </div>
                <div class="flex space-x-6">
                    <a href="#" class="text-gray-500 hover:text-blue-600">
                        <i class="fab fa-facebook-f"></i>
                    </a>
                    <a href="#" class="text-gray-500 hover:text-blue-600">
                        <i class="fab fa-twitter"></i>
                    </a>
                    <a href="#" class="text-gray-500 hover:text-blue-600">
                        <i class="fab fa-instagram"></i>
                    </a>
                    <a href="#" class="text-gray-500 hover:text-blue-600">
                        <i class="fab fa-linkedin-in"></i>
                    </a>
                </div>
            </div>
            <div class="mt-4 text-center text-sm text-gray-500">
                &copy; <%= new java.util.Date().getYear() + 1900 %> ZAIRTAM Hotels. All rights reserved.
            </div>
        </div>
    </footer>
</body>
</html>