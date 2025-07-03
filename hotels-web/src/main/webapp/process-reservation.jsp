<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.temporal.ChronoUnit" %>

<%
    // Check if the form was submitted
    if (request.getMethod().equalsIgnoreCase("POST")) {
        // Get form data
        String hotelId = request.getParameter("hotelId");
        String roomTypeId = request.getParameter("roomTypeId");
        String checkIn = request.getParameter("checkIn");
        String checkOut = request.getParameter("checkOut");
        String guests = request.getParameter("guests");
        String fullName = request.getParameter("fullName");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        
        // Calculate number of nights
        int numberOfNights = 1;
        try {
            LocalDate checkInDate = LocalDate.parse(checkIn);
            LocalDate checkOutDate = LocalDate.parse(checkOut);
            numberOfNights = (int) ChronoUnit.DAYS.between(checkInDate, checkOutDate);
        } catch (Exception e) {
            numberOfNights = 1;
        }
        
        // Database connection parameters
        String jdbcURL = "jdbc:mysql://localhost:3306/hotels_db";
        String dbUser = "root";
        String dbPassword = "";
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            // Establish database connection
            Class.forName("com.mysql.jdbc.Driver");
            conn = DriverManager.getConnection(jdbcURL, dbUser, dbPassword);
            
            // Get room price from database
            String priceQuery = "SELECT base_price FROM room_types WHERE room_type_id = ?";
            pstmt = conn.prepareStatement(priceQuery);
            pstmt.setString(1, roomTypeId);
            rs = pstmt.executeQuery();
            
            double roomPrice = 0.0;
            if (rs.next()) {
                roomPrice = rs.getDouble("base_price");
            }
            
            // Calculate total price
            double basePrice = roomPrice * numberOfNights;
            double taxesAndFees = basePrice * 0.12; // 12% taxes and fees
            double totalPrice = basePrice + taxesAndFees;
            
            // Close previous resources
            rs.close();
            pstmt.close();
            
            // Find an available room of the selected type
            String roomQuery = "SELECT room_id FROM rooms WHERE room_type_id = ? AND status = 'available' LIMIT 1";
            pstmt = conn.prepareStatement(roomQuery);
            pstmt.setString(1, roomTypeId);
            rs = pstmt.executeQuery();
            
            String roomId = null;
            if (rs.next()) {
                roomId = rs.getString("room_id");
            } else {
                // No available rooms
                response.sendRedirect("reservation.jsp?hotelId=" + hotelId + "&error=no_rooms");
                return;
            }
            
            // Close previous resources
            rs.close();
            pstmt.close();
            
            // Check if user exists or create a new user
            String userId = null;
            String userQuery = "SELECT user_id FROM users WHERE email = ?";
            pstmt = conn.prepareStatement(userQuery);
            pstmt.setString(1, email);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                // User exists
                userId = rs.getString("user_id");
            } else {
                // Create new user
                rs.close();
                pstmt.close();
                
                String createUserQuery = "INSERT INTO users (first_name, last_name, email, phone, role_id, created_at) " +
                                        "VALUES (?, ?, ?, ?, 1, NOW())";
                
                pstmt = conn.prepareStatement(createUserQuery, Statement.RETURN_GENERATED_KEYS);
                
                // Split full name into first and last name
                String[] nameParts = fullName.split(" ", 2);
                String firstName = nameParts[0];
                String lastName = nameParts.length > 1 ? nameParts[1] : "";
                
                pstmt.setString(1, firstName);
                pstmt.setString(2, lastName);
                pstmt.setString(3, email);
                pstmt.setString(4, phone);
                pstmt.executeUpdate();
                
                rs = pstmt.getGeneratedKeys();
                if (rs.next()) {
                    userId = rs.getString(1);
                }
            }
            
            // Close previous resources
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            
            // Create booking
            String bookingQuery = "INSERT INTO bookings (client_id, hotel_id, room_id, check_in_date, check_out_date, " +
                                 "guests, status, created_at) VALUES (?, ?, ?, ?, ?, ?, 'confirmed', NOW())";
            
            pstmt = conn.prepareStatement(bookingQuery, Statement.RETURN_GENERATED_KEYS);
            pstmt.setString(1, userId);
            pstmt.setString(2, hotelId);
            pstmt.setString(3, roomId);
            pstmt.setString(4, checkIn);
            pstmt.setString(5, checkOut);
            pstmt.setString(6, guests);
            pstmt.executeUpdate();
            
            rs = pstmt.getGeneratedKeys();
            String bookingId = null;
            if (rs.next()) {
                bookingId = rs.getString(1);
            }
            
            // Update room status
            pstmt.close();
            String updateRoomQuery = "UPDATE rooms SET status = 'occupied', last_status_at = NOW() WHERE room_id = ?";
            pstmt = conn.prepareStatement(updateRoomQuery);
            pstmt.setString(1, roomId);
            pstmt.executeUpdate();
            
            // Redirect to confirmation page
            response.sendRedirect("booking-confirmation.jsp?bookingId=" + bookingId);
            
        } catch (Exception e) {
            e.printStackTrace();
            // Redirect back to reservation page with error
            response.sendRedirect("reservation.jsp?hotelId=" + hotelId + "&error=system");
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
    } else {
        // If not a POST request, redirect to home
        response.sendRedirect("index.jsp");
    }
%>