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
    List<Map<String, Object>> paymentMethods = new ArrayList<>();
    
    // Messages for form submission
    String successMessage = "";
    String errorMessage = "";
    
    // Process form submissions
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        
        try {
            // Establish database connection
            String jdbcURL = "jdbc:mysql://localhost:3306/hotels_db";
            String dbUser = "root";
            String dbPassword = "";
            
            Class.forName("com.mysql.jdbc.Driver");
            conn = DriverManager.getConnection(jdbcURL, dbUser, dbPassword);
            
            if ("add".equals(action)) {
                // Add new payment method
                String cardType = request.getParameter("card_type");
                String cardNumber = request.getParameter("card_number");
                String cardholderName = request.getParameter("cardholder_name");
                String expiryMonth = request.getParameter("expiry_month");
                String expiryYear = request.getParameter("expiry_year");
                String cvv = request.getParameter("cvv");
                boolean isDefault = "on".equals(request.getParameter("is_default"));
                
                // Mask card number for storage (only store last 4 digits)
                String lastFourDigits = cardNumber.substring(cardNumber.length() - 4);
                String maskedCardNumber = "************" + lastFourDigits;
                
                // If this is set as default, update all other cards to non-default
                if (isDefault) {
                    String updateQuery = "UPDATE payment_methods SET is_default = false WHERE user_id = ?";
                    pstmt = conn.prepareStatement(updateQuery);
                    pstmt.setString(1, userId);
                    pstmt.executeUpdate();
                    pstmt.close();
                }
                
                // Insert new payment method
                String insertQuery = "INSERT INTO payment_methods (user_id, card_type, card_number, cardholder_name, " +
                                    "expiry_month, expiry_year, is_default, created_at) " +
                                    "VALUES (?, ?, ?, ?, ?, ?, ?, NOW())";
                
                pstmt = conn.prepareStatement(insertQuery);
                pstmt.setString(1, userId);
                pstmt.setString(2, cardType);
                pstmt.setString(3, maskedCardNumber);
                pstmt.setString(4, cardholderName);
                pstmt.setString(5, expiryMonth);
                pstmt.setString(6, expiryYear);
                pstmt.setBoolean(7, isDefault);
                
                pstmt.executeUpdate();
                successMessage = "Carte ajoutée avec succès.";
                
            } else if ("delete".equals(action)) {
                // Delete payment method
                String paymentMethodId = request.getParameter("payment_method_id");
                
                String deleteQuery = "DELETE FROM payment_methods WHERE id = ? AND user_id = ?";
                pstmt = conn.prepareStatement(deleteQuery);
                pstmt.setString(1, paymentMethodId);
                pstmt.setString(2, userId);
                
                int rowsAffected = pstmt.executeUpdate();
                if (rowsAffected > 0) {
                    successMessage = "Carte supprimée avec succès.";
                } else {
                    errorMessage = "Impossible de supprimer la carte.";
                }
                
            } else if ("set_default".equals(action)) {
                // Set payment method as default
                String paymentMethodId = request.getParameter("payment_method_id");
                
                // First, set all payment methods to non-default
                String updateAllQuery = "UPDATE payment_methods SET is_default = false WHERE user_id = ?";
                pstmt = conn.prepareStatement(updateAllQuery);
                pstmt.setString(1, userId);
                pstmt.executeUpdate();
                pstmt.close();
                
                // Then set the selected one as default
                String updateQuery = "UPDATE payment_methods SET is_default = true WHERE id = ? AND user_id = ?";
                pstmt = conn.prepareStatement(updateQuery);
                pstmt.setString(1, paymentMethodId);
                pstmt.setString(2, userId);
                
                int rowsAffected = pstmt.executeUpdate();
                if (rowsAffected > 0) {
                    successMessage = "Carte définie par défaut avec succès.";
                } else {
                    errorMessage = "Impossible de définir la carte par défaut.";
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
            user.put("profileImage", rs.getString("profile_image"));
            user.put("memberSince", rs.getDate("created_at"));
            
            // Format member since date
            SimpleDateFormat dateFormat = new SimpleDateFormat("MMMM yyyy");
            String memberSince = dateFormat.format(user.get("memberSince"));
            user.put("memberSinceFormatted", memberSince);
        }
        
        // Fetch user payment methods
        if (pstmt != null) pstmt.close();
        if (rs != null) rs.close();
        
        String paymentMethodsQuery = "SELECT * FROM payment_methods WHERE user_id = ? ORDER BY is_default DESC, created_at DESC";
        pstmt = conn.prepareStatement(paymentMethodsQuery);
        pstmt.setString(1, userId);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> paymentMethod = new HashMap<>();
            paymentMethod.put("id", rs.getString("id"));
            paymentMethod.put("cardType", rs.getString("card_type"));
            paymentMethod.put("cardNumber", rs.getString("card_number"));
            paymentMethod.put("cardholderName", rs.getString("cardholder_name"));
            paymentMethod.put("expiryMonth", rs.getString("expiry_month"));
            paymentMethod.put("expiryYear", rs.getString("expiry_year"));
            paymentMethod.put("isDefault", rs.getBoolean("is_default"));
            paymentMethod.put("createdAt", rs.getTimestamp("created_at"));
            
            // Format dates
            SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy");
            paymentMethod.put("createdAtFormatted", dateFormat.format(paymentMethod.get("createdAt")));
            
            // Add to payment methods list
            paymentMethods.add(paymentMethod);
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
    <title>ZAIRTAM - Moyens de paiement</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
            background-color: #F9FAFB;
        }
        
        .payment-card {
            transition: all 0.3s ease;
        }
        
        .payment-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
        }
        
        .card-badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 500;
        }
        
        .card-badge-default {
            background-color: #D1FAE5;
            color: #065F46;
        }
        
        .card-type-visa {
            color: #1A56DB;
        }
        
        .card-type-mastercard {
            color: #E74694;
        }
        
        .card-type-amex {
            color: #0F766E;
        }
        
        .card-type-discover {
            color: #B91C1C;
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
                        <a href="Payment-Methods.jsp" class="w-full flex items-center px-4 py-3 text-blue-600 bg-blue-50 rounded-md">
                            <i class="fas fa-credit-card w-5 text-center"></i>
                            <span class="ml-3">Moyens de paiement</span>
                        </a>
                        <a href="#" class="w-full flex items-center px-4 py-3 text-gray-700 hover:bg-gray-100 rounded-md">
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
                
                <!-- Payment Methods Overview -->
                <div class="bg-white rounded-lg shadow-sm p-6 mb-6">
                    <div class="flex justify-between items-center mb-6">
                        <h2 class="text-xl font-bold text-gray-800">Mes moyens de paiement</h2>
                        <button id="add-card-btn" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg flex items-center">
                            <i class="fas fa-plus mr-2"></i> Ajouter une carte
                        </button>
                    </div>
                    
                    <!-- Add Card Form (Hidden by default) -->
                    <div id="add-card-form" class="hidden bg-gray-50 p-6 rounded-lg mb-6">
                        <h3 class="text-lg font-semibold text-gray-800 mb-4">Ajouter une nouvelle carte</h3>
                        <form action="Payment-Methods.jsp" method="post">
                            <input type="hidden" name="action" value="add">
                            
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                                <div>
                                    <label for="card_type" class="block text-sm font-medium text-gray-700 mb-1">Type de carte</label>
                                    <select id="card_type" name="card_type" class="w-full p-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500" required>
                                        <option value="">Sélectionner...</option>
                                        <option value="visa">Visa</option>
                                        <option value="mastercard">Mastercard</option>
                                        <option value="amex">American Express</option>
                                        <option value="discover">Discover</option>
                                    </select>
                                </div>
                                
                                <div>
                                    <label for="card_number" class="block text-sm font-medium text-gray-700 mb-1">Numéro de carte</label>
                                    <input type="text" id="card_number" name="card_number" placeholder="XXXX XXXX XXXX XXXX" class="w-full p-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500" required>
                                </div>
                            </div>
                            
                            <div class="mb-4">
                                <label for="cardholder_name" class="block text-sm font-medium text-gray-700 mb-1">Nom du titulaire</label>
                                <input type="text" id="cardholder_name" name="cardholder_name" placeholder="Nom tel qu'il apparaît sur la carte" class="w-full p-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500" required>
                            </div>
                            
                            <div class="grid grid-cols-2 md:grid-cols-3 gap-4 mb-4">
                                <div>
                                    <label for="expiry_month" class="block text-sm font-medium text-gray-700 mb-1">Mois d'expiration</label>
                                    <select id="expiry_month" name="expiry_month" class="w-full p-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500" required>
                                        <option value="">MM</option>
                                        <% for (int i = 1; i <= 12; i++) { %>
                                            <option value="<%= String.format("%02d", i) %>"><%= String.format("%02d", i) %></option>
                                        <% } %>
                                    </select>
                                </div>
                                
                                <div>
                                    <label for="expiry_year" class="block text-sm font-medium text-gray-700 mb-1">Année d'expiration</label>
                                    <select id="expiry_year" name="expiry_year" class="w-full p-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500" required>
                                        <option value="">YYYY</option>
                                        <% 
                                            int currentYear = Calendar.getInstance().get(Calendar.YEAR);
                                            for (int i = currentYear; i <= currentYear + 10; i++) { 
                                        %>
                                            <option value="<%= i %>"><%= i %></option>
                                        <% } %>
                                    </select>
                                </div>
                                
                                <div>
                                    <label for="cvv" class="block text-sm font-medium text-gray-700 mb-1">CVV</label>
                                    <input type="text" id="cvv" name="cvv" placeholder="123" class="w-full p-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500" required>
                                </div>
                            </div>
                            
                            <div class="mb-4">
                                <label class="flex items-center">
                                    <input type="checkbox" name="is_default" class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded">
                                    <span class="ml-2 text-sm text-gray-700">Définir comme moyen de paiement par défaut</span>
                                </label>
                            </div>
                            
                            <div class="flex justify-end space-x-3">
                                <button type="button" id="cancel-add-card" class="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50">
                                    Annuler
                                </button>
                                <button type="submit" class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md">
                                    Ajouter la carte
                                </button>
                            </div>
                        </form>
                    </div>
                    
                    <!-- Payment Methods List -->
                    <div class="space-y-4">
                        <% if (paymentMethods.isEmpty()) { %>
                            <div class="text-center py-8">
                                <i class="fas fa-credit-card text-gray-300 text-5xl mb-4"></i>
                                <h3 class="text-lg font-medium text-gray-700 mb-2">Aucun moyen de paiement</h3>
                                <p class="text-gray-500 mb-4">Vous n'avez pas encore ajouté de moyen de paiement.</p>
                                <button id="no-cards-add-btn" class="inline-block bg-blue-600 hover:bg-blue-700 text-white font-medium px-6 py-3 rounded-lg transition duration-200">
                                    Ajouter une carte
                                </button>
                            </div>
                        <% } else { %>
                            <% for (Map<String, Object> paymentMethod : paymentMethods) { 
                                String cardType = (String) paymentMethod.get("cardType");
                                String cardTypeIcon = "";
                                String cardTypeClass = "";
                                
                                if ("visa".equalsIgnoreCase(cardType)) {
                                    cardTypeIcon = "fa-cc-visa";
                                    cardTypeClass = "card-type-visa";
                                } else if ("mastercard".equalsIgnoreCase(cardType)) {
                                    cardTypeIcon = "fa-cc-mastercard";
                                    cardTypeClass = "card-type-mastercard";
                                } else if ("amex".equalsIgnoreCase(cardType)) {
                                    cardTypeIcon = "fa-cc-amex";
                                    cardTypeClass = "card-type-amex";
                                } else if ("discover".equalsIgnoreCase(cardType)) {
                                    cardTypeIcon = "fa-cc-discover";
                                    cardTypeClass = "card-type-discover";
                                } else {
                                    cardTypeIcon = "fa-credit-card";
                                }
                            %>
                                <div class="payment-card bg-white border rounded-lg overflow-hidden">
                                    <div class="p-6">
                                        <div class="flex justify-between items-start mb-4">
                                            <div class="flex items-center">
                                                <i class="fab <%= cardTypeIcon %> <%= cardTypeClass %> text-3xl mr-3"></i>
                                                <div>
                                                    <h3 class="text-lg font-bold text-gray-800 capitalize"><%= cardType %></h3>
                                                    <p class="text-gray-600"><%= paymentMethod.get("cardNumber") %></p>
                                                </div>
                                            </div>
                                            
                                            <% if ((Boolean) paymentMethod.get("isDefault")) { %>
                                                <span class="card-badge card-badge-default">Par défaut</span>
                                            <% } %>
                                        </div>
                                        
                                        <div class="grid grid-cols-2 gap-4 mb-4">
                                            <div>
                                                <p class="text-sm text-gray-500">Titulaire</p>
                                                <p class="font-medium"><%= paymentMethod.get("cardholderName") %></p>
                                            </div>
                                            <div>
                                                <p class="text-sm text-gray-500">Expire le</p>
                                                <p class="font-medium"><%= paymentMethod.get("expiryMonth") %>/<%= paymentMethod.get("expiryYear") %></p>
                                            </div>
                                        </div>
                                        
                                        <div class="flex justify-between items-center pt-4 border-t border-gray-100">
                                            <p class="text-sm text-gray-500">Ajoutée le <%= paymentMethod.get("createdAtFormatted") %></p>
                                            
                                            <div class="flex space-x-2">
                                                <% if (!(Boolean) paymentMethod.get("isDefault")) { %>
                                                    <form action="Payment-Methods.jsp" method="post" class="inline">
                                                        <input type="hidden" name="action" value="set_default">
                                                        <input type="hidden" name="payment_method_id" value="<%= paymentMethod.get("id") %>">
                                                        <button type="submit" class="text-blue-600 hover:text-blue-800 text-sm font-medium">
                                                            Définir par défaut
                                                        </button>
                                                    </form>
                                                <% } %>
                                                
                                                <form action="Payment-Methods.jsp" method="post" class="inline" onsubmit="return confirm('Êtes-vous sûr de vouloir supprimer cette carte ?');">
                                                    <input type="hidden" name="action" value="delete">
                                                    <input type="hidden" name="payment_method_id" value="<%= paymentMethod.get("id") %>">
                                                    <button type="submit" class="text-red-600 hover:text-red-800 text-sm font-medium">
                                                        Supprimer
                                                    </button>
                                                </form>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            <% } %>
                        <% } %>
                    </div>
                </div>
                
                <!-- Payment Security Information -->
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <h3 class="text-lg font-bold text-gray-800 mb-4">Sécurité des paiements</h3>
                    
                    <div class="space-y-4">
                        <div class="flex items-start">
                            <div class="flex-shrink-0 mt-1">
                                <i class="fas fa-lock text-blue-600"></i>
                            </div>
                            <div class="ml-3">
                                <h4 class="text-base font-medium text-gray-800">Transactions sécurisées</h4>
                                <p class="text-sm text-gray-600">Toutes les transactions sont protégées par un cryptage SSL 256 bits.</p>
                            </div>
                        </div>
                        
                        <div class="flex items-start">
                            <div class="flex-shrink-0 mt-1">
                                <i class="fas fa-shield-alt text-blue-600"></i>
                            </div>
                            <div class="ml-3">
                                <h4 class="text-base font-medium text-gray-800">Protection des données</h4>
                                <p class="text-sm text-gray-600">Nous ne stockons jamais les numéros de carte complets, seulement les 4 derniers chiffres.</p>
                            </div>
                        </div>
                        
                        <div class="flex items-start">
                            <div class="flex-shrink-0 mt-1">
                                <i class="fas fa-user-shield text-blue-600"></i>
                            </div>
                            <div class="ml-3">
                                <h4 class="text-base font-medium text-gray-800">Authentification à deux facteurs</h4>
                                <p class="text-sm text-gray-600">Activez l'authentification à deux facteurs pour une sécurité supplémentaire lors des paiements.</p>
                            </div>
                        </div>
                        
                        <div class="flex items-start">
                            <div class="flex-shrink-0 mt-1">
                                <i class="fas fa-credit-card text-blue-600"></i>
                            </div>
                            <div class="ml-3">
                                <h4 class="text-base font-medium text-gray-800">Conformité PCI DSS</h4>
                                <p class="text-sm text-gray-600">Notre système de paiement est conforme aux normes PCI DSS pour garantir la sécurité de vos données.</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- JavaScript -->
    <script>
        // Toggle Add Card Form
        const addCardBtn = document.getElementById('add-card-btn');
        const addCardForm = document.getElementById('add-card-form');
        
        addCardBtn.addEventListener('click', () => {
            addCardForm.classList.toggle('hidden');
            if (!addCardForm.classList.contains('hidden')) {
                addCardBtn.innerHTML = '<i class="fas fa-times mr-2"></i> Annuler';
                addCardBtn.classList.remove('bg-blue-600', 'hover:bg-blue-700');
                addCardBtn.classList.add('bg-gray-600', 'hover:bg-gray-700');
            } else {
                addCardBtn.innerHTML = '<i class="fas fa-plus mr-2"></i> Ajouter une carte';
                addCardBtn.classList.remove('bg-gray-600', 'hover:bg-gray-700');
                addCardBtn.classList.add('bg-blue-600', 'hover:bg-blue-700');
            }
        });
        
        // Card Number Formatting
        const cardNumberInput = document.getElementById('card_number');
        
        cardNumberInput.addEventListener('input', (e) => {
            // Remove all non-digit characters
            let value = e.target.value.replace(/\D/g, '');
            
            // Add spaces after every 4 digits
            let formattedValue = '';
            for (let i = 0; i < value.length; i++) {
                if (i > 0 && i % 4 === 0) {
                    formattedValue += ' ';
                }
                formattedValue += value[i];
            }
            
            // Limit to 16 digits (19 characters with spaces)
            if (value.length > 16) {
                formattedValue = formattedValue.substring(0, 19);
            }
            
            e.target.value = formattedValue;
        });
        
        // Card Type Detection
        cardNumberInput.addEventListener('change', (e) => {
            const cardType = document.getElementById('card_type');
            const cardNumber = e.target.value.replace(/\s/g, '');
            
            // Detect card type based on first digits
            if (cardNumber.startsWith('4')) {
                cardType.value = 'visa';
            } else if (/^5[1-5]/.test(cardNumber)) {
                cardType.value = 'mastercard';
            } else if (/^3[47]/.test(cardNumber)) {
                cardType.value = 'amex';
            } else if (/^6(?:011|5)/.test(cardNumber)) {
                cardType.value = 'discover';
            }
        });
        
        // Form Validation
        const paymentForm = document.querySelector('form[action="Payment-Methods.jsp"]');
        
        paymentForm.addEventListener('submit', (e) => {
            const cardNumber = cardNumberInput.value.replace(/\s/g, '');
            
            // Basic validation
            if (cardNumber.length < 15) {
                e.preventDefault();
                alert('Veuillez entrer un numéro de carte valide');
                return;
            }
            
            const expiryMonth = document.getElementById('expiry_month').value;
            const expiryYear = document.getElementById('expiry_year').value;
            
            // Check if card is expired
            const today = new Date();
            const expiry = new Date(expiryYear, expiryMonth - 1);
            
            if (expiry < today) {
                e.preventDefault();
                alert('Cette carte a expiré. Veuillez utiliser une carte valide.');
                return;
            }
        });
        
        // Confirmation for Delete
        const deleteButtons = document.querySelectorAll('.delete-card-btn');
        
        deleteButtons.forEach(button => {
            button.addEventListener('click', (e) => {
                if (!confirm('Êtes-vous sûr de vouloir supprimer cette carte ?')) {
                    e.preventDefault();
                }
            });
        });
        
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
</body>
</html>