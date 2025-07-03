<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.io.*" %>
<%@ page import="javax.servlet.http.Part" %>

<%!
    // Helper method to extract filename from Part
    private String getSubmittedFileName(Part part) {
        if (part == null) return null;
        String contentDisp = part.getHeader("content-disposition");
        if (contentDisp == null) return null;
        for (String s : contentDisp.split(";")) {
            if (s.trim().startsWith("filename")) {
                return s.substring(s.indexOf("=") + 2, s.length() - 1);
            }
        }
        return null;
    }
%>

<%
    // Database connection parameters
    String url = "jdbc:mysql://localhost:4200/hotel?useSSL=false&serverTimezone=UTC";
    String username = "root";
    String password = "Hamza_13579";
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    
    // Admin information (fetch once, reuse)
    String adminName = (String) session.getAttribute("adminName");
    if (adminName == null) adminName = "Admin User"; // Default
    String adminImage = ""; // Placeholder
    
    // Message holders
    String successMessage = request.getParameter("success");
    String errorMessage = request.getParameter("error");

    // --- FORM PROCESSING LOGIC ---
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        // Clear previous messages before processing new request
        successMessage = null;
        errorMessage = null;
        
        // Use a single connection for the entire transaction
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(url, username, password);
            conn.setAutoCommit(false); // Start transaction

            // --- 1. GET AND VALIDATE FORM DATA ---
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

            // --- CORRECTION: Robustly parse latitude and longitude to prevent the error ---
            String latitudeParam = request.getParameter("latitude");
            String longitudeParam = request.getParameter("longitude");
            
            Double latitude = null;
            Double longitude = null;

            if (latitudeParam != null && !latitudeParam.trim().isEmpty()) {
                try {
                    latitude = Double.parseDouble(latitudeParam.trim());
                } catch (NumberFormatException e) {
                    throw new Exception("Latitude invalide. Veuillez entrer un nombre décimal.");
                }
            }

            if (longitudeParam != null && !longitudeParam.trim().isEmpty()) {
                try {
                    longitude = Double.parseDouble(longitudeParam.trim());
                } catch (NumberFormatException e) {
                    throw new Exception("Longitude invalide. Veuillez entrer un nombre décimal.");
                }
            }

            // --- END CORRECTION ---

            // --- 2. PROCESS FILE UPLOADS ---
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
            
            // --- 3. PERFORM DATABASE OPERATIONS ---
            
            // Get a manager ID (in a real app, this should come from the logged-in user)
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
            pstmt = conn.prepareStatement(insertHotelSQL, Statement.RETURN_GENERATED_KEYS);
            
            pstmt.setLong(1, managerId);
            pstmt.setString(2, hotelName);
            pstmt.setString(3, description);
            pstmt.setString(4, addressLine1);
            pstmt.setString(5, addressLine2);
            pstmt.setString(6, city);
            pstmt.setString(7, state);
            pstmt.setString(8, country);
            pstmt.setString(9, postalCode);
            
            // --- CORRECTION: Correctly set Double or NULL for the PreparedStatement ---
            if (latitude != null) {
                pstmt.setDouble(10, latitude);
            } else {
                pstmt.setNull(10, java.sql.Types.DECIMAL);
            }
            
            if (longitude != null) {
                pstmt.setDouble(11, longitude);
            } else {
                pstmt.setNull(11, java.sql.Types.DECIMAL);
            }
            // --- END CORRECTION ---

            pstmt.setString(12, status);
            
            int rowsAffected = pstmt.executeUpdate();
            if (rowsAffected == 0) {
                throw new SQLException("Creating hotel failed, no rows affected.");
            }

            // Get the generated hotel ID
            long hotelId = 0;
            try (ResultSet generatedKeys = pstmt.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    hotelId = generatedKeys.getLong(1);
                } else {
                    throw new SQLException("Creating hotel failed, no ID obtained.");
                }
            }
            
            // Insert image paths into the new `hotel_images` table
            if (!relativeImagePaths.isEmpty()) {
                String insertImageSQL = "INSERT INTO hotel_images (hotel_id, image_path, is_primary) VALUES (?, ?, ?)";
                try (PreparedStatement imageStmt = conn.prepareStatement(insertImageSQL)) {
                    for (int i = 0; i < relativeImagePaths.size(); i++) {
                        imageStmt.setLong(1, hotelId);
                        imageStmt.setString(2, relativeImagePaths.get(i));
                        imageStmt.setInt(3, i == 0 ? 1 : 0); // First image is primary
                        imageStmt.addBatch();
                    }
                    imageStmt.executeBatch();
                }
            }

            conn.commit(); // If everything succeeded, commit the transaction
            response.sendRedirect("add-hotel.jsp?success=Hotel+added+successfully!");
            return; // IMPORTANT: Stop page execution after redirect

        } catch (Exception e) {
            if (conn != null) {
                try {
                    conn.rollback(); // If any error occurs, rollback all changes
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            // To display the error on the same page, we redirect with a parameter
            response.sendRedirect("add-hotel.jsp?error=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
            e.printStackTrace();
            return;

        } finally {
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
            if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
    }

    // --- PAGE DISPLAY LOGIC (for GET requests) ---
    // Fetch admin name only on GET request if not in session
    if (adminName.equals("Admin User")) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(url, username, password);
            try (PreparedStatement userStmt = conn.prepareStatement("SELECT u.first_name, u.last_name FROM users u JOIN roles r ON u.role_id = r.role_id WHERE r.name = 'manager' LIMIT 1");
                 ResultSet userRs = userStmt.executeQuery()) {
                if (userRs.next()) {
                    adminName = userRs.getString("first_name") + " " + userRs.getString("last_name");
                    session.setAttribute("adminName", adminName);
                }
            }
        } catch (Exception e) {
            e.printStackTrace(); // Log error, but don't crash the page
        } finally {
            if (conn != null) try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZAIRTAM - Add New Hotel</title>
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
        
        .image-preview {
            width: 120px;
            height: 120px;
            object-fit: cover;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            transition: all 0.3s ease;
            border: 2px solid #e5e7eb;
        }
        
        .image-preview:hover {
            transform: scale(1.05);
            border-color: #3b82f6;
        }
        
        .preview-container {
            display: flex;
            flex-wrap: wrap;
            gap: 15px;
            margin-top: 15px;
        }
        
        .upload-container {
            border: 2px dashed #cbd5e0;
            border-radius: 8px;
            padding: 25px;
            text-align: center;
            background-color: #f8fafc;
            transition: all 0.3s ease;
            cursor: pointer;
            margin-bottom: 10px;
        }
        
        .upload-container:hover {
            border-color: #3b82f6;
            background-color: #eff6ff;
        }
        
        .upload-icon {
            font-size: 40px;
            color: #94a3b8;
            margin-bottom: 10px;
            transition: color 0.3s ease;
        }
        
        .upload-container:hover .upload-icon {
            color: #3b82f6;
        }
        
        .preview-item {
            position: relative;
        }
        
        .remove-image {
            position: absolute;
            top: -8px;
            right: -8px;
            background: #ef4444;
            color: white;
            border-radius: 50%;
            width: 24px;
            height: 24px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 12px;
            cursor: pointer;
            opacity: 0;
            transition: opacity 0.2s;
            box-shadow: 0 2px 4px rgba(0,0,0,0.2);
        }
        
        .preview-item:hover .remove-image {
            opacity: 1;
        }
        
        .primary-badge {
            position: absolute;
            bottom: -5px;
            left: 50%;
            transform: translateX(-50%);
            background: #3b82f6;
            color: white;
            border-radius: 4px;
            padding: 2px 8px;
            font-size: 10px;
            font-weight: 600;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
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
                            <a href="hotels.jsp" class="flex items-center px-3 py-2 text-blue-600 bg-blue-50 rounded-md">
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
                            <a href="bookings.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
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
                                <i class="fas fa-dollar-sign w-5 text-center"></i>
                                <span class="ml-2">Revenue</span>
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
        <div class="flex-1 p-6">
            <div class="max-w-4xl mx-auto">
                <div class="flex justify-between items-center mb-6">
                    <h1 class="text-2xl font-bold text-gray-800">Add New Hotel</h1>
                    <a href="hotels.jsp" class="px-4 py-2 bg-gray-200 text-gray-700 rounded-md hover:bg-gray-300 transition-colors">
                        <i class="fas fa-arrow-left mr-2"></i> Back to Hotels
                    </a>
                </div>
                
                <% if (!errorMessage.isEmpty()) { %>
                    <div class="bg-red-100 border-l-4 border-red-500 text-red-700 p-4 mb-6" role="alert">
                        <p><%= errorMessage %></p>
                    </div>
                <% } %>
                
                <% if (!successMessage.isEmpty()) { %>
                    <div class="bg-green-100 border-l-4 border-green-500 text-green-700 p-4 mb-6" role="alert">
                        <p><%= successMessage %></p>
                    </div>
                <% } %>
                
                <div class="bg-white shadow-md rounded-lg overflow-hidden">
                    <div class="p-6">
                        <form action="add-hotel.jsp" method="post" enctype="multipart/form-data" class="space-y-6">
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                                <div>
                                    <label for="hotel_name" class="block text-sm font-medium text-gray-700 mb-1">Hotel Name *</label>
                                    <input type="text" id="hotel_name" name="hotel_name" required class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                                </div>
                                
                                <div>
                                    <label for="status" class="block text-sm font-medium text-gray-700 mb-1">Status *</label>
                                    <select id="status" name="status" required class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                                        <option value="active">Active</option>
                                        <option value="inactive">Inactive</option>
                                        <option value="pending">Pending</option>
                                    </select>
                                </div>
                                
                                <div class="md:col-span-2">
                                    <label for="description" class="block text-sm font-medium text-gray-700 mb-1">Description *</label>
                                    <textarea id="description" name="description" rows="4" required class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"></textarea>
                                </div>
                                
                                <div>
                                    <label for="address_line1" class="block text-sm font-medium text-gray-700 mb-1">Address Line 1 *</label>
                                    <input type="text" id="address_line1" name="address_line1" required class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                                </div>
                                
                                <div>
                                    <label for="address_line2" class="block text-sm font-medium text-gray-700 mb-1">Address Line 2</label>
                                    <input type="text" id="address_line2" name="address_line2" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                                </div>
                                
                                <div>
                                    <label for="city" class="block text-sm font-medium text-gray-700 mb-1">City *</label>
                                    <input type="text" id="city" name="city" required class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                                </div>
                                
                                <div>
                                    <label for="state" class="block text-sm font-medium text-gray-700 mb-1">State/Province *</label>
                                    <input type="text" id="state" name="state" required class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                                </div>
                                
                                <div>
                                    <label for="country" class="block text-sm font-medium text-gray-700 mb-1">Country *</label>
                                    <input type="text" id="country" name="country" required class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                                </div>
                                
                                <div>
                                    <label for="postal_code" class="block text-sm font-medium text-gray-700 mb-1">Postal Code *</label>
                                    <input type="text" id="postal_code" name="postal_code" required class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                                </div>
                                
                                <div>
                                    <label for="latitude" class="block text-sm font-medium text-gray-700 mb-1">Latitude</label>
                                    <input type="text" id="latitude" name="latitude" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                                </div>
                                
                                <div>
                                    <label for="longitude" class="block text-sm font-medium text-gray-700 mb-1">Longitude</label>
                                    <input type="text" id="longitude" name="longitude" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                                </div>
                                
                                <div class="md:col-span-2">
                                    <label for="hotel_images" class="block text-sm font-medium text-gray-700 mb-1">Hotel Images *</label>
                                    <div id="upload-container" class="upload-container">
                                        <i class="fas fa-cloud-upload-alt upload-icon"></i>
                                        <p class="text-gray-600 mb-2">Drag and drop images here or click to browse</p>
                                        <p class="text-xs text-gray-500">Upload multiple images (PNG, JPG, JPEG)</p>
                                        <input type="file" id="hotel_images" name="hotel_images" multiple accept="image/*" required class="hidden">
                                    </div>
                                    <div id="image-preview" class="preview-container"></div>
                                    <p class="text-xs text-gray-500 mt-1">The first image will be set as the primary image for this hotel.</p>
                                </div>
                            </div>
                            
                            <div class="flex justify-end">
                                <button type="submit" class="px-6 py-3 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
                                    <i class="fas fa-plus mr-2"></i> Add Hotel
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Image upload functionality
        document.addEventListener('DOMContentLoaded', function() {
            const uploadContainer = document.getElementById('upload-container');
            const fileInput = document.getElementById('hotel_images');
            const previewContainer = document.getElementById('image-preview');
            
            // Click on upload container to trigger file input
            uploadContainer.addEventListener('click', () => {
                fileInput.click();
            });
            
            // Prevent default drag behaviors
            ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
                uploadContainer.addEventListener(eventName, preventDefaults, false);
            });
            
            function preventDefaults(e) {
                e.preventDefault();
                e.stopPropagation();
            }
            
            // Highlight drop area when item is dragged over it
            ['dragenter', 'dragover'].forEach(eventName => {
                uploadContainer.addEventListener(eventName, highlight, false);
            });
            
            ['dragleave', 'drop'].forEach(eventName => {
                uploadContainer.addEventListener(eventName, unhighlight, false);
            });
            
            function highlight() {
                uploadContainer.style.borderColor = '#3b82f6';
                uploadContainer.style.backgroundColor = '#eff6ff';
            }
            
            function unhighlight() {
                uploadContainer.style.borderColor = '#cbd5e0';
                uploadContainer.style.backgroundColor = '#f8fafc';
            }
            
            // Handle dropped files
            uploadContainer.addEventListener('drop', handleDrop, false);
            
            function handleDrop(e) {
                const dt = e.dataTransfer;
                const files = dt.files;
                handleFiles(files);
            }
            
            // Handle selected files from file input
            fileInput.addEventListener('change', function() {
                handleFiles(this.files);
            });
            
            function handleFiles(files) {
                const filesArray = Array.from(files);
                filesArray.forEach((file, index) => {
                    if (file.type.startsWith('image/')) {
                        const reader = new FileReader();
                        
                        reader.onload = function(e) {
                            const previewItem = document.createElement('div');
                            previewItem.className = 'preview-item';
                            
                            const img = document.createElement('img');
                            img.src = e.target.result;
                            img.className = 'image-preview';
                            img.alt = file.name;
                            
                            const removeBtn = document.createElement('div');
                            removeBtn.className = 'remove-image';
                            removeBtn.innerHTML = '<i class="fas fa-times"></i>';
                            removeBtn.addEventListener('click', function(e) {
                                e.stopPropagation();
                                previewItem.remove();
                                updatePrimaryBadges();
                            });
                            
                            previewItem.appendChild(img);
                            previewItem.appendChild(removeBtn);
                            previewContainer.appendChild(previewItem);
                            
                            updatePrimaryBadges();
                        };
                        
                        reader.readAsDataURL(file);
                    }
                });
            }
            
            function updatePrimaryBadges() {
                // Remove all primary badges
                document.querySelectorAll('.primary-badge').forEach(badge => {
                    badge.remove();
                });
                
                // Add primary badge to first image if exists
                if (previewContainer.children.length > 0) {
                    const primaryBadge = document.createElement('div');
                    primaryBadge.className = 'primary-badge';
                    primaryBadge.textContent = 'PRIMARY';
                    previewContainer.children[0].appendChild(primaryBadge);
                }
            }
        });
    </script>
    </body>
    </html>