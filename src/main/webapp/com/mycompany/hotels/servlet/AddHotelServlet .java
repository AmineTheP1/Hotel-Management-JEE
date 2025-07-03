package com.mycompany.hotels.servlet; // Adjust package name as needed

import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;

// 1. ANNOTATE THE SERVLET
// This tells the server the URL to access this servlet
@WebServlet("/admin/addHotel")
// THIS IS THE CRITICAL ANNOTATION that fixes your error
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 1,  // 1 MB
    maxFileSize = 1024 * 1024 * 10, // 10 MB
    maxRequestSize = 1024 * 1024 * 15 // 15 MB
)
public class AddHotelServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // 2. MOVE THE FORM PROCESSING LOGIC HERE
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        
        // Database connection parameters
        String url = "jdbc:mysql://localhost:4200/hotel?useSSL=false&serverTimezone=UTC";
        String username = "root";
        String password = "Hamza_13579";

        Connection conn = null;
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(url, username, password);
            conn.setAutoCommit(false); // Start transaction

            request.setCharacterEncoding("UTF-8");
            String hotelName = request.getParameter("hotel_name");
            String description = request.getParameter("description");
            String addressLine1 = request.getParameter("address_line1");
            String addressLine2 = request.getParameter("address_line2");
            String city = request.getParameter("city");
            String state = request.getParameter("state");
            String country = request.getParameter("country");
            String postalCode = request.getParameter("postal_code");
            String status = request.getParameter("status");

            // Get the parameters from the form
            String latitudeParam = request.getParameter("latitude");
            String longitudeParam = request.getParameter("longitude");
            
            // Default to 0.0
            double latitude = 0.0;
            double longitude = 0.0;

            if (latitudeParam != null && !latitudeParam.trim().isEmpty()) {
                try {
                    latitude = Double.parseDouble(latitudeParam.trim());
                } catch (NumberFormatException e) {
                    throw new Exception("Invalid Latitude format. Please enter a valid number.");
                }
            }

            if (longitudeParam != null && !longitudeParam.trim().isEmpty()) {
                try {
                    longitude = Double.parseDouble(longitudeParam.trim());
                } catch (NumberFormatException e) {
                    throw new Exception("Invalid Longitude format. Please enter a valid number.");
                }
            }
            
            // --- Process file uploads ---
            // The getParts() call will now work correctly!
            String uploadPath = getServletContext().getRealPath("") + File.separator + "uploads" + File.separator + "hotels";
            File uploadDir = new File(uploadPath);
            if (!uploadDir.exists()) uploadDir.mkdirs();

            List<String> relativeImagePaths = new ArrayList<>();
            for (Part part : request.getParts()) {
                if ("hotel_images".equals(part.getName()) && part.getSize() > 0) {
                    String fileName = getSubmittedFileName(part);
                    if (fileName != null && !fileName.isEmpty()) {
                        String uniqueFileName = System.currentTimeMillis() + "_" + fileName.replaceAll("[^a-zA-Z0-9._-]", "");
                        part.write(uploadPath + File.separator + uniqueFileName);
                        relativeImagePaths.add("uploads/hotels/" + uniqueFileName);
                    }
                }
            }
            
            // Get manager ID
            long managerId = 1; // Fallback
            try (PreparedStatement managerStmt = conn.prepareStatement("SELECT user_id FROM users u JOIN roles r ON u.role_id = r.role_id WHERE r.name = 'manager' LIMIT 1");
                 ResultSet managerRs = managerStmt.executeQuery()) {
                if (managerRs.next()) {
                    managerId = managerRs.getLong("user_id");
                } else {
                    throw new Exception("No manager found in the database. Cannot create hotel.");
                }
            }

            // Insert hotel details
            String insertHotelSQL = "INSERT INTO hotels (manager_id, name, description, address_line1, address_line2, city, state, country, postal_code, latitude, longitude, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            try(PreparedStatement pstmt = conn.prepareStatement(insertHotelSQL, Statement.RETURN_GENERATED_KEYS)) {
                pstmt.setLong(1, managerId);
                pstmt.setString(2, hotelName);
                pstmt.setString(3, description);
                pstmt.setString(4, addressLine1);
                pstmt.setString(5, addressLine2);
                pstmt.setString(6, city);
                pstmt.setString(7, state);
                pstmt.setString(8, country);
                pstmt.setString(9, postalCode);
                pstmt.setDouble(10, latitude);
                pstmt.setDouble(11, longitude);
                pstmt.setString(12, status);
                
                int rowsAffected = pstmt.executeUpdate();
                if (rowsAffected == 0) {
                    throw new SQLException("Creating hotel failed, no rows were affected.");
                }

                long hotelId = 0;
                try (ResultSet generatedKeys = pstmt.getGeneratedKeys()) {
                    if (generatedKeys.next()) {
                        hotelId = generatedKeys.getLong(1);
                    } else {
                        throw new SQLException("Creating hotel failed, no ID was obtained.");
                    }
                }
                
                if (!relativeImagePaths.isEmpty()) {
                    String insertImageSQL = "INSERT INTO hotel_images (hotel_id, image_path, is_primary) VALUES (?, ?, ?)";
                    try (PreparedStatement imageStmt = conn.prepareStatement(insertImageSQL)) {
                        for (int i = 0; i < relativeImagePaths.size(); i++) {
                            imageStmt.setLong(1, hotelId);
                            imageStmt.setString(2, relativeImagePaths.get(i));
                            imageStmt.setInt(3, i == 0 ? 1 : 0);
                            imageStmt.addBatch();
                        }
                        imageStmt.executeBatch();
                    }
                }
            }
            
            conn.commit();
            // Redirect back to the JSP with a success message
            response.sendRedirect(request.getContextPath() + "/admin/add-hotel.jsp?success=Hotel+added+successfully!");

        } catch (Exception e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
            }
            e.printStackTrace();
            // Redirect back to the JSP with an error message
            String errorMessage = java.net.URLEncoder.encode(e.getMessage(), "UTF-8");
            response.sendRedirect(request.getContextPath() + "/admin/add-hotel.jsp?error=" + errorMessage);
        } finally {
            if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
    }

    // 3. MOVE THE HELPER METHOD HERE
    private String getSubmittedFileName(Part part) {
        if (part == null) return null;
        for (String contentDisp : part.getHeader("content-disposition").split(";")) {
            if (contentDisp.trim().startsWith("filename")) {
                return contentDisp.substring(contentDisp.indexOf("=") + 2, contentDisp.length() - 1);
            }
        }
        return null;
    }
}