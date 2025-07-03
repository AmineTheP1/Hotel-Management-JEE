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
    List<Map<String, Object>> upcomingReservations = new ArrayList<>();
    List<Map<String, Object>> pastReservations = new ArrayList<>();
    List<Map<String, Object>> cancelledReservations = new ArrayList<>();
    
    // Statistics
    int totalReservations = 0;
    int upcomingCount = 0;
    int pastCount = 0;
    int cancelledCount = 0;
    double totalSpent = 0.0;
    
    try {
        // Establish database connection
        String jdbcURL = "jdbc:mysql://localhost:4200/hotel?useSSL=false";
        String dbUser = "root";
        String dbPassword = "Hamza_13579";
        
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
            user.put("profileImage", rs.getString("profile_image"));
            user.put("memberSince", rs.getDate("created_at"));
            
            // Format member since date
            SimpleDateFormat dateFormat = new SimpleDateFormat("MMMM yyyy");
            String memberSince = dateFormat.format(user.get("memberSince"));
            user.put("memberSinceFormatted", memberSince);
        }
        
        // Fetch user reservations
        if (pstmt != null) pstmt.close();
        if (rs != null) rs.close();
        
        String reservationQuery = "SELECT r.*, h.name as hotel_name, h.location as hotel_location, " +
                                 "h.image as hotel_image, rt.name as room_type, rt.price as room_price " +
                                 "FROM reservations r " +
                                 "JOIN hotels h ON r.hotel_id = h.id " +
                                 "JOIN room_types rt ON r.room_type_id = rt.id " +
                                 "WHERE r.user_id = ? " +
                                 "ORDER BY r.check_in_date DESC";
        
        pstmt = conn.prepareStatement(reservationQuery);
        pstmt.setString(1, userId);
        rs = pstmt.executeQuery();
        
        // Get current date for comparison
        java.util.Date currentDate = new java.util.Date();
        
        while (rs.next()) {
            Map<String, Object> reservation = new HashMap<>();
            reservation.put("id", rs.getString("id"));
            reservation.put("hotelId", rs.getString("hotel_id"));
            reservation.put("hotelName", rs.getString("hotel_name"));
            reservation.put("hotelLocation", rs.getString("hotel_location"));
            reservation.put("hotelImage", rs.getString("hotel_image"));
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
            
            // Calculate nights
            long diffInMillies = ((java.util.Date) reservation.get("checkOut")).getTime() - ((java.util.Date) reservation.get("checkIn")).getTime();
            int nights = (int) (diffInMillies / (1000 * 60 * 60 * 24));
            reservation.put("nights", nights);
            
            // Add to appropriate lists based on status and dates
            String status = (String) reservation.get("status");
            java.util.Date checkOutDate = (java.util.Date) reservation.get("checkOut");
            
            if ("cancelled".equalsIgnoreCase(status)) {
                cancelledReservations.add(reservation);
                cancelledCount++;
            } else if (checkOutDate.before(currentDate)) {
                pastReservations.add(reservation);
                pastCount++;
                // Add to total spent only for completed stays
                totalSpent += (Double) reservation.get("totalPrice");
            } else {
                upcomingReservations.add(reservation);
                upcomingCount++;
            }
            
            // Add to all reservations list
            reservations.add(reservation);
            totalReservations++;
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
    <title>ZAIRTAM - Mes Réservations</title>
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
        
        .tab-content {
            display: none;
        }
        
        .tab-content.active {
            display: block;
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
                        <input type="text" placeholder="Rechercher des hôtels, destinations..." class="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
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
                            <% if (user.get("profileImage") != null && !((String)user.get("profileImage")).isEmpty()) { %>
                                <img src="${user.profileImage}" alt="${user.firstName} ${user.lastName}" class="h-8 w-8 rounded-full object-cover">
                            <% } else { %>
                                <div class="h-8 w-8 rounded-full bg-blue-100 flex items-center justify-center">
                                    <i class="fas fa-user text-blue-600"></i>
                                </div>
                            <% } %>
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
                            <% if (user.get("profileImage") != null && !((String)user.get("profileImage")).isEmpty()) { %>
                                <img src="${user.profileImage}" alt="${user.firstName} ${user.lastName}" class="h-24 w-24 rounded-full object-cover border-4 border-white shadow">
                            <% } else { %>
                                <div class="h-24 w-24 rounded-full bg-blue-100 flex items-center justify-center border-4 border-white shadow">
                                    <i class="fas fa-user text-blue-600 text-4xl"></i>
                                </div>
                            <% } %>
                        </div>
                        <h2 class="text-xl font-bold text-gray-800">${user.firstName} ${user.lastName}</h2>
                        <p class="text-gray-600 text-sm">Membre depuis ${user.memberSinceFormatted}</p>
                    </div>
                    
                    <!-- Navigation Tabs -->
                    <div class="space-y-1">
                        <a href="dashboard.jsp" class="w-full flex items-center px-4 py-3 text-gray-700 hover:bg-gray-100 rounded-md">
                            <i class="fas fa-user w-5 text-center"></i>
                            <span class="ml-3">Informations du profil</span>
                        </a>
                        <a href="Reservations.jsp" class="w-full flex items-center px-4 py-3 text-blue-600 bg-blue-50 rounded-md">
                            <i class="fas fa-calendar-alt w-5 text-center"></i>
                            <span class="ml-3">Réservations</span>
                        </a>
                        <a href="Payment-Methods.jsp" class="w-full flex items-center px-4 py-3 text-gray-700 hover:bg-gray-100 rounded-md">
                            <i class="fas fa-credit-card w-5 text-center"></i>
                            <span class="ml-3">Moyens de paiement</span>
                        </a>
                        <a href="Account-Settings.jsp" class="w-full flex items-center px-4 py-3 text-gray-700 hover:bg-gray-100 rounded-md">
                            <i class="fas fa-cog w-5 text-center"></i>
                            <span class="ml-3">Paramètres du compte</span>
                        </a>
                    </div>
                    
                    <div class="mt-6 pt-6 border-t border-gray-200">
                        <a href="../logout.jsp" class="w-full flex items-center px-4 py-3 text-red-600 hover:bg-red-50 rounded-md">
                            <i class="fas fa-sign-out-alt w-5 text-center"></i>
                            <span class="ml-3">Déconnexion</span>
                        </a>
                    </div>
                </div>
            </div>
            
            <!-- Main Content Area -->
            <div class="md:w-2/3 lg:w-3/4">
                <!-- Reservations Overview -->
                <div class="bg-white rounded-lg shadow-sm p-6 mb-6">
                    <h2 class="text-xl font-bold text-gray-800 mb-4">Aperçu des réservations</h2>
                    
                    <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
                        <div class="bg-blue-50 rounded-lg p-4">
                            <div class="flex items-center">
                                <div class="bg-blue-100 rounded-full p-3 mr-4">
                                    <i class="fas fa-calendar-check text-blue-600 text-xl"></i>
                                </div>
                                <div>
                                    <p class="text-sm text-gray-500">Total des réservations</p>
                                    <p class="text-xl font-bold text-gray-800"><%= totalReservations %></p>
                                </div>
                            </div>
                        </div>
                        
                        <div class="bg-green-50 rounded-lg p-4">
                            <div class="flex items-center">
                                <div class="bg-green-100 rounded-full p-3 mr-4">
                                    <i class="fas fa-plane-departure text-green-600 text-xl"></i>
                                </div>
                                <div>
                                    <p class="text-sm text-gray-500">À venir</p>
                                    <p class="text-xl font-bold text-gray-800"><%= upcomingCount %></p>
                                </div>
                            </div>
                        </div>
                        
                        <div class="bg-purple-50 rounded-lg p-4">
                            <div class="flex items-center">
                                <div class="bg-purple-100 rounded-full p-3 mr-4">
                                    <i class="fas fa-history text-purple-600 text-xl"></i>
                                </div>
                                <div>
                                    <p class="text-sm text-gray-500">Passées</p>
                                    <p class="text-xl font-bold text-gray-800"><%= pastCount %></p>
                                </div>
                            </div>
                        </div>
                        
                        <div class="bg-yellow-50 rounded-lg p-4">
                            <div class="flex items-center">
                                <div class="bg-yellow-100 rounded-full p-3 mr-4">
                                    <i class="fas fa-coins text-yellow-600 text-xl"></i>
                                </div>
                                <div>
                                    <p class="text-sm text-gray-500">Total dépensé</p>
                                    <p class="text-xl font-bold text-gray-800"><%= String.format("%.2f €", totalSpent) %></p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Reservations Tabs -->
                <div class="bg-white rounded-lg shadow-sm overflow-hidden">
                    <div class="flex border-b">
                        <button id="upcoming-tab-btn" class="flex-1 py-4 px-6 text-center font-medium text-blue-600 border-b-2 border-blue-600">
                            À venir (<%= upcomingCount %>)
                        </button>
                        <button id="past-tab-btn" class="flex-1 py-4 px-6 text-center font-medium text-gray-500 hover:text-gray-700">
                            Passées (<%= pastCount %>)
                        </button>
                        <button id="cancelled-tab-btn" class="flex-1 py-4 px-6 text-center font-medium text-gray-500 hover:text-gray-700">
                            Annulées (<%= cancelledCount %>)
                        </button>
                    </div>
                    
                    <!-- Upcoming Reservations Tab -->
                    <div id="upcoming-tab" class="tab-content active p-6">
                        <% if (upcomingReservations.isEmpty()) { %>
                            <div class="text-center py-8">
                                <i class="fas fa-calendar-alt text-gray-300 text-5xl mb-4"></i>
                                <h3 class="text-lg font-medium text-gray-700 mb-2">Aucune réservation à venir</h3>
                                <p class="text-gray-500 mb-4">Vous n'avez pas de réservations à venir pour le moment.</p>
                                <a href="../index.jsp" class="inline-block bg-blue-600 hover:bg-blue-700 text-white font-medium px-6 py-3 rounded-lg transition duration-200">
                                    Réserver un hôtel
                                </a>
                            </div>
                        <% } else { %>
                            <div class="space-y-6">
                                <% for (Map<String, Object> reservation : upcomingReservations) { %>
                                    <div class="reservation-card bg-white border rounded-lg overflow-hidden">
                                        <div class="md:flex">
                                            <div class="md:w-1/3 h-48 md:h-auto">
                                                <img src="${not empty reservation.hotelImage ? reservation.hotelImage : 'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80'}" 
                                                     alt="${reservation.hotelName}" 
                                                     class="w-full h-full object-cover">
                                            </div>
                                            <div class="p-6 md:w-2/3">
                                                <div class="flex justify-between items-start mb-2">
                                                    <h3 class="text-lg font-bold text-gray-800">${reservation.hotelName}</h3>
                                                    <span class="status-badge ${reservation.status == 'confirmed' ? 'status-confirmed' : 'status-pending'}">
                                                        ${reservation.status == 'confirmed' ? 'Confirmée' : 'En attente'}
                                                    </span>
                                                </div>
                                                <p class="text-gray-600 mb-4">
                                                    <i class="fas fa-map-marker-alt text-red-500 mr-1"></i> ${reservation.hotelLocation}
                                                </p>
                                                
                                                <div class="grid grid-cols-2 gap-4 mb-4">
                                                    <div>
                                                        <p class="text-sm text-gray-500">Check-in</p>
                                                        <p class="font-medium">${reservation.checkInFormatted}</p>
                                                    </div>
                                                    <div>
                                                        <p class="text-sm text-gray-500">Check-out</p>
                                                        <p class="font-medium">${reservation.checkOutFormatted}</p>
                                                    </div>
                                                    <div>
                                                        <p class="text-sm text-gray-500">Chambre</p>
                                                        <p class="font-medium">${reservation.roomType}</p>
                                                    </div>
                                                    <div>
                                                        <p class="text-sm text-gray-500">Voyageurs</p>
                                                        <p class="font-medium">${reservation.guests} personne(s)</p>
                                                    </div>
                                                </div>
                                                
                                                <div class="flex justify-between items-center pt-4 border-t">
                                                    <div>
                                                        <p class="text-sm text-gray-500">Prix total</p>
                                                        <p class="text-lg font-bold text-gray-800">${String.format("%.2f €", reservation.totalPrice)}</p>
                                                        <p class="text-xs text-gray-500">${reservation.nights} nuit(s)</p>
                                                    </div>
                                                    <div class="space-x-2">
                                                        <a href="ReservationDetails.jsp?id=${reservation.id}" class="inline-block bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium transition duration-200">
                                                            Détails
                                                        </a>
                                                        <button onclick="cancelReservation('${reservation.id}')" class="inline-block bg-white hover:bg-gray-100 text-red-600 border border-red-600 px-4 py-2 rounded-md text-sm font-medium transition duration-200">
                                                            Annuler
                                                        </button>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                <% } %>
                            </div>
                        <% } %>
                    </div>
                    
                    <!-- Past Reservations Tab -->
                    <div id="past-tab" class="tab-content p-6">
                        <% if (pastReservations.isEmpty()) { %>
                            <div class="text-center py-8">
                                <i class="fas fa-history text-gray-300 text-5xl mb-4"></i>
                                <h3 class="text-lg font-medium text-gray-700 mb-2">Aucune réservation passée</h3>
                                <p class="text-gray-500 mb-4">Vous n'avez pas encore effectué de séjour avec nous.</p>
                                <a href="../index.jsp" class="inline-block bg-blue-600 hover:bg-blue-700 text-white font-medium px-6 py-3 rounded-lg transition duration-200">
                                    Réserver un hôtel
                                </a>
                            </div>
                        <% } else { %>
                            <div class="space-y-6">
                                <% for (Map<String, Object> reservation : pastReservations) { %>
                                    <div class="reservation-card bg-white border rounded-lg overflow-hidden">
                                        <div class="md:flex">
                                            <div class="md:w-1/3 h-48 md:h-auto">
                                                <img src="${not empty reservation.hotelImage ? reservation.hotelImage : 'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80'}" 
                                                     alt="${reservation.hotelName}" 
                                                     class="w-full h-full object-cover">
                                            </div>
                                            <div class="p-6 md:w-2/3">
                                                <div class="flex justify-between items-start mb-2">
                                                    <h3 class="text-lg font-bold text-gray-800">${reservation.hotelName}</h3>
                                                    <span class="status-badge status-confirmed">Terminée</span>
                                                </div>
                                                <p class="text-gray-600 mb-4">
                                                    <i class="fas fa-map-marker-alt text-red-500 mr-1"></i> ${reservation.hotelLocation}
                                                </p>
                                                
                                                <div class="grid grid-cols-2 gap-4 mb-4">
                                                    <div>
                                                        <p class="text-sm text-gray-500">Check-in</p>
                                                        <p class="font-medium">${reservation.checkInFormatted}</p>
                                                    </div>
                                                    <div>
                                                        <p class="text-sm text-gray-500">Check-out</p>
                                                        <p class="font-medium">${reservation.checkOutFormatted}</p>
                                                    </div>
                                                    <div>
                                                        <p class="text-sm text-gray-500">Chambre</p>
                                                        <p class="font-medium">${reservation.roomType}</p>
                                                    </div>
                                                    <div>
                                                        <p class="text-sm text-gray-500">Voyageurs</p>
                                                        <p class="font-medium">${reservation.guests} personne(s)</p>
                                                    </div>
                                                </div>
                                                
                                                <div class="flex justify-between items-center pt-4 border-t">
                                                    <div>
                                                        <p class="text-sm text-gray-500">Prix total</p>
                                                        <p class="text-lg font-bold text-gray-800">${String.format("%.2f €", reservation.totalPrice)}</p>
                                                        <p class="text-xs text-gray-500">${reservation.nights} nuit(s)</p>
                                                    </div>
                                                    <div class="space-x-2">
                                                        <a href="ReservationDetails.jsp?id=${reservation.id}" class="inline-block bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium transition duration-200">
                                                            Détails
                                                        </a>
                                                        <a href="#" onclick="rateStay('${reservation.id}', '${reservation.hotelId}')" class="inline-block bg-white hover:bg-gray-100 text-yellow-600 border border-yellow-600 px-4 py-2 rounded-md text-sm font-medium transition duration-200">
                                                            <i class="fas fa-star mr-1"></i> Évaluer
                                                        </a>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                <% } %>
                            </div>
                        <% } %>
                    </div>
                    
                    <!-- Cancelled Reservations Tab -->
                    <div id="cancelled-tab" class="tab-content p-6">
                        <% if (cancelledReservations.isEmpty()) { %>
                            <div class="text-center py-8">
                                <i class="fas fa-ban text-gray-300 text-5xl mb-4"></i>
                                <h3 class="text-lg font-medium text-gray-700 mb-2">Aucune réservation annulée</h3>
                                <p class="text-gray-500">Vous n'avez pas de réservations annulées.</p>
                            </div>
                        <% } else { %>
                            <div class="space-y-6">
                                <% for (Map<String, Object> reservation : cancelledReservations) { %>
                                    <div class="reservation-card bg-white border rounded-lg overflow-hidden opacity-75">
                                        <div class="md:flex">
                                            <div class="md:w-1/3 h-48 md:h-auto">
                                                <img src="${not empty reservation.hotelImage ? reservation.hotelImage : 'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80'}" 
                                                     alt="${reservation.hotelName}" 
                                                     class="w-full h-full object-cover">
                                            </div>
                                            <div class="p-6 md:w-2/3">
                                                <div class="flex justify-between items-start mb-2">
                                                    <h3 class="text-lg font-bold text-gray-800">${reservation.hotelName}</h3>
                                                    <span class="status-badge status-cancelled">Annulée</span>
                                                </div>
                                                <p class="text-gray-600 mb-4">
                                                    <i class="fas fa-map-marker-alt text-red-500 mr-1"></i> ${reservation.hotelLocation}
                                                </p>
                                                
                                                <div class="grid grid-cols-2 gap-4 mb-4">
                                                    <div>
                                                        <p class="text-sm text-gray-500">Check-in</p>
                                                        <p class="font-medium">${reservation.checkInFormatted}</p>
                                                    </div>
                                                    <div>
                                                        <p class="text-sm text-gray-500">Check-out</p>
                                                        <p class="font-medium">${reservation.checkOutFormatted}</p>
                                                    </div>
                                                    <div>
                                                        <p class="text-sm text-gray-500">Chambre</p>
                                                        <p class="font-medium">${reservation.roomType}</p>
                                                    </div>
                                                    <div>
                                                        <p class="text-sm text-gray-500">Voyageurs</p>
                                                        <p class="font-medium">${reservation.guests} personnes</p>
                                                    </div>
                                                </div>
                                                
                                                <div class="flex flex-col md:flex-row justify-between items-start md:items-center">
                                                    <div>
                                                        <p class="text-sm text-gray-500">Date de réservation</p>
                                                        <p class="font-medium">${reservation.bookingDateFormatted}</p>
                                                    </div>
                                                    <div class="mt-2 md:mt-0">
                                                        <p class="text-sm text-gray-500">Prix total</p>
                                                        <p class="font-semibold text-lg text-gray-600">${reservation.totalPrice} €</p>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                <% } %>
                            </div>
                        <% } %>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- JavaScript -->
    <script>
        // Tab Switching
        const upcomingTabBtn = document.getElementById('upcoming-tab-btn');
        const pastTabBtn = document.getElementById('past-tab-btn');
        const cancelledTabBtn = document.getElementById('cancelled-tab-btn');
        
        const upcomingTab = document.getElementById('upcoming-tab');
        const pastTab = document.getElementById('past-tab');
        const cancelledTab = document.getElementById('cancelled-tab');
        
        upcomingTabBtn.addEventListener('click', () => {
            // Update tab buttons
            upcomingTabBtn.classList.add('text-blue-600', 'border-b-2', 'border-blue-600');
            upcomingTabBtn.classList.remove('text-gray-500');
            
            pastTabBtn.classList.remove('text-blue-600', 'border-b-2', 'border-blue-600');
            pastTabBtn.classList.add('text-gray-500');
            
            cancelledTabBtn.classList.remove('text-blue-600', 'border-b-2', 'border-blue-600');
            cancelledTabBtn.classList.add('text-gray-500');
            
            // Show/hide tabs
            upcomingTab.classList.add('active');
            pastTab.classList.remove('active');
            cancelledTab.classList.remove('active');
        });
        
        pastTabBtn.addEventListener('click', () => {
            // Update tab buttons
            pastTabBtn.classList.add('text-blue-600', 'border-b-2', 'border-blue-600');
            pastTabBtn.classList.remove('text-gray-500');
            
            upcomingTabBtn.classList.remove('text-blue-600', 'border-b-2', 'border-blue-600');
            upcomingTabBtn.classList.add('text-gray-500');
            
            cancelledTabBtn.classList.remove('text-blue-600', 'border-b-2', 'border-blue-600');
            cancelledTabBtn.classList.add('text-gray-500');
            
            // Show/hide tabs
            pastTab.classList.add('active');
            upcomingTab.classList.remove('active');
            cancelledTab.classList.remove('active');
        });
        
        cancelledTabBtn.addEventListener('click', () => {
            // Update tab buttons
            cancelledTabBtn.classList.add('text-blue-600', 'border-b-2', 'border-blue-600');
            cancelledTabBtn.classList.remove('text-gray-500');
            
            upcomingTabBtn.classList.remove('text-blue-600', 'border-b-2', 'border-blue-600');
            upcomingTabBtn.classList.add('text-gray-500');
            
            pastTabBtn.classList.remove('text-blue-600', 'border-b-2', 'border-blue-600');
            pastTabBtn.classList.add('text-gray-500');
            
            // Show/hide tabs
            cancelledTab.classList.add('active');
            upcomingTab.classList.remove('active');
            pastTab.classList.remove('active');
        });
    </script>
</body>
</html>