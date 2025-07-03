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
    Map<String, Object> userPreferences = new HashMap<>();
    
    // Messages for form submission
    String successMessage = "";
    String errorMessage = "";
    
    // Process form submissions
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        
        try {
            // Establish database connection
            String jdbcURL = "jdbc:mysql://localhost:4200/hotel?useSSL=false";
            String dbUser = "root";
            String dbPassword = "Hamza_13579";
            
            Class.forName("com.mysql.jdbc.Driver");
            conn = DriverManager.getConnection(jdbcURL, dbUser, dbPassword);
            
            if ("update_password".equals(action)) {
                // Update password
                String currentPassword = request.getParameter("current_password");
                String newPassword = request.getParameter("new_password");
                String confirmPassword = request.getParameter("confirm_password");
                
                // Verify current password
                String checkPasswordQuery = "SELECT password FROM users WHERE id = ?";
                pstmt = conn.prepareStatement(checkPasswordQuery);
                pstmt.setString(1, userId);
                rs = pstmt.executeQuery();
                
                if (rs.next()) {
                    String storedPassword = rs.getString("password");
                    
                    // Simple password check (in a real app, you'd use proper hashing)
                    if (storedPassword.equals(currentPassword)) {
                        // Check if new passwords match
                        if (newPassword.equals(confirmPassword)) {
                            // Update password
                            String updateQuery = "UPDATE users SET password = ? WHERE id = ?";
                            pstmt = conn.prepareStatement(updateQuery);
                            pstmt.setString(1, newPassword);
                            pstmt.setString(2, userId);
                            pstmt.executeUpdate();
                            
                            successMessage = "Mot de passe mis à jour avec succès.";
                        } else {
                            errorMessage = "Les nouveaux mots de passe ne correspondent pas.";
                        }
                    } else {
                        errorMessage = "Le mot de passe actuel est incorrect.";
                    }
                }
                
            } else if ("update_preferences".equals(action)) {
                // Update user preferences
                String language = request.getParameter("language");
                String currency = request.getParameter("currency");
                String timeZone = request.getParameter("time_zone");
                boolean emailNotifications = "on".equals(request.getParameter("email_notifications"));
                boolean smsNotifications = "on".equals(request.getParameter("sms_notifications"));
                boolean marketingEmails = "on".equals(request.getParameter("marketing_emails"));
                
                // Check if preferences already exist
                String checkQuery = "SELECT * FROM user_preferences WHERE user_id = ?";
                pstmt = conn.prepareStatement(checkQuery);
                pstmt.setString(1, userId);
                rs = pstmt.executeQuery();
                
                if (rs.next()) {
                    // Update existing preferences
                    String updateQuery = "UPDATE user_preferences SET language = ?, currency = ?, time_zone = ?, " +
                                        "email_notifications = ?, sms_notifications = ?, marketing_emails = ?, " +
                                        "updated_at = NOW() WHERE user_id = ?";
                    
                    pstmt = conn.prepareStatement(updateQuery);
                    pstmt.setString(1, language);
                    pstmt.setString(2, currency);
                    pstmt.setString(3, timeZone);
                    pstmt.setBoolean(4, emailNotifications);
                    pstmt.setBoolean(5, smsNotifications);
                    pstmt.setBoolean(6, marketingEmails);
                    pstmt.setString(7, userId);
                    
                    pstmt.executeUpdate();
                } else {
                    // Insert new preferences
                    String insertQuery = "INSERT INTO user_preferences (user_id, language, currency, time_zone, " +
                                        "email_notifications, sms_notifications, marketing_emails, created_at) " +
                                        "VALUES (?, ?, ?, ?, ?, ?, ?, NOW())";
                    
                    pstmt = conn.prepareStatement(insertQuery);
                    pstmt.setString(1, userId);
                    pstmt.setString(2, language);
                    pstmt.setString(3, currency);
                    pstmt.setString(4, timeZone);
                    pstmt.setBoolean(5, emailNotifications);
                    pstmt.setBoolean(6, smsNotifications);
                    pstmt.setBoolean(7, marketingEmails);
                    
                    pstmt.executeUpdate();
                }
                
                successMessage = "Préférences mises à jour avec succès.";
                
            } else if ("update_privacy".equals(action)) {
                // Update privacy settings
                boolean profileVisibility = "on".equals(request.getParameter("profile_visibility"));
                boolean showBookingHistory = "on".equals(request.getParameter("show_booking_history"));
                boolean showReviews = "on".equals(request.getParameter("show_reviews"));
                
                // Check if privacy settings already exist
                String checkQuery = "SELECT * FROM user_privacy WHERE user_id = ?";
                pstmt = conn.prepareStatement(checkQuery);
                pstmt.setString(1, userId);
                rs = pstmt.executeQuery();
                
                if (rs.next()) {
                    // Update existing privacy settings
                    String updateQuery = "UPDATE user_privacy SET profile_visibility = ?, show_booking_history = ?, " +
                                        "show_reviews = ?, updated_at = NOW() WHERE user_id = ?";
                    
                    pstmt = conn.prepareStatement(updateQuery);
                    pstmt.setBoolean(1, profileVisibility);
                    pstmt.setBoolean(2, showBookingHistory);
                    pstmt.setBoolean(3, showReviews);
                    pstmt.setString(4, userId);
                    
                    pstmt.executeUpdate();
                } else {
                    // Insert new privacy settings
                    String insertQuery = "INSERT INTO user_privacy (user_id, profile_visibility, show_booking_history, " +
                                        "show_reviews, created_at) VALUES (?, ?, ?, ?, NOW())";
                    
                    pstmt = conn.prepareStatement(insertQuery);
                    pstmt.setString(1, userId);
                    pstmt.setBoolean(2, profileVisibility);
                    pstmt.setBoolean(3, showBookingHistory);
                    pstmt.setBoolean(4, showReviews);
                    
                    pstmt.executeUpdate();
                }
                
                successMessage = "Paramètres de confidentialité mis à jour avec succès.";
                
            } else if ("delete_account".equals(action)) {
                // Delete account (soft delete)
                String confirmDelete = request.getParameter("confirm_delete");
                
                if ("DELETE".equals(confirmDelete)) {
                    String updateQuery = "UPDATE users SET status = 'deleted', deleted_at = NOW() WHERE id = ?";
                    pstmt = conn.prepareStatement(updateQuery);
                    pstmt.setString(1, userId);
                    pstmt.executeUpdate();
                    
                    // Invalidate session
                    session.invalidate();
                    
                    // Redirect to home page
                    response.sendRedirect("../index.jsp");
                    return;
                } else {
                    errorMessage = "Confirmation incorrecte. Veuillez saisir 'DELETE' pour confirmer.";
                }
            }
            
        } catch (Exception e) {
            errorMessage = "Erreur: " + e.getMessage();
            e.printStackTrace();
        } finally {
            try {
                if (pstmt != null) pstmt.close();
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
    
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
            user.put("profileImage", rs.getString("profile_image"));
            user.put("memberSince", rs.getDate("created_at"));
            
            // Format member since date
            SimpleDateFormat dateFormat = new SimpleDateFormat("MMMM yyyy");
            String memberSince = dateFormat.format(user.get("memberSince"));
            user.put("memberSinceFormatted", memberSince);
        }
        
        // Fetch user preferences
        if (pstmt != null) pstmt.close();
        if (rs != null) rs.close();
        
        String preferencesQuery = "SELECT * FROM user_preferences WHERE user_id = ?";
        pstmt = conn.prepareStatement(preferencesQuery);
        pstmt.setString(1, userId);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            userPreferences.put("language", rs.getString("language"));
            userPreferences.put("currency", rs.getString("currency"));
            userPreferences.put("timeZone", rs.getString("time_zone"));
            userPreferences.put("emailNotifications", rs.getBoolean("email_notifications"));
            userPreferences.put("smsNotifications", rs.getBoolean("sms_notifications"));
            userPreferences.put("marketingEmails", rs.getBoolean("marketing_emails"));
        } else {
            // Default preferences
            userPreferences.put("language", "fr");
            userPreferences.put("currency", "EUR");
            userPreferences.put("timeZone", "Europe/Paris");
            userPreferences.put("emailNotifications", true);
            userPreferences.put("smsNotifications", false);
            userPreferences.put("marketingEmails", true);
        }
        
        // Fetch privacy settings
        if (pstmt != null) pstmt.close();
        if (rs != null) rs.close();
        
        String privacyQuery = "SELECT * FROM user_privacy WHERE user_id = ?";
        pstmt = conn.prepareStatement(privacyQuery);
        pstmt.setString(1, userId);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            userPreferences.put("profileVisibility", rs.getBoolean("profile_visibility"));
            userPreferences.put("showBookingHistory", rs.getBoolean("show_booking_history"));
            userPreferences.put("showReviews", rs.getBoolean("show_reviews"));
        } else {
            // Default privacy settings
            userPreferences.put("profileVisibility", true);
            userPreferences.put("showBookingHistory", true);
            userPreferences.put("showReviews", true);
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
    <title>ZAIRTAM - Paramètres du compte</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
            background-color: #F9FAFB;
        }
        
        .settings-card {
            transition: all 0.3s ease;
        }
        
        .settings-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
        }
        
        .tab-active {
            background-color: #EFF6FF;
            color: #2563EB;
            border-left: 3px solid #2563EB;
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
                            <c:choose>
                                <c:when test="${not empty user.profileImage}">
                                    <img src="${user.profileImage}" alt="${user.firstName} ${user.lastName}" class="h-8 w-8 rounded-full object-cover">
                                </c:when>
                                <c:otherwise>
                                    <div class="h-8 w-8 rounded-full bg-blue-100 flex items-center justify-center">
                                        <i class="fas fa-user text-blue-600"></i>
                                    </div>
                                </c:otherwise>
                            </c:choose>
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
                            <c:choose>
                                <c:when test="${not empty user.profileImage}">
                                    <img src="${user.profileImage}" alt="${user.firstName} ${user.lastName}" class="h-24 w-24 rounded-full object-cover border-4 border-white shadow">
                                </c:when>
                                <c:otherwise>
                                    <div class="h-24 w-24 rounded-full bg-blue-100 flex items-center justify-center border-4 border-white shadow">
                                        <i class="fas fa-user text-blue-600 text-4xl"></i>
                                    </div>
                                </c:otherwise>
                            </c:choose>
                        </div>
                        <h2 class="text-xl font-bold text-gray-800">${user.firstName} ${user.lastName}</h2>
                        <p class="text-gray-600 text-sm">Membre depuis ${user.memberSinceFormatted}</p>
                    </div>
                    
                    <!-- Navigation Tabs -->
                    <div class="space-y-1">
                        <a href="Profile.jsp" class="w-full flex items-center px-4 py-3 text-gray-700 hover:bg-gray-100 rounded-md">
                            <i class="fas fa-user w-5 text-center"></i>
                            <span class="ml-3">Informations du profil</span>
                        </a>
                        <a href="Reservations.jsp" class="w-full flex items-center px-4 py-3 text-gray-700 hover:bg-gray-100 rounded-md">
                            <i class="fas fa-calendar-alt w-5 text-center"></i>
                            <span class="ml-3">Réservations</span>
                        </a>
                        <a href="Payment-Methods.jsp" class="w-full flex items-center px-4 py-3 text-gray-700 hover:bg-gray-100 rounded-md">
                            <i class="fas fa-credit-card w-5 text-center"></i>
                            <span class="ml-3">Moyens de paiement</span>
                        </a>
                        <a href="Account-Settings.jsp" class="w-full flex items-center px-4 py-3 text-blue-600 bg-blue-50 rounded-md">
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
                <!-- Success/Error Messages -->
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
                
                <!-- Settings Tabs -->
                <div class="bg-white rounded-lg shadow-sm overflow-hidden mb-6">
                    <div class="flex border-b">
                        <button id="security-tab-btn" class="tab-btn flex-1 py-4 px-6 text-center font-medium text-blue-600 border-b-2 border-blue-600" data-tab="security-tab">
                            <i class="fas fa-shield-alt mr-2"></i> Sécurité
                        </button>
                        <button id="preferences-tab-btn" class="tab-btn flex-1 py-4 px-6 text-center font-medium text-gray-500 hover:text-gray-700" data-tab="preferences-tab">
                            <i class="fas fa-sliders-h mr-2"></i> Préférences
                        </button>
                        <button id="privacy-tab-btn" class="tab-btn flex-1 py-4 px-6 text-center font-medium text-gray-500 hover:text-gray-700" data-tab="privacy-tab">
                            <i class="fas fa-user-shield mr-2"></i> Confidentialité
                        </button>
                        <button id="account-tab-btn" class="tab-btn flex-1 py-4 px-6 text-center font-medium text-gray-500 hover:text-gray-700" data-tab="account-tab">
                            <i class="fas fa-user-cog mr-2"></i> Compte
                        </button>
                    </div>
                    
                    <!-- Security Tab Content -->
                    <div id="security-tab" class="tab-content active p-6">
                        <h3 class="text-lg font-semibold text-gray-800 mb-4">Modifier votre mot de passe</h3>
                        <form action="Account-Settings.jsp" method="post">
                            <input type="hidden" name="action" value="update_password">
                            
                            <div class="mb-4">
                                <label for="current_password" class="block text-sm font-medium text-gray-700 mb-1">Mot de passe actuel</label>
                                <input type="password" id="current_password" name="current_password" class="w-full p-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500" required>
                            </div>
                            
                            <div class="mb-4">
                                <label for="new_password" class="block text-sm font-medium text-gray-700 mb-1">Nouveau mot de passe</label>
                                <input type="password" id="new_password" name="new_password" class="w-full p-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500" required>
                                <p class="mt-1 text-xs text-gray-500">Le mot de passe doit contenir au moins 8 caractères, incluant des lettres majuscules, minuscules et des chiffres.</p>
                            </div>
                            
                            <div class="mb-4">
                                <label for="confirm_password" class="block text-sm font-medium text-gray-700 mb-1">Confirmer le nouveau mot de passe</label>
                                <input type="password" id="confirm_password" name="confirm_password" class="w-full p-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500" required>
                            </div>
                            
                            <div class="mt-6">
                                <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg">
                                    Mettre à jour le mot de passe
                                </button>
                            </div>
                        </form>
                        
                        <div class="mt-8 pt-6 border-t border-gray-200">
                            <h3 class="text-lg font-semibold text-gray-800 mb-4">Authentification à deux facteurs</h3>
                            <p class="text-gray-600 mb-4">L'authentification à deux facteurs ajoute une couche de sécurité supplémentaire à votre compte en exigeant plus qu'un simple mot de passe pour vous connecter.</p>
                            
                            <div class="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                                <div>
                                    <h4 class="font-medium text-gray-800">Authentification par SMS</h4>
                                    <p class="text-sm text-gray-600">Recevez un code de vérification par SMS lors de la connexion</p>
                                </div>
                                <div class="flex items-center">
                                    <span class="mr-3 text-sm text-red-600">Désactivé</span>
                                    <button class="bg-gray-200 hover:bg-gray-300 text-gray-800 px-3 py-1 rounded-lg text-sm">
                                        Activer
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Preferences Tab Content -->
                    <div id="preferences-tab" class="tab-content hidden p-6">
                        <h3 class="text-lg font-semibold text-gray-800 mb-4">Préférences utilisateur</h3>
                        <form action="Account-Settings.jsp" method="post">
                            <input type="hidden" name="action" value="update_preferences">
                            
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
                                <div>
                                    <label for="language" class="block text-sm font-medium text-gray-700 mb-1">Langue</label>
                                    <select id="language" name="language" class="w-full p-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500">
                                        <option value="fr" ${userPreferences.language == 'fr' ? 'selected' : ''}>Français</option>
                                        <option value="en" ${userPreferences.language == 'en' ? 'selected' : ''}>English</option>
                                        <option value="es" ${userPreferences.language == 'es' ? 'selected' : ''}>Español</option>
                                        <option value="de" ${userPreferences.language == 'de' ? 'selected' : ''}>Deutsch</option>
                                    </select>
                                </div>
                                
                                <div>
                                    <label for="currency" class="block text-sm font-medium text-gray-700 mb-1">Devise</label>
                                    <select id="currency" name="currency" class="w-full p-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500">
                                        <option value="EUR" ${userPreferences.currency == 'EUR' ? 'selected' : ''}>Euro (€)</option>
                                        <option value="USD" ${userPreferences.currency == 'USD' ? 'selected' : ''}>US Dollar ($)</option>
                                        <option value="GBP" ${userPreferences.currency == 'GBP' ? 'selected' : ''}>British Pound (£)</option>
                                        <option value="JPY" ${userPreferences.currency == 'JPY' ? 'selected' : ''}>Japanese Yen (¥)</option>
                                    </select>
                                </div>
                            </div>
                            
                            <div class="mb-6">
                                <label for="time_zone" class="block text-sm font-medium text-gray-700 mb-1">Fuseau horaire</label>
                                <select id="time_zone" name="time_zone" class="w-full p-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500">
                                    <option value="Europe/Paris" ${userPreferences.timeZone == 'Europe/Paris' ? 'selected' : ''}>Europe/Paris</option>
                                    <option value="Europe/London" ${userPreferences.timeZone == 'Europe/London' ? 'selected' : ''}>Europe/London</option>
                                    <option value="America/New_York" ${userPreferences.timeZone == 'America/New_York' ? 'selected' : ''}>America/New York</option>
                                    <option value="Asia/Tokyo" ${userPreferences.timeZone == 'Asia/Tokyo' ? 'selected' : ''}>Asia/Tokyo</option>
                                </select>
                            </div>
                            
                            <h4 class="font-medium text-gray-800 mb-3 mt-6">Notifications</h4>
                            
                            <div class="space-y-3 mb-6">
                                <div class="flex items-center">
                                    <input type="checkbox" id="email_notifications" name="email_notifications" class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded" ${userPreferences.emailNotifications ? 'checked' : ''}>
                                    <label for="email_notifications" class="ml-2 block text-sm text-gray-700">
                                        Recevoir des notifications par email
                                    </label>
                                </div>
                                
                                <div class="flex items-center">
                                    <input type="checkbox" id="sms_notifications" name="sms_notifications" class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded" ${userPreferences.smsNotifications ? 'checked' : ''}>
                                    <label for="sms_notifications" class="ml-2 block text-sm text-gray-700">
                                        Recevoir des notifications par SMS
                                    </label>
                                </div>
                                
                                <div class="flex items-center">
                                    <input type="checkbox" id="marketing_emails" name="marketing_emails" class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded" ${userPreferences.marketingEmails ? 'checked' : ''}>
                                    <label for="marketing_emails" class="ml-2 block text-sm text-gray-700">
                                        Recevoir des emails marketing et promotionnels
                                    </label>
                                </div>
                            </div>
                            
                            <div class="flex justify-end">
                                <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium transition duration-200">
                                    Enregistrer les préférences
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
                
                <!-- Privacy Settings -->
                <div id="privacy-settings" class="bg-white rounded-lg shadow-sm p-6 mb-6">
                    <h2 class="text-xl font-bold text-gray-800 mb-4">Paramètres de confidentialité</h2>
                    
                    <form action="Account-Settings.jsp" method="post">
                        <input type="hidden" name="action" value="update_privacy">
                        
                        <div class="space-y-3 mb-6">
                            <div class="flex items-center">
                                <input type="checkbox" id="profile_visibility" name="profile_visibility" class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded" ${userPreferences.profileVisibility ? 'checked' : ''}>
                                <label for="profile_visibility" class="ml-2 block text-sm text-gray-700">
                                    Rendre mon profil visible pour les autres utilisateurs
                                </label>
                            </div>
                            
                            <div class="flex items-center">
                                <input type="checkbox" id="show_booking_history" name="show_booking_history" class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded" ${userPreferences.showBookingHistory ? 'checked' : ''}>
                                <label for="show_booking_history" class="ml-2 block text-sm text-gray-700">
                                    Afficher mon historique de réservations sur mon profil
                                </label>
                            </div>
                            
                            <div class="flex items-center">
                                <input type="checkbox" id="show_reviews" name="show_reviews" class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded" ${userPreferences.showReviews ? 'checked' : ''}>
                                <label for="show_reviews" class="ml-2 block text-sm text-gray-700">
                                    Afficher mes avis et évaluations sur mon profil
                                </label>
                            </div>
                        </div>
                        
                        <div class="flex justify-end">
                            <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium transition duration-200">
                                Enregistrer les paramètres
                            </button>
                        </div>
                    </form>
                </div>
                
                <!-- Delete Account Section -->
                <div id="delete-account" class="bg-white rounded-lg shadow-sm p-6 mb-6 border border-red-200">
                    <h2 class="text-xl font-bold text-red-600 mb-4">Supprimer mon compte</h2>
                    
                    <div class="mb-6">
                        <p class="text-gray-700 mb-4">La suppression de votre compte est définitive et entraînera la perte de toutes vos données, y compris :</p>
                        
                        <ul class="list-disc pl-5 mb-4 text-gray-600 space-y-1">
                            <li>Votre profil et informations personnelles</li>
                            <li>Votre historique de réservations</li>
                            <li>Vos avis et évaluations</li>
                            <li>Vos moyens de paiement enregistrés</li>
                            <li>Vos préférences et paramètres</li>
                        </ul>
                        
                        <div class="bg-yellow-50 border-l-4 border-yellow-400 p-4 mb-4">
                            <div class="flex">
                                <div class="flex-shrink-0">
                                    <i class="fas fa-exclamation-triangle text-yellow-400"></i>
                                </div>
                                <div class="ml-3">
                                    <p class="text-sm text-yellow-700">
                                        Cette action est irréversible. Veuillez vous assurer que vous souhaitez vraiment supprimer votre compte.
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <form action="Account-Settings.jsp" method="post" onsubmit="return confirmDelete()">
                        <input type="hidden" name="action" value="delete_account">
                        
                        <div class="mb-4">
                            <label for="confirm_delete" class="block text-sm font-medium text-gray-700 mb-1">
                                Pour confirmer, veuillez saisir "DELETE" ci-dessous
                            </label>
                            <input type="text" id="confirm_delete" name="confirm_delete" class="w-full p-2 border border-gray-300 rounded-md focus:ring-red-500 focus:border-red-500" required>
                        </div>
                        
                        <div class="flex justify-end">
                            <button type="submit" class="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-md text-sm font-medium transition duration-200">
                                Supprimer définitivement mon compte
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- JavaScript -->
    <script>
        // Tab Navigation
        const tabs = document.querySelectorAll('.settings-tab');
        const tabContents = document.querySelectorAll('.tab-content');
        
        tabs.forEach(tab => {
            tab.addEventListener('click', () => {
                // Remove active class from all tabs
                tabs.forEach(t => t.classList.remove('tab-active'));
                
                // Add active class to clicked tab
                tab.classList.add('tab-active');
                
                // Show corresponding tab content
                const target = tab.getAttribute('data-target');
                
                tabContents.forEach(content => {
                    if (content.id === target) {
                        content.classList.remove('hidden');
                    } else {
                        content.classList.add('hidden');
                    }
                });
            });
        });
        
        // Password Validation
        const newPasswordInput = document.getElementById('new_password');
        const confirmPasswordInput = document.getElementById('confirm_password');
        const passwordForm = document.querySelector('form[action="Account-Settings.jsp"][name="password_form"]');
        
        if (passwordForm) {
            passwordForm.addEventListener('submit', (e) => {
                if (newPasswordInput.value !== confirmPasswordInput.value) {
                    e.preventDefault();
                    alert('Les mots de passe ne correspondent pas.');
                    return false;
                }
                
                if (newPasswordInput.value.length < 8) {
                    e.preventDefault();
                    alert('Le mot de passe doit contenir au moins 8 caractères.');
                    return false;
                }
                
                return true;
            });
        }
        
        // Confirm Delete Account
        function confirmDelete() {
            const confirmInput = document.getElementById('confirm_delete');
            
            if (confirmInput.value !== 'DELETE') {
                alert('Veuillez saisir "DELETE" pour confirmer la suppression de votre compte.');
                return false;
            }
            
            return confirm('Êtes-vous vraiment sûr de vouloir supprimer définitivement votre compte ? Cette action est irréversible.');
        }
        
        // Auto-hide success messages
        const successMessage = document.querySelector('.bg-green-50');
        if (successMessage) {
            setTimeout(() => {
                successMessage.style.opacity = '0';
                successMessage.style.transition = 'opacity 0.5s ease';
                setTimeout(() => {
                    successMessage.style.display = 'none';
                }, 500);
            }, 5000);
        }
    </script>

    <!-- Add JavaScript for tab switching -->
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Get all tab buttons and content
            const tabButtons = document.querySelectorAll('.tab-btn');
            const tabContents = document.querySelectorAll('.tab-content');
            
            // Add click event to each tab button
            tabButtons.forEach(button => {
                button.addEventListener('click', function() {
                    // Remove active class from all buttons and contents
                    tabButtons.forEach(btn => {
                        btn.classList.remove('text-blue-600', 'border-b-2', 'border-blue-600');
                        btn.classList.add('text-gray-500');
                    });
                    
                    tabContents.forEach(content => {
                        content.classList.add('hidden');
                        content.classList.remove('active');
                    });
                    
                    // Add active class to clicked button
                    this.classList.add('text-blue-600', 'border-b-2', 'border-blue-600');
                    this.classList.remove('text-gray-500');
                    
                    // Show corresponding content
                    const tabId = this.getAttribute('data-tab');
                    const tabContent = document.getElementById(tabId);
                    tabContent.classList.remove('hidden');
                    tabContent.classList.add('active');
                });
            });
        });
    </script>
</body>
</html>