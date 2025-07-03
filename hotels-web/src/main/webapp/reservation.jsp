<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.temporal.ChronoUnit" %>
<%@ page import="java.time.format.DateTimeFormatter" %>

<%
    // Get parameters from the request
    String hotelId = request.getParameter("hotelId");
    String checkIn = request.getParameter("checkIn");
    String checkOut = request.getParameter("checkOut");
    String guests = request.getParameter("guests");
    
    // Database connection parameters
    String jdbcURL = "jdbc:mysql://localhost:3306/hotels_db";
    String dbUser = "root";
    String dbPassword = "";
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // Hotel and room data
    Map<String, Object> hotel = new HashMap<>();
    List<Map<String, Object>> roomTypes = new ArrayList<>();
    List<String> hotelImages = new ArrayList<>();
    
    // Calculate number of nights
    int numberOfNights = 1;
    try {
        LocalDate checkInDate = LocalDate.parse(checkIn);
        LocalDate checkOutDate = LocalDate.parse(checkOut);
        numberOfNights = (int) ChronoUnit.DAYS.between(checkInDate, checkOutDate);
    } catch (Exception e) {
        // Use default value if dates are invalid
        numberOfNights = 1;
    }
    
    try {
        // Establish database connection
        Class.forName("com.mysql.jdbc.Driver");
        conn = DriverManager.getConnection(jdbcURL, dbUser, dbPassword);
        
        // Fetch hotel details
        String hotelQuery = "SELECT h.*, COUNT(r.review_id) as review_count, AVG(r.rating) as avg_rating " +
                           "FROM hotels h " +
                           "LEFT JOIN reviews r ON h.hotel_id = r.hotel_id " +
                           "WHERE h.hotel_id = ? " +
                           "GROUP BY h.hotel_id";
        
        pstmt = conn.prepareStatement(hotelQuery);
        pstmt.setString(1, hotelId);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            hotel.put("id", rs.getLong("hotel_id"));
            hotel.put("name", rs.getString("name"));
            hotel.put("description", rs.getString("description"));
            hotel.put("address", rs.getString("address_line1"));
            hotel.put("city", rs.getString("city"));
            hotel.put("country", rs.getString("country"));
            hotel.put("rating", rs.getDouble("rating"));
            hotel.put("location", rs.getString("city") + ", " + rs.getString("country"));
            hotel.put("distanceFromCenter", "0.5"); // Example value
            hotel.put("reviewCount", rs.getInt("review_count"));
            
            // Add placeholder images (you can replace with actual images from your database)
            hotelImages.add("https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=80");
            hotelImages.add("https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=800&q=80");
            hotel.put("images", hotelImages);
        }
        
        // Close previous result set and statement
        rs.close();
        pstmt.close();
        
        // Fetch available room types for this hotel
        String roomQuery = "SELECT rt.*, COUNT(r.room_id) as available_rooms " +
                          "FROM room_types rt " +
                          "JOIN rooms r ON rt.room_type_id = r.room_type_id " +
                          "WHERE rt.hotel_id = ? AND r.status = 'available' " +
                          "GROUP BY rt.room_type_id " +
                          "HAVING available_rooms > 0";
        
        pstmt = conn.prepareStatement(roomQuery);
        pstmt.setString(1, hotelId);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> roomType = new HashMap<>();
            roomType.put("id", rs.getInt("room_type_id"));
            roomType.put("name", rs.getString("name"));
            roomType.put("description", rs.getString("description"));
            roomType.put("maxGuests", rs.getInt("max_guests"));
            roomType.put("price", rs.getDouble("base_price"));
            roomType.put("totalPrice", rs.getDouble("base_price") * numberOfNights);
            roomType.put("availableRooms", rs.getInt("available_rooms"));
            
            // Add room amenities (example values - you can customize based on your database)
            roomType.put("hasWifi", true);
            roomType.put("hasBreakfast", true);
            roomType.put("hasAC", true);
            roomType.put("hasTV", true);
            roomType.put("hasPrivateBathroom", true);
            roomType.put("hasRoomService", rs.getString("name").toLowerCase().contains("suite"));
            
            roomTypes.add(roomType);
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
    
    // Store data in request attributes for JSP access
    request.setAttribute("hotel", hotel);
    request.setAttribute("roomTypes", roomTypes);
    request.setAttribute("checkIn", checkIn);
    request.setAttribute("checkOut", checkOut);
    request.setAttribute("guests", guests);
    request.setAttribute("numberOfNights", numberOfNights);
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZAIRTAM - Hotel Reservation</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
        }
        
        .star-rating .fas {
            color: #FFD700;
        }
        
        .star-rating .far {
            color: #E5E7EB;
        }
        
        .carousel-container {
            scroll-behavior: smooth;
        }
        
        .carousel-item {
            flex: 0 0 100%;
        }
        
        .payment-method-content {
            max-height: 0;
            overflow: hidden;
            transition: max-height 0.3s ease-out;
        }
        
        .payment-method-content.active {
            max-height: 500px;
        }
        
        .amenity-icon {
            width: 24px;
            height: 24px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }
        
        @media (max-width: 768px) {
            .reservation-container {
                flex-direction: column;
            }
            
            .hotel-details, .reservation-form {
                width: 100%;
            }
        }
    </style>
</head>
<body class="bg-gray-50">
    <!-- Navigation -->
    <jsp:include page="WEB-INF/components/header.jsp" />

    <!-- Reservation Header -->
    <div class="bg-blue-600 py-8">
        <div class="max-w-7xl mx-auto px-4">
            <div class="flex flex-col md:flex-row justify-between items-start md:items-center">
                <div class="text-white mb-4 md:mb-0">
                    <h1 class="text-2xl font-bold">${hotel.name}</h1>
                    <p class="text-blue-100">
                        <i class="fas fa-map-marker-alt mr-1"></i> 
                        ${hotel.location}, ${hotel.distanceFromCenter} miles from center
                    </p>
                </div>
                
                <div class="flex items-center">
                    <div class="star-rating text-white mr-2">
                        <c:forEach begin="1" end="5" var="i">
                            <c:choose>
                                <c:when test="${i <= hotel.rating}">
                                    <i class="fas fa-star"></i>
                                </c:when>
                                <c:otherwise>
                                    <i class="far fa-star"></i>
                                </c:otherwise>
                            </c:choose>
                        </c:forEach>
                    </div>
                    <span class="text-white">${hotel.rating}.0 (${hotel.reviewCount} reviews)</span>
                </div>
            </div>
        </div>
    </div>

    <!-- Main Content -->
    <div class="max-w-7xl mx-auto px-4 py-8">
        <div class="flex flex-col lg:flex-row gap-8 reservation-container">
            <!-- Hotel Details -->
            <div class="lg:w-7/12 hotel-details">
                <!-- Image Carousel -->
                <div class="bg-white rounded-lg shadow-sm overflow-hidden mb-6">
                    <div class="relative">
                        <div class="overflow-hidden">
                            <div class="flex carousel-container" id="image-carousel">
                                <c:forEach items="${hotel.images}" var="image" varStatus="status">
                                    <div class="carousel-item">
                                        <img src="${image}" alt="Room ${status.index + 1}" class="w-full h-80 object-cover">
                                    </div>
                                </c:forEach>
                                
                                <!-- Fallback images if no images in database -->
                                <c:if test="${empty hotel.images}">
                                    <div class="carousel-item">
                                        <img src="https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80" alt="Room 1" class="w-full h-80 object-cover">
                                    </div>
                                    <div class="carousel-item">
                                        <img src="https://images.unsplash.com/photo-1590490360182-c33d57733427?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1474&q=80" alt="Room 2" class="w-full h-80 object-cover">
                                    </div>
                                </c:if>
                            </div>
                        </div>
                        
                        <button id="prev-btn" class="absolute left-2 top-1/2 transform -translate-y-1/2 bg-white/80 hover:bg-white text-gray-800 p-2 rounded-full shadow-md">
                            <i class="fas fa-chevron-left"></i>
                        </button>
                        
                        <button id="next-btn" class="absolute right-2 top-1/2 transform -translate-y-1/2 bg-white/80 hover:bg-white text-gray-800 p-2 rounded-full shadow-md">
                            <i class="fas fa-chevron-right"></i>
                        </button>
                    </div>
                    
                    <div class="p-4 flex justify-center space-x-2">
                        <c:forEach items="${hotel.images}" var="image" varStatus="status">
                            <button class="w-3 h-3 rounded-full ${status.index == 0 ? 'bg-blue-600' : 'bg-gray-300'} carousel-dot" data-index="${status.index}"></button>
                        </c:forEach>
                        
                        <!-- Fallback dots if no images in database -->
                        <c:if test="${empty hotel.images}">
                            <button class="w-3 h-3 rounded-full bg-blue-600 carousel-dot active" data-index="0"></button>
                            <button class="w-3 h-3 rounded-full bg-gray-300 carousel-dot" data-index="1"></button>
                        </c:if>
                    </div>
                </div>
                
                <!-- Room Details -->
                <div class="bg-white rounded-lg shadow-sm p-6 mb-6">
                    <h2 class="text-2xl font-bold text-gray-800 mb-4">${room.name}</h2>
                    
                    <div class="mb-6">
                        <h3 class="text-lg font-semibold mb-2">Room Description</h3>
                        <p class="text-gray-600">
                            ${room.description}
                        </p>
                    </div>
                    
                    <div class="mb-6">
                        <h3 class="text-lg font-semibold mb-3">Room Amenities</h3>
                        <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
                            <c:if test="${room.hasWifi}">
                                <div class="flex items-center">
                                    <div class="amenity-icon bg-blue-100 rounded-full mr-2">
                                        <i class="fas fa-wifi text-blue-600"></i>
                                    </div>
                                    <span class="text-gray-700">Free WiFi</span>
                                </div>
                            </c:if>
                            <c:if test="${room.hasBreakfast}">
                                <div class="flex items-center">
                                    <div class="amenity-icon bg-blue-100 rounded-full mr-2">
                                        <i class="fas fa-coffee text-blue-600"></i>
                                    </div>
                                    <span class="text-gray-700">Breakfast Included</span>
                                </div>
                            </c:if>
                            <c:if test="${room.hasAC}">
                                <div class="flex items-center">
                                    <div class="amenity-icon bg-blue-100 rounded-full mr-2">
                                        <i class="fas fa-snowflake text-blue-600"></i>
                                    </div>
                                    <span class="text-gray-700">Air Conditioning</span>
                                </div>
                            </c:if>
                            <c:if test="${room.hasTV}">
                                <div class="flex items-center">
                                    <div class="amenity-icon bg-blue-100 rounded-full mr-2">
                                        <i class="fas fa-tv text-blue-600"></i>
                                    </div>
                                    <span class="text-gray-700">Flat-screen TV</span>
                                </div>
                            </c:if>
                            <c:if test="${room.hasPrivateBathroom}">
                                <div class="flex items-center">
                                    <div class="amenity-icon bg-blue-100 rounded-full mr-2">
                                        <i class="fas fa-bath text-blue-600"></i>
                                    </div>
                                    <span class="text-gray-700">Private Bathroom</span>
                                </div>
                            </c:if>
                            <c:if test="${room.hasRoomService}">
                                <div class="flex items-center">
                                    <div class="amenity-icon bg-blue-100 rounded-full mr-2">
                                        <i class="fas fa-concierge-bell text-blue-600"></i>
                                    </div>
                                    <span class="text-gray-700">Room Service</span>
                                </div>
                            </c:if>
                            <c:if test="${hotel.hasParking}">
                                <div class="flex items-center">
                                    <div class="amenity-icon bg-blue-100 rounded-full mr-2">
                                        <i class="fas fa-parking text-blue-600"></i>
                                    </div>
                                    <span class="text-gray-700">Parking Available</span>
                                </div>
                            </c:if>
                            <c:if test="${hotel.hasPool}">
                                <div class="flex items-center">
                                    <div class="amenity-icon bg-blue-100 rounded-full mr-2">
                                        <i class="fas fa-swimming-pool text-blue-600"></i>
                                    </div>
                                    <span class="text-gray-700">Swimming Pool</span>
                                </div>
                            </c:if>
                        </div>
                    </div>
                    
                    <div>
                        <h3 class="text-lg font-semibold mb-3">Availability</h3>
                        <div class="flex items-center">
                            <div class="w-4 h-4 rounded-full bg-green-500 mr-2"></div>
                            <span class="text-green-600 font-medium">Available for your selected dates</span>
                        </div>
                        <p class="text-gray-600 text-sm mt-1">${param.checkIn} - ${param.checkOut} · ${param.nights} nights · ${param.guests} guests</p>
                    </div>
                </div>
                
                <!-- Price Details -->
                <div class="bg-white rounded-lg shadow-sm p-6 mb-6">
                    <h3 class="text-lg font-semibold mb-4">Price Details</h3>
                    
                    <div class="space-y-2 mb-4">
                        <div class="flex justify-between">
                            <span class="text-gray-600">Room rate (per night)</span>
                            <span class="font-medium">$${room.pricePerNight}</span>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-gray-600">Number of nights</span>
                            <span class="font-medium">${param.nights}</span>
                        </div>
                        <div class="flex justify-between">
                            <span class="text-gray-600">Taxes and fees</span>
                            <span class="font-medium">$${taxesAndFees}</span>
                        </div>
                    </div>
                    
                    <div class="border-t pt-4 flex justify-between">
                        <span class="text-lg font-semibold">Total</span>
                        <span class="text-lg font-bold text-blue-600">$${totalPrice}</span>
                    </div>
                    
                    <c:if test="${hotel.freeCancel}">
                        <div class="mt-4 text-green-600 text-sm">
                            <i class="fas fa-check-circle mr-1"></i> Free cancellation until ${cancelDate}
                        </div>
                    </c:if>
                </div>
                
                <!-- Hotel Policies -->
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <h3 class="text-lg font-semibold mb-4">Hotel Policies</h3>
                    
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <p class="font-medium text-gray-800 mb-1">Check-in</p>
                            <p class="text-gray-600">From ${hotel.checkInTime}</p>
                        </div>
                        <div>
                            <p class="font-medium text-gray-800 mb-1">Check-out</p>
                            <p class="text-gray-600">Until ${hotel.checkOutTime}</p>
                        </div>
                        <div>
                            <p class="font-medium text-gray-800 mb-1">Cancellation</p>
                            <p class="text-gray-600">${hotel.cancellationPolicy}</p>
                        </div>
                        <div>
                            <p class="font-medium text-gray-800 mb-1">Children</p>
                            <p class="text-gray-600">${hotel.childrenPolicy}</p>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Reservation Form -->
            <div class="lg:w-5/12 reservation-form">
                <div class="bg-white rounded-lg shadow-sm p-6 sticky top-24">
                    <h2 class="text-xl font-bold text-gray-800 mb-4">Book Your Stay</h2>
                    
                    <form action="process-reservation.jsp" method="post">
                        <input type="hidden" name="hotelId" value="${hotel.id}">
                        
                        <!-- Date Selection -->
                        <div class="mb-4">
                            <label class="block text-sm font-medium text-gray-700 mb-1">Check-in / Check-out</label>
                            <div class="flex space-x-2">
                                <div class="w-1/2">
                                    <input type="date" name="checkIn" value="${checkIn}" required
                                        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                                </div>
                                <div class="w-1/2">
                                    <input type="date" name="checkOut" value="${checkOut}" required
                                        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                                </div>
                            </div>
                            <p class="text-sm text-gray-500 mt-1">${numberOfNights} night(s)</p>
                        </div>
                        
                        <!-- Guests -->
                        <div class="mb-4">
                            <label for="guests" class="block text-sm font-medium text-gray-700 mb-1">Guests</label>
                            <select id="guests" name="guests" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                                <c:forEach begin="1" end="10" var="i">
                                    <option value="${i}" ${guests eq i ? 'selected' : ''}>${i} Guest(s)</option>
                                </c:forEach>
                            </select>
                        </div>
                        
                        <!-- Room Selection -->
                        <div class="mb-6">
                            <label class="block text-sm font-medium text-gray-700 mb-2">Select Room Type</label>
                            
                            <c:forEach items="${roomTypes}" var="room" varStatus="status">
                                <div class="border rounded-md p-4 mb-3 ${status.first ? 'border-blue-500 bg-blue-50' : 'border-gray-200'}">
                                    <div class="flex items-start">
                                        <input type="radio" name="roomTypeId" value="${room.id}" id="room-${room.id}" 
                                               class="mt-1 mr-3" ${status.first ? 'checked' : ''}>
                                        <label for="room-${room.id}" class="flex-grow cursor-pointer">
                                            <div class="flex justify-between">
                                                <span class="font-medium text-gray-800">${room.name}</span>
                                                <span class="font-bold text-gray-800">$${room.price} <span class="font-normal text-sm">/ night</span></span>
                                            </div>
                                            <p class="text-sm text-gray-600 mt-1">${room.description}</p>
                                            <div class="text-sm text-gray-600 mt-2">
                                                <span class="mr-3"><i class="fas fa-user mr-1"></i> Max ${room.maxGuests} guests</span>
                                                <span><i class="fas fa-door-open mr-1"></i> ${room.availableRooms} rooms left</span>
                                            </div>
                                        </label>
                                    </div>
                                </div>
                            </c:forEach>
                        </div>
                        
                        <!-- Price Summary -->
                        <div class="border-t border-gray-200 pt-4 mb-4">
                            <div class="flex justify-between mb-2">
                                <span class="text-gray-600">Room (${numberOfNights} nights)</span>
                                <span class="text-gray-800">$<span id="roomPrice">0</span></span>
                            </div>
                            <div class="flex justify-between mb-2">
                                <span class="text-gray-600">Taxes & fees</span>
                                <span class="text-gray-800">$<span id="taxesPrice">0</span></span>
                            </div>
                            <div class="flex justify-between font-bold text-lg mt-2 pt-2 border-t border-gray-200">
                                <span>Total</span>
                                <span>$<span id="totalPrice">0</span></span>
                            </div>
                        </div>
                        
                        <!-- Guest Information -->
                        <div class="mb-4">
                            <h3 class="font-medium text-gray-800 mb-2">Guest Information</h3>
                            
                            <div class="mb-3">
                                <label for="fullName" class="block text-sm font-medium text-gray-700 mb-1">Full Name</label>
                                <input type="text" id="fullName" name="fullName" required
                                       class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                            </div>
                            
                            <div class="mb-3">
                                <label for="email" class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                                <input type="email" id="email" name="email" required
                                       class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                            </div>
                            
                            <div class="mb-3">
                                <label for="phone" class="block text-sm font-medium text-gray-700 mb-1">Phone Number</label>
                                <input type="tel" id="phone" name="phone" required
                                       class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                            </div>
                        </div>
                        
                        <!-- Submit Button -->
                        <button type="submit" class="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 rounded-md font-medium">
                            Complete Reservation
                        </button>
                        
                        <p class="text-xs text-gray-500 mt-3 text-center">
                            By clicking "Complete Reservation", you agree to our terms and conditions.
                        </p>
                    </form>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Footer -->
    <footer class="bg-gray-800 text-white py-12">
        <div class="max-w-7xl mx-auto px-4">
            <div class="grid grid-cols-1 md:grid-cols-4 gap-8">
                <div>
                    <div class="flex items-center mb-4">
                        <i class="fas fa-hotel text-blue-400 text-2xl mr-2"></i>
                        <span class="text-xl font-bold">ZAIRTAM</span>
                    </div>
                    <p class="text-gray-400 mb-4">
                        Book your perfect stay with confidence. Best rates guaranteed.
                    </p>
                    <div class="flex space-x-4">
                        <a href="#" class="text-gray-400 hover:text-white">
                            <i class="fab fa-facebook-f"></i>
                        </a>
                        <a href="#" class="text-gray-400 hover:text-white">
                            <i class="fab fa-twitter"></i>
                        </a>
                        <a href="#" class="text-gray-400 hover:text-white">
                            <i class="fab fa-instagram"></i>
                        </a>
                        <a href="#" class="text-gray-400 hover:text-white">
                            <i class="fab fa-linkedin-in"></i>
                        </a>
                    </div>
                </div>
                
                <div>
                    <h3 class="text-lg font-semibold mb-4">Company</h3>
                    <ul class="space-y-2">
                        <li><a href="#" class="text-gray-400 hover:text-white">About Us</a></li>
                        <li><a href="#" class="text-gray-400 hover:text-white">Careers</a></li>
                        <li><a href="#" class="text-gray-400 hover:text-white">Blog</a></li>
                        <li><a href="#" class="text-gray-400 hover:text-white">Press</a></li>
                    </ul>
                </div>
                
                <div>
                    <h3 class="text-lg font-semibold mb-4">Support</h3>
                    <ul class="space-y-2 text-gray-400">
                        <li><a href="#" class="text-gray-400 hover:text-white">Contact Us</a></li>
                        <li><a href="#" class="text-gray-400 hover:text-white">Help Center</a></li>
                        <li><a href="#" class="text-gray-400 hover:text-white">Cancellation Options</a></li>
                        <li><a href="#" class="text-gray-400 hover:text-white">Safety Resource Center</a></li>
                    </ul>
                </div>
                
                <div>
                    <h3 class="text-lg font-semibold mb-4">Contact Us</h3>
                    <ul class="space-y-2 text-gray-400">
                        <li class="flex items-start">
                            <i class="fas fa-map-marker-alt mt-1 mr-2"></i>
                            <span>123 Hotel Street, City, Country</span>
                        </li>
                        <li class="flex items-start">
                            <i class="fas fa-phone-alt mt-1 mr-2"></i>
                            <span>+1 234 567 8900</span>
                        </li>
                        <li class="flex items-start">
                            <i class="fas fa-envelope mt-1 mr-2"></i>
                            <span>info@zairtam.com</span>
                        </li>
                    </ul>
                    
                    <div class="mt-4">
                        <h4 class="text-sm font-semibold mb-2">Subscribe to our newsletter</h4>
                        <div class="flex">
                            <input type="email" placeholder="Your email" class="px-3 py-2 text-sm text-gray-800 bg-gray-100 rounded-l-md focus:outline-none w-full">
                            <button class="bg-blue-600 hover:bg-blue-700 text-white px-3 py-2 rounded-r-md text-sm">
                                <i class="fas fa-paper-plane"></i>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="border-t border-gray-700 mt-8 pt-8 text-center text-gray-400 text-sm">
                <p>&copy; 2023 ZAIRTAM. All rights reserved.</p>
            </div>
        </div>
    </footer>

    <!-- JavaScript -->
    <script>
        // Mobile menu toggle
        const mobileMenuButton = document.getElementById('mobile-menu-button');
        const mobileMenu = document.getElementById('mobile-menu');
        
        mobileMenuButton.addEventListener('click', () => {
            mobileMenu.classList.toggle('hidden');
        });
        
        // Image carousel
        const carousel = document.getElementById('image-carousel');
        const prevBtn = document.getElementById('prev-btn');
        const nextBtn = document.getElementById('next-btn');
        const dots = document.querySelectorAll('.carousel-dot');
        
        let currentIndex = 0;
        const totalSlides = carousel.children.length;
        
        function updateCarousel() {
            carousel.style.transform = `translateX(-${currentIndex * 100}%)`;
            
            // Update dots
            dots.forEach((dot, index) => {
                if (index === currentIndex) {
                    dot.classList.add('bg-blue-600');
                    dot.classList.remove('bg-gray-300');
                } else {
                    dot.classList.add('bg-gray-300');
                    dot.classList.remove('bg-blue-600');
                }
            });
        }
        
        prevBtn.addEventListener('click', () => {
            currentIndex = (currentIndex - 1 + totalSlides) % totalSlides;
            updateCarousel();
        });
        
        nextBtn.addEventListener('click', () => {
            currentIndex = (currentIndex + 1) % totalSlides;
            updateCarousel();
        });
        
        dots.forEach((dot, index) => {
            dot.addEventListener('click', () => {
                currentIndex = index;
                updateCarousel();
            });
        });
        
        // Payment method selection
        const paymentMethods = document.querySelectorAll('.payment-method');
        const paymentContents = document.querySelectorAll('.payment-method-content');
        
        paymentMethods.forEach((method, index) => {
            method.addEventListener('click', () => {
                // Update radio button
                const radio = method.querySelector('input[type="radio"]');
                radio.checked = true;
                
                // Show selected payment method content
                paymentContents.forEach((content, i) => {
                    if (i === index) {
                        content.classList.add('active');
                    } else {
                        content.classList.remove('active');
                    }
                });
            });
        });
        
        // Form validation
        const reservationForm = document.getElementById('reservation-form');
        
        reservationForm.addEventListener('submit', function(e) {
            let isValid = true;
            
            // Basic validation
            const requiredFields = this.querySelectorAll('[required]');
            requiredFields.forEach(field => {
                if (!field.value.trim()) {
                    isValid = false;
                    field.classList.add('border-red-500');
                } else {
                    field.classList.remove('border-red-500');
                }
            });
            
            // Credit card validation if credit card payment is selected
            const creditCardRadio = document.getElementById('credit-card');
            if (creditCardRadio && creditCardRadio.checked) {
                const cardNumber = document.getElementById('card-number');
                const cardExpiry = document.getElementById('card-expiry');
                const cardCvv = document.getElementById('card-cvv');
                
                // Simple validation - can be enhanced with more specific checks
                if (cardNumber && (!cardNumber.value.trim() || cardNumber.value.length < 13)) {
                    isValid = false;
                    cardNumber.classList.add('border-red-500');
                }
                
                if (cardExpiry && !cardExpiry.value.trim()) {
                    isValid = false;
                    cardExpiry.classList.add('border-red-500');
                }
                
                if (cardCvv && (!cardCvv.value.trim() || cardCvv.value.length < 3)) {
                    isValid = false;
                    cardCvv.classList.add('border-red-500');
                }
            }
            
            if (!isValid) {
                e.preventDefault();
                alert('Please fill in all required fields correctly.');
            }
        });
    </script>
</body>
</html>
<script>
    // Mobile menu toggle
    const mobileMenuButton = document.getElementById('mobile-menu-button');
    const mobileMenu = document.getElementById('mobile-menu');
    
    mobileMenuButton.addEventListener('click', () => {
        mobileMenu.classList.toggle('hidden');
    });
    
    // Image carousel functionality
    const carousel = document.getElementById('image-carousel');
    const prevBtn = document.getElementById('prev-btn');
    const nextBtn = document.getElementById('next-btn');
    const carouselDots = document.querySelectorAll('.carousel-dot');
    let currentIndex = 0;
    
    function updateCarousel() {
        const itemWidth = carousel.querySelector('.carousel-item').offsetWidth;
        carousel.scrollLeft = currentIndex * itemWidth;
        
        // Update dots
        carouselDots.forEach((dot, index) => {
            if (index === currentIndex) {
                dot.classList.add('bg-blue-600');
                dot.classList.remove('bg-gray-300');
            } else {
                dot.classList.add('bg-gray-300');
                dot.classList.remove('bg-blue-600');
            }
        });
    }
    
    prevBtn.addEventListener('click', () => {
        if (currentIndex > 0) {
            currentIndex--;
            updateCarousel();
        }
    });
    
    nextBtn.addEventListener('click', () => {
        if (currentIndex < carousel.querySelectorAll('.carousel-item').length - 1) {
            currentIndex++;
            updateCarousel();
        }
    });
    
    carouselDots.forEach((dot, index) => {
        dot.addEventListener('click', () => {
            currentIndex = index;
            updateCarousel();
        });
    });
    
    // Price calculation
    const roomTypeRadios = document.querySelectorAll('input[name="roomTypeId"]');
    const roomPriceElement = document.getElementById('roomPrice');
    const taxesPriceElement = document.getElementById('taxesPrice');
    const totalPriceElement = document.getElementById('totalPrice');
    const numberOfNights = ${numberOfNights};
    
    // Room prices from database
    const roomPrices = {};
    <c:forEach items="${roomTypes}" var="room">
        roomPrices[${room.id}] = ${room.price};
    </c:forEach>
    
    function updatePrices() {
        let selectedRoomId = null;
        
        roomTypeRadios.forEach(radio => {
            if (radio.checked) {
                selectedRoomId = radio.value;
            }
        });
        
        if (selectedRoomId && roomPrices[selectedRoomId]) {
            const basePrice = roomPrices[selectedRoomId] * numberOfNights;
            const taxesAndFees = basePrice * 0.12; // 12% taxes and fees
            const totalPrice = basePrice + taxesAndFees;
            
            roomPriceElement.textContent = basePrice.toFixed(2);
            taxesPriceElement.textContent = taxesAndFees.toFixed(2);
            totalPriceElement.textContent = totalPrice.toFixed(2);
        }
    }
    
    // Add event listeners to room type radios
    roomTypeRadios.forEach(radio => {
        radio.addEventListener('change', updatePrices);
    });
    
    // Initialize prices
    updatePrices();
</script>
</body>
</html>