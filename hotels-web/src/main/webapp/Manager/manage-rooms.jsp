<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="javax.servlet.http.*" %>
<%@ page import="javax.servlet.ServletException" %>
<%@ page import="java.nio.file.*" %>
<%@ page import="org.apache.commons.fileupload.*" %>
<%@ page import="org.apache.commons.fileupload.disk.*" %>
<%@ page import="org.apache.commons.fileupload.servlet.*" %>

<%
    // Database connection parameters
    String url = "jdbc:mysql://localhost:4200/hotel?useSSL=false";
    String username = "root";
    String password = "Hamza_13579";
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    
    String successMessage = "";
    String errorMessage = "";
    
    try {
        // Process form submission
        if (request.getMethod().equals("POST")) {
            // Check if the request is multipart
            boolean isMultipart = ServletFileUpload.isMultipartContent(request);
            
            if (isMultipart) {
                // Create a factory for disk-based file items
                DiskFileItemFactory factory = new DiskFileItemFactory();
                
                // Create a new file upload handler
                ServletFileUpload upload = new ServletFileUpload(factory);
                
                // Parse the request
                List<FileItem> items = upload.parseRequest(request);
                
                // Process the uploaded items
                String action = "";
                String hotelId = "";
                String roomName = "";
                String description = "";
                int maxGuests = 0;
                double basePrice = 0.0;
                boolean hasWifi = false;
                boolean hasAc = false;
                boolean hasTv = false;
                boolean hasBreakfast = false;
                String imagePath = "";
                
                for (FileItem item : items) {
                    if (item.isFormField()) {
                        // Process regular form fields
                        String fieldName = item.getFieldName();
                        String fieldValue = item.getString("UTF-8");
                        
                        switch (fieldName) {
                            case "action":
                                action = fieldValue;
                                break;
                            case "hotel_id":
                                hotelId = fieldValue;
                                break;
                            case "room_name":
                                roomName = fieldValue;
                                break;
                            case "description":
                                description = fieldValue;
                                break;
                            case "max_guests":
                                maxGuests = Integer.parseInt(fieldValue);
                                break;
                            case "base_price":
                                basePrice = Double.parseDouble(fieldValue);
                                break;
                            case "has_wifi":
                                hasWifi = true;
                                break;
                            case "has_ac":
                                hasAc = true;
                                break;
                            case "has_tv":
                                hasTv = true;
                                break;
                            case "has_breakfast":
                                hasBreakfast = true;
                                break;
                        }
                    } else {
                        // Process file upload
                        if (item.getSize() > 0) {
                            // Define the upload directory path
                            String uploadDir = request.getServletContext().getRealPath("/uploads/rooms");
                            File uploadDirFile = new File(uploadDir);
                            if (!uploadDirFile.exists()) {
                                uploadDirFile.mkdirs();
                            }
                            
                            // Generate a unique filename
                            String fileName = System.currentTimeMillis() + "_" + item.getName();
                            String filePath = uploadDir + File.separator + fileName;
                            
                            // Save the file
                            File uploadedFile = new File(filePath);
                            item.write(uploadedFile);
                            
                            // Store the relative path for database
                            imagePath = "uploads/rooms/" + fileName;
                        }
                    }
                }
                
                // Establish database connection
                Class.forName("com.mysql.cj.jdbc.Driver");
                conn = DriverManager.getConnection(url, username, password);
                
                if ("add_room_type".equals(action)) {
                    // Insert new room type
                    String insertQuery = "INSERT INTO room_types (hotel_id, name, description, max_guests, base_price, image_url) VALUES (?, ?, ?, ?, ?, ?)";
                    pstmt = conn.prepareStatement(insertQuery, Statement.RETURN_GENERATED_KEYS);
                    pstmt.setString(1, hotelId);
                    pstmt.setString(2, roomName);
                    pstmt.setString(3, description);
                    pstmt.setInt(4, maxGuests);
                    pstmt.setDouble(5, basePrice);
                    pstmt.setString(6, imagePath);
                    
                    int affectedRows = pstmt.executeUpdate();
                    
                    if (affectedRows > 0) {
                        // Get the generated room_type_id
                        ResultSet generatedKeys = pstmt.getGeneratedKeys();
                        int roomTypeId = 0;
                        if (generatedKeys.next()) {
                            roomTypeId = generatedKeys.getInt(1);
                        }
                        
                        // Insert amenities
                        if (roomTypeId > 0) {
                            String amenitiesQuery = "INSERT INTO room_amenities (room_type_id, amenity_name, is_available) VALUES (?, ?, ?)";
                            pstmt = conn.prepareStatement(amenitiesQuery);
                            
                            if (hasWifi) {
                                pstmt.setInt(1, roomTypeId);
                                pstmt.setString(2, "WiFi");
                                pstmt.setBoolean(3, true);
                                pstmt.addBatch();
                            }
                            
                            if (hasAc) {
                                pstmt.setInt(1, roomTypeId);
                                pstmt.setString(2, "Air Conditioning");
                                pstmt.setBoolean(3, true);
                                pstmt.addBatch();
                            }
                            
                            if (hasTv) {
                                pstmt.setInt(1, roomTypeId);
                                pstmt.setString(2, "TV");
                                pstmt.setBoolean(3, true);
                                pstmt.addBatch();
                            }
                            
                            if (hasBreakfast) {
                                pstmt.setInt(1, roomTypeId);
                                pstmt.setString(2, "Breakfast");
                                pstmt.setBoolean(3, true);
                                pstmt.addBatch();
                            }
                            
                            pstmt.executeBatch();
                        }
                        
                        successMessage = "Room type added successfully!";
                    } else {
                        errorMessage = "Failed to add room type.";
                    }
                }
            }
        }
    } catch (Exception e) {
        errorMessage = "Error: " + e.getMessage();
        e.printStackTrace();
    } finally {
        // Close database resources
        try {
            if (pstmt != null) pstmt.close();
            if (conn != null) conn.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    
    // Redirect back to hotels page with message
    if (!successMessage.isEmpty()) {
        session.setAttribute("successMessage", successMessage);
    }
    if (!errorMessage.isEmpty()) {
        session.setAttribute("errorMessage", errorMessage);
    }
    response.sendRedirect("hotels.jsp");
%>