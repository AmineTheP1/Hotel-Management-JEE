<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    // Get booking ID from request
    String bookingId = request.getParameter("bookingId");
    
    // Database connection parameters
    String jdbcURL = "jdbc:mysql://localhost:3306/hotels_db";
    String dbUser = "root";
    String dbPassword = "";
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // Booking data
    Map<String, Object> booking = new HashMap<>();
    
    try {
        // Establish database connection
        Class.forName("com.mysql.jdbc.Driver");
        conn = DriverManager.getConnection(jdbcURL, dbUser, dbPassword);
        
        // Fetch booking details
        String bookingQuery = "SELECT b.*, h.name as hotel_name, h.address_line1, h.city, h.country, " +
                             "r.room_number, rt.name as room_type, rt.base_price, " +
                             "u.first_name, u.last_name, u.email, u.phone " +
                             "FROM bookings b " +
                             "JOIN hotels h ON b.hotel_id = h.hotel_id " +
                             "JOIN rooms r ON b.room_id = r.room_id " +
                             "JOIN room_types rt ON r.room_type_id = rt.room_type_id " +
                             "JOIN users u ON b.client_id = u.user_id " +
                             "WHERE b.booking_id = ?";
        
        pstmt = conn.prepareStatement(bookingQuery);
        pstmt.setString(1, bookingId);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            booking.put("id", rs.getString("booking_id"));
            booking.put("checkIn", rs.getDate("check_in_date"));
            booking.put("checkOut", rs.getDate("check_out_date"));
            booking.put("guests", rs.getInt("guests"));
            booking.put("status", rs.getString("status"));
            booking.put("createdAt", rs.getTimestamp("created_at"));
            
            booking.put("hotelName", rs.getString("hotel_name"));
            booking.put("hotelAddress", rs.getString("address_line1"));
            booking.put("hotelCity", rs.getString("city"));
            booking.put("hotelCountry", rs.getString("country"));
            
            booking.put("roomNumber", rs.getString("room_number"));
            booking.put("roomType", rs.getString("room_type"));
            booking.put("roomPrice", rs.getDouble("base_price"));
            
            booking.put("guestName", rs.getString("first_name") + " " + rs.getString("last_name"));
            booking.put("guestEmail", rs.getString("email"));
            booking.put("guestPhone", rs.getString("phone"));
            
            // Format dates
            SimpleDateFormat dateFormat = new SimpleDateFormat("EEEE, MMMM d, yyyy");
            booking.put("checkInFormatted", dateFormat.format(booking.get("checkIn")));
            booking.put("checkOutFormatted", dateFormat.format(booking.get("checkOut")));
            
            // Calculate number of nights
            long diffInMillies = ((Date) booking.get("checkOut")).getTime() - ((Date) booking.get("checkIn")).getTime();
            int nights = (int) (diffInMillies / (1000 * 60 * 60 * 24));
            booking.put("nights", nights);
            
            // Calculate total price
            double totalPrice = nights * ((Double) booking.get("roomPrice"));
            booking.put("totalPrice", totalPrice);
            
            // Get payment information
            String paymentQuery = "SELECT p.*, pm.name as payment_method_name " +
                                 "FROM payments p " +
                                 "JOIN payment_methods pm ON p.method_id = pm.method_id " +
                                 "WHERE p.booking_id = ? " +
                                 "ORDER BY p.paid_at DESC";
            
            pstmt = conn.prepareStatement(paymentQuery);
            pstmt.setString(1, bookingId);
            rs = pstmt.executeQuery();
            
            List<Map<String, Object>> payments = new ArrayList<>();
            double totalPaid = 0.0;
            
            while (rs.next()) {
                Map<String, Object> payment = new HashMap<>();
                payment.put("id", rs.getString("payment_id"));
                payment.put("amount", rs.getDouble("amount"));
                payment.put("currency", rs.getString("currency"));
                payment.put("method", rs.getString("payment_method_name"));
                payment.put("paidAt", rs.getTimestamp("paid_at"));
                payment.put("isPartial", rs.getBoolean("is_partial"));
                
                payments.add(payment);
                totalPaid += rs.getDouble("amount");
            }
            
            booking.put("payments", payments);
            booking.put("totalPaid", totalPaid);
            booking.put("remainingBalance", totalPrice - totalPaid);
            
            // Store booking in request attribute
            request.setAttribute("booking", booking);
        } else {
            // Booking not found
            request.setAttribute("error", "Booking not found");
        }
    } catch (Exception e) {
        request.setAttribute("error", "Error retrieving booking details: " + e.getMessage());
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
    <title>Booking Confirmation - ZAIRTAM Hotels</title>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
</head>
<body class="bg-gray-100 min-h-screen">
    <!-- Include Header -->
    <jsp:include page="includes/header.jsp" />
    
    <div class="max-w-4xl mx-auto px-4 py-8">
        <c:if test="${not empty error}">
            <div class="bg-red-100 border-l-4 border-red-500 text-red-700 p-4 mb-6" role="alert">
                <p>${error}</p>
                <p class="mt-2">
                    <a href="index.jsp" class="text-red-700 underline">Return to homepage</a>
                </p>
            </div>
        </c:if>
        
        <c:if test="${not empty booking}">
            <!-- Confirmation Header -->
            <div class="text-center mb-8">
                <div class="inline-block p-4 rounded-full bg-green-100 text-green-500 mb-4">
                    <i class="fas fa-check-circle text-4xl"></i>
                </div>
                <h1 class="text-3xl font-bold text-gray-800">Booking Confirmed!</h1>
                <p class="text-gray-600 mt-2">Your reservation has been successfully processed.</p>
                <p class="text-gray-500 text-sm mt-1">Booking ID: #${booking.id}</p>
            </div>
            
            <!-- Booking Summary -->
            <div class="bg-white rounded-lg shadow-md overflow-hidden mb-6">
                <div class="bg-blue-600 text-white px-6 py-4">
                    <h2 class="text-xl font-semibold">Booking Summary</h2>
                </div>
                
                <div class="p-6">
                    <!-- Hotel Info -->
                    <div class="flex flex-col md:flex-row mb-6 pb-6 border-b border-gray-200">
                        <div class="md:w-1/3 font-medium text-gray-600 mb-2 md:mb-0">Hotel</div>
                        <div class="md:w-2/3">
                            <h3 class="text-lg font-bold text-gray-800">${booking.hotelName}</h3>
                            <p class="text-gray-600">${booking.hotelAddress}</p>
                            <p class="text-gray-600">${booking.hotelCity}, ${booking.hotelCountry}</p>
                        </div>
                    </div>
                    
                    <!-- Room Info -->
                    <div class="flex flex-col md:flex-row mb-6 pb-6 border-b border-gray-200">
                        <div class="md:w-1/3 font-medium text-gray-600 mb-2 md:mb-0">Room</div>
                        <div class="md:w-2/3">
                            <h3 class="text-lg font-bold text-gray-800">${booking.roomType}</h3>
                            <p class="text-gray-600">Room #${booking.roomNumber}</p>
                            <p class="text-gray-600">${booking.guests} Guest(s)</p>
                        </div>
                    </div>
                    
                    <!-- Dates -->
                    <div class="flex flex-col md:flex-row mb-6 pb-6 border-b border-gray-200">
                        <div class="md:w-1/3 font-medium text-gray-600 mb-2 md:mb-0">Dates</div>
                        <div class="md:w-2/3">
                            <div class="flex items-center mb-2">
                                <div class="bg-blue-100 text-blue-800 p-2 rounded-full mr-3">
                                    <i class="fas fa-arrow-right"></i>
                                </div>
                                <div>
                                    <p class="font-medium">Check-in</p>
                                    <p class="text-gray-600">${booking.checkInFormatted}</p>
                                </div>
                            </div>
                            <div class="flex items-center">
                                <div class="bg-blue-100 text-blue-800 p-2 rounded-full mr-3">
                                    <i class="fas fa-arrow-left"></i>
                                </div>
                                <div>
                                    <p class="font-medium">Check-out</p>
                                    <p class="text-gray-600">${booking.checkOutFormatted}</p>
                                </div>
                            </div>
                            <p class="mt-2 text-gray-600">${booking.nights} night(s)</p>
                        </div>
                    </div>
                    
                    <!-- Guest Info -->
                    <div class="flex flex-col md:flex-row mb-6 pb-6 border-b border-gray-200">
                        <div class="md:w-1/3 font-medium text-gray-600 mb-2 md:mb-0">Guest</div>
                        <div class="md:w-2/3">
                            <p class="font-medium">${booking.guestName}</p>
                            <p class="text-gray-600">${booking.guestEmail}</p>
                            <p class="text-gray-600">${booking.guestPhone}</p>
                        </div>
                    </div>
                    
                    <!-- Payment Info -->
                    <div class="flex flex-col md:flex-row">
                        <div class="md:w-1/3 font-medium text-gray-600 mb-2 md:mb-0">Payment</div>
                        <div class="md:w-2/3">
                            <div class="flex justify-between mb-2">
                                <span>Room Rate (${booking.nights} nights)</span>
                                <span>$${booking.roomPrice} × ${booking.nights}</span>
                            </div>
                            <div class="flex justify-between font-bold text-lg border-t border-gray-200 pt-2 mb-4">
                                <span>Total</span>
                                <span>$${booking.totalPrice}</span>
                            </div>
                            
                            <c:if test="${not empty booking.payments}">
                                <h4 class="font-medium mb-2">Payment History</h4>
                                <c:forEach var="payment" items="${booking.payments}">
                                    <div class="flex justify-between text-sm mb-1">
                                        <span>${payment.method} - <fmt:formatDate value="${payment.paidAt}" pattern="MMM d, yyyy"/></span>
                                        <span class="text-green-600">$${payment.amount}</span>
                                    </div>
                                </c:forEach>
                                
                                <div class="flex justify-between font-medium mt-2 pt-2 border-t border-gray-200">
                                    <span>Remaining Balance</span>
                                    <span class="${booking.remainingBalance <= 0 ? 'text-green-600' : 'text-red-600'}">
                                        $${booking.remainingBalance}
                                    </span>
                                </div>
                            </c:if>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Actions -->
            <div class="flex flex-col md:flex-row gap-4 mt-8">
                <a href="index.jsp" class="bg-white hover:bg-gray-100 text-gray-800 font-semibold py-3 px-6 border border-gray-300 rounded-lg shadow-sm text-center">
                    <i class="fas fa-home mr-2"></i> Return to Homepage
                </a>
                <a href="my-bookings.jsp" class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-6 rounded-lg shadow-sm text-center">
                    <i class="fas fa-list-alt mr-2"></i> View My Bookings
                </a>
                <button onclick="window.print()" class="bg-gray-800 hover:bg-gray-900 text-white font-semibold py-3 px-6 rounded-lg shadow-sm text-center">
                    <i class="fas fa-print mr-2"></i> Print Confirmation
                </button>
            </div>
        </c:if>
    </div>
    
    <!-- Include Footer -->
    <jsp:include page="includes/footer.jsp" />
    
    <script>
        // Add any JavaScript functionality here
    </script>
</body>
</html>