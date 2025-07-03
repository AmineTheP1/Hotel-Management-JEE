<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    // Check if user is logged in
    String userId = (String) session.getAttribute("userId");
    if (userId == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
    
    // Database connection variables
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // User data
    Map<String, Object> user = new HashMap<>();
    List<Map<String, Object>> reservations = new ArrayList<>();
    
    try {
        // Establish database connection
        String jdbcURL = "jdbc:mysql://localhost:3306/hotels_db";
        String dbUser = "root";
        String dbPassword = "";
        
        Class.forName("com.mysql.jdbc.Driver");
        conn = DriverManager.getConnection(jdbcURL, dbUser, dbPassword);
        
        // Fetch user information
        String userQuery = "SELECT * FROM users WHERE id = ?";
        pstmt = conn.prepareStatement(userQuery);
        pstmt.setString(1, userId);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            user.put("id", rs.getString("id"));
            user.put("firstName", rs.getString("first_name"));
            user.put("lastName", rs.getString("last_name"));
            user.put("email", rs.getString("email"));
            user.put("phone", rs.getString("phone"));
            user.put("address", rs.getString("address"));
            user.put("city", rs.getString("city"));
            user.put("state", rs.getString("state"));
            user.put("zip", rs.getString("zip"));
            user.put("country", rs.getString("country"));
            user.put("dob", rs.getDate("date_of_birth"));
            user.put("language", rs.getString("preferred_language"));
            user.put("profileImage", rs.getString("profile_image"));
            user.put("memberSince", rs.getDate("created_at"));
            
            // Format member since date
            SimpleDateFormat dateFormat = new SimpleDateFormat("MMMM yyyy");
            String memberSince = dateFormat.format(user.get("memberSince"));
            user.put("memberSinceFormatted", memberSince);
            
            // Format date of birth
            if (user.get("dob") != null) {
                SimpleDateFormat dobFormat = new SimpleDateFormat("yyyy-MM-dd");
                user.put("dobFormatted", dobFormat.format(user.get("dob")));
            }
        }
        
        // Fetch user reservations
        if (pstmt != null) pstmt.close();
        if (rs != null) rs.close();
        
        String reservationQuery = "SELECT r.*, h.name as hotel_name, h.location as hotel_location, " +
                                 "rt.name as room_type, rt.price as room_price " +
                                 "FROM reservations r " +
                                 "JOIN hotels h ON r.hotel_id = h.id " +
                                 "JOIN room_types rt ON r.room_type_id = rt.id " +
                                 "WHERE r.user_id = ? " +
                                 "ORDER BY r.check_in_date DESC";
        
        pstmt = conn.prepareStatement(reservationQuery);
        pstmt.setString(1, userId);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> reservation = new HashMap<>();
            reservation.put("id", rs.getString("id"));
            reservation.put("hotelName", rs.getString("hotel_name"));
            reservation.put("hotelLocation", rs.getString("hotel_location"));
            reservation.put("roomType", rs.getString("room_type"));
            reservation.put("checkIn", rs.getDate("check_in_date"));
            reservation.put("checkOut", rs.getDate("check_out_date"));
            reservation.put("guests", rs.getInt("guests"));
            reservation.put("totalPrice", rs.getDouble("total_price"));
            reservation.put("status", rs.getString("status"));
            reservation.put("bookingDate", rs.getDate("created_at"));
            
            // Format dates
            SimpleDateFormat dateFormat = new SimpleDateFormat("MMM dd, yyyy");
            reservation.put("checkInFormatted", dateFormat.format(reservation.get("checkIn")));
            reservation.put("checkOutFormatted", dateFormat.format(reservation.get("checkOut")));
            reservation.put("bookingDateFormatted", dateFormat.format(reservation.get("bookingDate")));
            
            reservations.add(reservation);
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
    <title>ZAIRTAM - User Profile</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
            background-color: #F9FAFB;
        }
        
        .reservation-card {
            transition: all 0.3s ease;
        }
        
        .reservation-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
        }
        
        .status-badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 500;
        }
        
        .status-paid {
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
        
        .tab-content {
            display: none;
        }
        
        .tab-content.active {
            display: block;
        }
        
        .profile-image-container:hover .profile-image-overlay {
            opacity: 1;
        }
    </style>
</head>
<body>
    <!-- Navigation -->
    <nav class="bg-white shadow-sm sticky top-0 z-50">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between items-center h-16">
                <!-- Logo -->
                <div class="flex items-center">
                    <a href="../index.jsp" class="flex items-center">
                        <i class="fas fa-hotel text-blue-600 text-2xl mr-2"></i>
                        <span class="text-xl font-bold text-gray-800">ZAIRTAM</span>
                    </a>
                </div>
                
                <!-- Search -->
                <div class="hidden md:flex items-center flex-1 max-w-md mx-8">
                    <div class="w-full relative">
                        <input type="text" placeholder="Search for hotels, destinations..." class="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                        <i class="fas fa-search absolute left-3 top-3 text-gray-400"></i>
                    </div>
                </div>
                
                <!-- Right Nav Items -->
                <div class="flex items-center space-x-4">
                    <a href="#" class="text-gray-700 hover:text-blue-600">
                        <i class="fas fa-heart text-xl"></i>
                    </a>
                    
                    <a href="#" class="text-gray-700 hover:text-blue-600">
                        <i class="fas fa-bell text-xl"></i>
                    </a>
                    
                    <div class="relative">
                        <button class="flex items-center text-gray-800 hover:text-blue-600">
                            <img src="${not empty user.profileImage ? user.profileImage : 'https://randomuser.me/api/portraits/women/44.jpg'}" alt="${user.firstName} ${user.lastName}" class="h-8 w-8 rounded-full object-cover">
                            <span class="ml-2 hidden md:block">${user.firstName} ${user.lastName}</span>
                            <i class="fas fa-chevron-down ml-1 text-xs hidden md:block"></i>
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </nav>

    <!-- Main Content -->
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="flex flex-col md:flex-row gap-8">
            <!-- Profile Sidebar -->
            <div class="md:w-1/3 lg:w-1/4">
                <div class="bg-white rounded-lg shadow-sm p-6 sticky top-24">
                    <!-- Profile Image -->
                    <div class="flex flex-col items-center mb-6">
                        <div class="relative profile-image-container mb-4">
                            <img src="${not empty user.profileImage ? user.profileImage : 'https://randomuser.me/api/portraits/women/44.jpg'}" alt="${user.firstName} ${user.lastName}" class="h-24 w-24 rounded-full object-cover border-4 border-white shadow">
                            <div class="absolute inset-0 bg-black bg-opacity-50 rounded-full flex items-center justify-center opacity-0 transition-opacity duration-300 profile-image-overlay cursor-pointer">
                                <i class="fas fa-camera text-white text-xl"></i>
                            </div>
                        </div>
                        <h2 class="text-xl font-bold text-gray-800">${user.firstName} ${user.lastName}</h2>
                        <p class="text-gray-600 text-sm">Member since ${user.memberSinceFormatted}</p>
                    </div>
                    
                    <!-- Navigation Tabs -->
                    <div class="space-y-1">
                        <button id="profile-tab" class="w-full flex items-center px-4 py-3 text-blue-600 bg-blue-50 rounded-md">
                            <i class="fas fa-user w-5 text-center"></i>
                            <span class="ml-3">Profile Information</span>
                        </button>
                        <button id="reservations-tab" class="w-full flex items-center px-4 py-3 text-gray-700 hover:bg-gray-100 rounded-md">
                            <i class="fas fa-calendar-alt w-5 text-center"></i>
                            <span class="ml-3">Reservations</span>
                        </button>
                        <button id="payment-tab" class="w-full flex items-center px-4 py-3 text-gray-700 hover:bg-gray-100 rounded-md">
                            <i class="fas fa-credit-card w-5 text-center"></i>
                            <span class="ml-3">Payment Methods</span>
                        </button>
                        <button id="settings-tab" class="w-full flex items-center px-4 py-3 text-gray-700 hover:bg-gray-100 rounded-md">
                            <i class="fas fa-cog w-5 text-center"></i>
                            <span class="ml-3">Account Settings</span>
                        </button>
                    </div>
                    
                    <div class="mt-6 pt-6 border-t border-gray-200">
                        <a href="../logout.jsp" class="w-full flex items-center px-4 py-3 text-red-600 hover:bg-red-50 rounded-md">
                            <i class="fas fa-sign-out-alt w-5 text-center"></i>
                            <span class="ml-3">Sign Out</span>
                        </a>
                    </div>
                </div>
            </div>
            
            <!-- Main Content Area -->
            <div class="md:w-2/3 lg:w-3/4">
                <!-- Profile Information Tab -->
                <div id="profile-content" class="tab-content active">
                    <div class="bg-white rounded-lg shadow-sm p-6 mb-6">
                        <div class="flex justify-between items-center mb-6">
                            <h2 class="text-xl font-bold text-gray-800">Profile Information</h2>
                            <button id="edit-profile-btn" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium transition duration-200">
                                <i class="fas fa-edit mr-1"></i> Edit Profile
                            </button>
                        </div>
                        
                        <!-- View Mode -->
                        <div id="profile-view-mode">
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                                <div>
                                    <h3 class="text-sm font-medium text-gray-500 mb-1">Full Name</h3>
                                    <p class="text-gray-800">${user.firstName} ${user.lastName}</p>
                                </div>
                                <div>
                                    <h3 class="text-sm font-medium text-gray-500 mb-1">Email Address</h3>
                                    <p class="text-gray-800">${user.email}</p>
                                </div>
                                <div>
                                    <h3 class="text-sm font-medium text-gray-500 mb-1">Phone Number</h3>
                                    <p class="text-gray-800">${user.phone}</p>
                                </div>
                                <div>
                                    <h3 class="text-sm font-medium text-gray-500 mb-1">Date of Birth</h3>
                                    <p class="text-gray-800">${user.dob != null ? user.dob : 'Not provided'}</p>
                                </div>
                                <div>
                                    <h3 class="text-sm font-medium text-gray-500 mb-1">Address</h3>
                                    <p class="text-gray-800">${user.address}</p>
                                </div>
                                <div>
                                    <h3 class="text-sm font-medium text-gray-500 mb-1">City, State, ZIP</h3>
                                    <p class="text-gray-800">${user.city}, ${user.state} ${user.zip}</p>
                                </div>
                                <div>
                                    <h3 class="text-sm font-medium text-gray-500 mb-1">Country</h3>
                                    <p class="text-gray-800">${user.country}</p>
                                </div>
                                <div>
                                    <h3 class="text-sm font-medium text-gray-500 mb-1">Preferred Language</h3>
                                    <p class="text-gray-800">${user.language}</p>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Edit Mode (Hidden by default) -->
                        <div id="profile-edit-mode" class="hidden">
                            <form id="profile-edit-form" action="../UpdateProfileServlet" method="post" class="space-y-6">
                                <input type="hidden" name="userId" value="${user.id}">
                                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                                    <div>
                                        <label for="firstName" class="block text-sm font-medium text-gray-700 mb-1">First Name</label>
                                        <input type="text" id="firstName" name="firstName" value="${user.firstName}" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                    </div>
                                    <div>
                                        <label for="lastName" class="block text-sm font-medium text-gray-700 mb-1">Last Name</label>
                                        <input type="text" id="lastName" name="lastName" value="${user.lastName}" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                    </div>
                                    <div>
                                        <label for="email" class="block text-sm font-medium text-gray-700 mb-1">Email Address</label>
                                        <input type="email" id="email" name="email" value="${user.email}" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                    </div>
                                    <div>
                                        <label for="phone" class="block text-sm font-medium text-gray-700 mb-1">Phone Number</label>
                                        <input type="tel" id="phone" name="phone" value="${user.phone}" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                    </div>
                                    <div>
                                        <label for="dob" class="block text-sm font-medium text-gray-700 mb-1">Date of Birth</label>
                                        <input type="date" id="dob" name="dob" value="${user.dobFormatted}" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                    </div>
                                    <div>
                                        <label for="address" class="block text-sm font-medium text-gray-700 mb-1">Address</label>
                                        <input type="text" id="address" name="address" value="${user.address}" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                    </div>
                                    <div>
                                        <label for="city" class="block text-sm font-medium text-gray-700 mb-1">City</label>
                                        <input type="text" id="city" name="city" value="${user.city}" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                    </div>
                                    <div class="grid grid-cols-2 gap-3">
                                        <div>
                                            <label for="state" class="block text-sm font-medium text-gray-700 mb-1">State</label>
                                            <input type="text" id="state" name="state" value="${user.state}" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                        </div>
                                        <div>
                                            <label for="zip" class="block text-sm font-medium text-gray-700 mb-1">ZIP Code</label>
                                            <input type="text" id="zip" name="zip" value="${user.zip}" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                        </div>
                                    </div>
                                    <div>
                                        <label for="country" class="block text-sm font-medium text-gray-700 mb-1">Country</label>
                                        <select id="country" name="country" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                            <option value="US" ${user.country == 'United States' ? 'selected' : ''}>United States</option>
                                            <option value="CA" ${user.country == 'Canada' ? 'selected' : ''}>Canada</option>
                                            <option value="UK" ${user.country == 'United Kingdom' ? 'selected' : ''}>United Kingdom</option>
                                            <option value="FR" ${user.country == 'France' ? 'selected' : ''}>France</option>
                                            <option value="DE" ${user.country == 'Germany' ? 'selected' : ''}>Germany</option>
                                        </select>
                                    </div>
                                    <div>
                                        <label for="language" class="block text-sm font-medium text-gray-700 mb-1">Preferred Language</label>
                                        <select id="language" name="language" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                            <option value="en" ${user.language == 'English' ? 'selected' : ''}>English</option>
                                            <option value="fr" ${user.language == 'French' ? 'selected' : ''}>French</option>
                                            <option value="es" ${user.language == 'Spanish' ? 'selected' : ''}>Spanish</option>
                                            <option value="de" ${user.language == 'German' ? 'selected' : ''}>German</option>
                                            <option value="zh" ${user.language == 'Chinese' ? 'selected' : ''}>Chinese</option>
                                        </select>
                                    </div>
                                </div>
                                
                                <div class="flex justify-end space-x-3 pt-4">
                                    <button type="button" id="cancel-edit-btn" class="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 text-sm font-medium transition duration-200">
                                        Cancel
                                    </button>
                                    <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium transition duration-200">
                                        Save Changes
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                    
                    <div class="bg-white rounded-lg shadow-sm p-6">
                        <h2 class="text-xl font-bold text-gray-800 mb-6">Preferences</h2>
                        
                        <div class="space-y-4">
                            <div class="flex items-center justify-between">
                                <div>
                                    <h3 class="font-medium text-gray-800">Email Notifications</h3>
                                    <p class="text-sm text-gray-600">Receive emails about your reservations and special offers</p>
                                </div>
                                <label class="relative inline-flex items-center cursor-pointer">
                                    <input type="checkbox" checked class="sr-only peer">
                                    <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                                </label>
                            </div>
                            
                            <div class="flex items-center justify-between">
                                <div>
                                    <h3 class="font-medium text-gray-800">SMS Notifications</h3>
                                    <p class="text-sm text-gray-600">Receive text messages about your upcoming reservations</p>
                                </div>
                                <label class="relative inline-flex items-center cursor-pointer">
                                    <input type="checkbox" class="sr-only peer">
                                    <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                                </label>
                            </div>
                            
                            <div class="flex items-center justify-between">
                                <div>
                                    <h3 class="font-medium text-gray-800">Two-Factor Authentication</h3>
                                    <p class="text-sm text-gray-600">Add an extra layer of security to your account</p>
                                </div>
                                <label class="relative inline-flex items-center cursor-pointer">
                                    <input type="checkbox" checked class="sr-only peer">
                                    <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                                </label>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Reservations Tab -->
                <div id="reservations-content" class="tab-content">
                    <div class="bg-white rounded-lg shadow-sm p-6">
                        <div class="flex justify-between items-center mb-6">
                            <h2 class="text-xl font-bold text-gray-800">Your Reservations</h2>
                            <a href="../search.jsp" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium transition duration-200">
                                <i class="fas fa-plus mr-1"></i> Book New Stay
                            </a>
                        </div>
                        
                        <c:choose>
                            <c:when test="${empty reservations}">
                                <div class="text-center py-8">
                                    <i class="fas fa-calendar-alt text-gray-300 text-5xl mb-4"></i>
                                    <h3 class="text-lg font-medium text-gray-800 mb-2">No Reservations Yet</h3>
                                    <p class="text-gray-600 mb-6">You haven't made any hotel reservations yet.</p>
                                    <a href="../search.jsp" class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-md text-sm font-medium transition duration-200">
                                        Find Hotels
                                    </a>
                                </div>
                            </c:when>
                            <c:otherwise>
                                <div class="space-y-6">
                                    <c:forEach var="reservation" items="${reservations}">
                                        <div class="reservation-card border rounded-lg overflow-hidden">
                                            <div class="p-6">
                                                <div class="flex flex-col md:flex-row md:justify-between md:items-start">
                                                    <div>
                                                        <h3 class="text-lg font-semibold text-gray-800">${reservation.hotelName}</h3>
                                                        <p class="text-gray-600">${reservation.hotelLocation}</p>
                                                    </div>
                                                    <div class="mt-2 md:mt-0">
                                                        <span class="status-badge ${reservation.status == 'confirmed' ? 'status-paid' : reservation.status == 'pending' ? 'status-pending' : 'status-cancelled'}">
                                                            ${reservation.status}
                                                        </span>
                                                    </div>
                                                </div>
                                                
                                                <div class="mt-4 grid grid-cols-1 md:grid-cols-3 gap-4">
                                                    <div>
                                                        <p class="text-sm text-gray-500">Check-in</p>
                                                        <p class="font-medium">${reservation.checkInFormatted}</p>
                                                    </div>
                                                    <div>
                                                        <p class="text-sm text-gray-500">Check-out</p>
                                                        <p class="font-medium">${reservation.checkOutFormatted}</p>
                                                    </div>
                                                    <div>
                                                        <p class="text-sm text-gray-500">Room Type</p>
                                                        <p class="font-medium">${reservation.roomType}</p>
                                                    </div>
                                                </div>
                                                
                                                <div class="mt-4 flex flex-col md:flex-row md:justify-between md:items-center">
                                                    <div>
                                                        <p class="text-sm text-gray-500">
                                                        <p class="text-sm text-gray-500">Booking Date</p>
                                                        <p class="font-medium">${reservation.bookingDateFormatted}</p>
                                                    </div>
                                                    <div class="mt-2 md:mt-0">
                                                        <p class="text-sm text-gray-500">Total Price</p>
                                                        <p class="font-semibold text-lg text-blue-600">$${reservation.totalPrice}</p>
                                                    </div>
                                                </div>
                                                
                                                <div class="mt-6 flex flex-col sm:flex-row gap-3">
                                                    <a href="reservation-details.jsp?id=${reservation.id}" class="inline-flex items-center justify-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50">
                                                        <i class="fas fa-eye mr-2"></i> View Details
                                                    </a>
                                                    
                                                    <c:if test="${reservation.status != 'cancelled'}">
                                                        <a href="modify-reservation.jsp?id=${reservation.id}" class="inline-flex items-center justify-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50">
                                                            <i class="fas fa-edit mr-2"></i> Modify
                                                        </a>
                                                        
                                                        <button data-reservation-id="${reservation.id}" class="cancel-reservation-btn inline-flex items-center justify-center px-4 py-2 border border-red-300 rounded-md shadow-sm text-sm font-medium text-red-700 bg-white hover:bg-red-50">
                                                            <i class="fas fa-times mr-2"></i> Cancel
                                                        </button>
                                                    </c:if>
                                                    
                                                    <c:if test="${reservation.status == 'confirmed' && reservation.checkOut < now}">
                                                        <a href="write-review.jsp?hotel_id=${reservation.hotelId}" class="inline-flex items-center justify-center px-4 py-2 border border-blue-300 rounded-md shadow-sm text-sm font-medium text-blue-700 bg-white hover:bg-blue-50">
                                                            <i class="fas fa-star mr-2"></i> Write Review
                                                        </a>
                                                    </c:if>
                                                </div>
                                            </div>
                                        </div>
                                    </c:forEach>
                                </div>
                            </c:otherwise>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- JavaScript -->
    <script>
        // Tab Switching
        const profileTab = document.getElementById('profile-tab');
        const reservationsTab = document.getElementById('reservations-tab');
        const paymentTab = document.getElementById('payment-tab');
        const settingsTab = document.getElementById('settings-tab');
        
        const profileContent = document.getElementById('profile-content');
        const reservationsContent = document.getElementById('reservations-content');
        const paymentContent = document.getElementById('payment-content');
        const settingsContent = document.getElementById('settings-content');
        
        // Profile tab click event
        profileTab.addEventListener('click', () => {
            // Update active tab
            profileTab.classList.add('text-blue-600', 'bg-blue-50');
            profileTab.classList.remove('text-gray-700', 'hover:bg-gray-100');
            
            reservationsTab.classList.remove('text-blue-600', 'bg-blue-50');
            reservationsTab.classList.add('text-gray-700', 'hover:bg-gray-100');
            
            paymentTab.classList.remove('text-blue-600', 'bg-blue-50');
            paymentTab.classList.add('text-gray-700', 'hover:bg-gray-100');
            
            settingsTab.classList.remove('text-blue-600', 'bg-blue-50');
            settingsTab.classList.add('text-gray-700', 'hover:bg-gray-100');
            
            // Show/hide content
            profileContent.classList.add('active');
            reservationsContent.classList.remove('active');
            paymentContent.classList.remove('active');
            settingsContent.classList.remove('active');
        });
        
        // Reservations tab click event
        reservationsTab.addEventListener('click', () => {
            // Update active tab
            reservationsTab.classList.add('text-blue-600', 'bg-blue-50');
            reservationsTab.classList.remove('text-gray-700', 'hover:bg-gray-100');
            
            profileTab.classList.remove('text-blue-600', 'bg-blue-50');
            profileTab.classList.add('text-gray-700', 'hover:bg-gray-100');
            
            paymentTab.classList.remove('text-blue-600', 'bg-blue-50');
            paymentTab.classList.add('text-gray-700', 'hover:bg-gray-100');
            
            settingsTab.classList.remove('text-blue-600', 'bg-blue-50');
            settingsTab.classList.add('text-gray-700', 'hover:bg-gray-100');
            
            // Show/hide content
            reservationsContent.classList.add('active');
            profileContent.classList.remove('active');
            paymentContent.classList.remove('active');
            settingsContent.classList.remove('active');
        });
        
        // Payment tab click event
        paymentTab.addEventListener('click', () => {
            // Update active tab
            paymentTab.classList.add('text-blue-600', 'bg-blue-50');
            paymentTab.classList.remove('text-gray-700', 'hover:bg-gray-100');
            
            profileTab.classList.remove('text-blue-600', 'bg-blue-50');
            profileTab.classList.add('text-gray-700', 'hover:bg-gray-100');
            
            reservationsTab.classList.remove('text-blue-600', 'bg-blue-50');
            reservationsTab.classList.add('text-gray-700', 'hover:bg-gray-100');
            
            settingsTab.classList.remove('text-blue-600', 'bg-blue-50');
            settingsTab.classList.add('text-gray-700', 'hover:bg-gray-100');
            
            // Show/hide content
            paymentContent.classList.add('active');
            profileContent.classList.remove('active');
            reservationsContent.classList.remove('active');
            settingsContent.classList.remove('active');
        });
        
        // Settings tab click event
        settingsTab.addEventListener('click', () => {
            // Update active tab
            settingsTab.classList.add('text-blue-600', 'bg-blue-50');
            settingsTab.classList.remove('text-gray-700', 'hover:bg-gray-100');
            
            profileTab.classList.remove('text-blue-600', 'bg-blue-50');
            profileTab.classList.add('text-gray-700', 'hover:bg-gray-100');
            
            reservationsTab.classList.remove('text-blue-600', 'bg-blue-50');
            reservationsTab.classList.add('text-gray-700', 'hover:bg-gray-100');
            
            paymentTab.classList.remove('text-blue-600', 'bg-blue-50');
            paymentTab.classList.add('text-gray-700', 'hover:bg-gray-100');
            
            // Show/hide content
            settingsContent.classList.add('active');
            profileContent.classList.remove('active');
            reservationsContent.classList.remove('active');
            paymentContent.classList.remove('active');
        });
        
        // Edit Profile Toggle
        const editProfileBtn = document.getElementById('edit-profile-btn');
        const profileViewMode = document.getElementById('profile-view-mode');
        const profileEditMode = document.getElementById('profile-edit-mode');
        
        editProfileBtn.addEventListener('click', () => {
            if (profileViewMode.classList.contains('hidden')) {
                // Switch to view mode
                profileViewMode.classList.remove('hidden');
                profileEditMode.classList.add('hidden');
                editProfileBtn.innerHTML = '<i class="fas fa-edit mr-1"></i> Edit Profile';
                editProfileBtn.classList.remove('bg-gray-600');
                editProfileBtn.classList.add('bg-blue-600', 'hover:bg-blue-700');
            } else {
                // Switch to edit mode
                profileViewMode.classList.add('hidden');
                profileEditMode.classList.remove('hidden');
                editProfileBtn.innerHTML = '<i class="fas fa-times mr-1"></i> Cancel';
                editProfileBtn.classList.remove('bg-blue-600', 'hover:bg-blue-700');
                editProfileBtn.classList.add('bg-gray-600', 'hover:bg-gray-700');
            }
        });
        
        // Profile Image Upload
        const profileImageOverlay = document.querySelector('.profile-image-overlay');
        
        profileImageOverlay.addEventListener('click', () => {
            // Create a file input element
            const fileInput = document.createElement('input');
            fileInput.type = 'file';
            fileInput.accept = 'image/*';
            
            // Trigger click on the file input
            fileInput.click();
            
            // Handle file selection
            fileInput.addEventListener('change', (e) => {
                if (e.target.files && e.target.files[0]) {
                    // Here you would typically upload the file to the server
                    // For now, just show a preview
                    const reader = new FileReader();
                    
                    reader.onload = (event) => {
                        document.querySelectorAll('.profile-image-container img').forEach(img => {
                            img.src = event.target.result;
                        });
                        
                        // In a real application, you would send the file to the server here
                        // using FormData and fetch or XMLHttpRequest
                    };
                    
                    reader.readAsDataURL(e.target.files[0]);
                }
            });
        });
    </script>
</body>
</html>
