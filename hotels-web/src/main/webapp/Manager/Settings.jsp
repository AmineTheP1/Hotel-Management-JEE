<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    // Paramètres de connexion à la base de données
    String url = "jdbc:mysql://localhost:4200/hotel?useSSL=false"; // Change to your database name
    String username = "root"; // Change to your database username
    String password = "Hamza_13579"; // Change to your database password
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // User information - Get from session if available
    String adminName = (String) session.getAttribute("adminName");
    String adminImage = (String) session.getAttribute("adminImage");
    
    // Set default values if not in session
    if (adminName == null) adminName = "Admin";
    if (adminImage == null) adminImage = "";
    
    // Variables pour stocker les paramètres du système
    Map<String, String> systemSettings = new HashMap<>();
    List<Map<String, Object>> emailTemplatesList = new ArrayList<>();
    List<Map<String, Object>> paymentGatewaysList = new ArrayList<>();
    List<Map<String, Object>> apiIntegrationsList = new ArrayList<>();
    
    // Variables pour les messages
    String successMessage = "";
    String errorMessage = "";
    
    // Traitement des actions (mise à jour des paramètres)
    if (request.getMethod().equals("POST")) {
        String action = request.getParameter("action");
        
        try {
            // Établir la connexion à la base de données
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(url, username, password);
            PreparedStatement userStmt = conn.prepareStatement(
            "SELECT u.first_name, u.last_name " + 
            "FROM users u " +
            "JOIN roles r ON u.role_id = r.role_id " + 
            "WHERE r.name = 'manager' " + 
            "LIMIT 1");
        ResultSet userRs = userStmt.executeQuery();
        if (userRs.next()) {
            // Combine first and last names
            adminName = userRs.getString("first_name") + " " + userRs.getString("last_name");
            
            // Store in session for future use
            session.setAttribute("adminName", adminName);
            session.setAttribute("adminImage", adminImage);
        }
            if ("update_general".equals(action)) {
                // Mise à jour des paramètres généraux
                String siteName = request.getParameter("site_name");
                String siteUrl = request.getParameter("site_url");
                String adminEmail = request.getParameter("admin_email");
                String dateFormat = request.getParameter("date_format");
                String timeZone = request.getParameter("time_zone");
                
                String updateQuery = "UPDATE system_settings SET value = ? WHERE setting_key = ?";
                pstmt = conn.prepareStatement(updateQuery);
                
                // Mettre à jour le nom du site
                pstmt.setString(1, siteName);
                pstmt.setString(2, "site_name");
                pstmt.executeUpdate();
                
                // Mettre à jour l'URL du site
                pstmt.setString(1, siteUrl);
                pstmt.setString(2, "site_url");
                pstmt.executeUpdate();
                
                // Mettre à jour l'email de l'administrateur
                pstmt.setString(1, adminEmail);
                pstmt.setString(2, "admin_email");
                pstmt.executeUpdate();
                
                // Mettre à jour le format de date
                pstmt.setString(1, dateFormat);
                pstmt.setString(2, "date_format");
                pstmt.executeUpdate();
                
                // Mettre à jour le fuseau horaire
                pstmt.setString(1, timeZone);
                pstmt.setString(2, "time_zone");
                pstmt.executeUpdate();
                
                successMessage = "Paramètres généraux mis à jour avec succès.";
            } else if ("update_email".equals(action)) {
                // Mise à jour des paramètres d'email
                String smtpServer = request.getParameter("smtp_server");
                String smtpPort = request.getParameter("smtp_port");
                String smtpUsername = request.getParameter("smtp_username");
                String smtpPassword = request.getParameter("smtp_password");
                String smtpEncryption = request.getParameter("smtp_encryption");
                
                String updateQuery = "UPDATE system_settings SET value = ? WHERE setting_key = ?";
                pstmt = conn.prepareStatement(updateQuery);
                
                // Mettre à jour le serveur SMTP
                pstmt.setString(1, smtpServer);
                pstmt.setString(2, "smtp_server");
                pstmt.executeUpdate();
                
                // Mettre à jour le port SMTP
                pstmt.setString(1, smtpPort);
                pstmt.setString(2, "smtp_port");
                pstmt.executeUpdate();
                
                // Mettre à jour le nom d'utilisateur SMTP
                pstmt.setString(1, smtpUsername);
                pstmt.setString(2, "smtp_username");
                pstmt.executeUpdate();
                
                // Mettre à jour le mot de passe SMTP
                pstmt.setString(1, smtpPassword);
                pstmt.setString(2, "smtp_password");
                pstmt.executeUpdate();
                
                // Mettre à jour le type d'encryption SMTP
                pstmt.setString(1, smtpEncryption);
                pstmt.setString(2, "smtp_encryption");
                pstmt.executeUpdate();
                
                successMessage = "Paramètres d'email mis à jour avec succès.";
            } else if ("update_payment".equals(action)) {
                // Mise à jour des paramètres de paiement
                String currencyCode = request.getParameter("currency_code");
                String paypalEnabled = request.getParameter("paypal_enabled") != null ? "1" : "0";
                String stripeEnabled = request.getParameter("stripe_enabled") != null ? "1" : "0";
                String paypalClientId = request.getParameter("paypal_client_id");
                String stripeApiKey = request.getParameter("stripe_api_key");
                
                String updateQuery = "UPDATE system_settings SET value = ? WHERE setting_key = ?";
                pstmt = conn.prepareStatement(updateQuery);
                
                // Mettre à jour le code de devise
                pstmt.setString(1, currencyCode);
                pstmt.setString(2, "currency_code");
                pstmt.executeUpdate();
                
                // Mettre à jour l'activation de PayPal
                pstmt.setString(1, paypalEnabled);
                pstmt.setString(2, "paypal_enabled");
                pstmt.executeUpdate();
                
                // Mettre à jour l'activation de Stripe
                pstmt.setString(1, stripeEnabled);
                pstmt.setString(2, "stripe_enabled");
                pstmt.executeUpdate();
                
                // Mettre à jour l'ID client PayPal
                pstmt.setString(1, paypalClientId);
                pstmt.setString(2, "paypal_client_id");
                pstmt.executeUpdate();
                
                // Mettre à jour la clé API Stripe
                pstmt.setString(1, stripeApiKey);
                pstmt.setString(2, "stripe_api_key");
                pstmt.executeUpdate();
                
                successMessage = "Paramètres de paiement mis à jour avec succès.";
            } else if ("update_api".equals(action)) {
                // Mise à jour des paramètres d'API
                String googleMapsKey = request.getParameter("google_maps_key");
                String weatherApiKey = request.getParameter("weather_api_key");
                String recaptchaKey = request.getParameter("recaptcha_key");
                
                String updateQuery = "UPDATE system_settings SET value = ? WHERE setting_key = ?";
                pstmt = conn.prepareStatement(updateQuery);
                
                // Mettre à jour la clé Google Maps
                pstmt.setString(1, googleMapsKey);
                pstmt.setString(2, "google_maps_key");
                pstmt.executeUpdate();
                
                // Mettre à jour la clé API météo
                pstmt.setString(1, weatherApiKey);
                pstmt.setString(2, "weather_api_key");
                pstmt.executeUpdate();
                
                // Mettre à jour la clé reCAPTCHA
                pstmt.setString(1, recaptchaKey);
                pstmt.setString(2, "recaptcha_key");
                pstmt.executeUpdate();
                
                successMessage = "Paramètres d'API mis à jour avec succès.";
            }
        } catch (Exception e) {
            errorMessage = "Erreur lors de la mise à jour des paramètres: " + e.getMessage();
            e.printStackTrace();
        }
    }
    
    try {
        // Établir la connexion à la base de données
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(url, username, password);
        
        // Récupérer tous les paramètres du système
        String settingsQuery = "SELECT setting_key, value, description FROM system_settings";
        pstmt = conn.prepareStatement(settingsQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            systemSettings.put(rs.getString("setting_key"), rs.getString("value"));
        }
        
        rs.close();
        pstmt.close();
        
        // Récupérer les modèles d'emails
        String emailTemplatesQuery = "SELECT id, name, subject, template, last_updated FROM email_templates";
        pstmt = conn.prepareStatement(emailTemplatesQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> template = new HashMap<>();
            template.put("id", rs.getInt("id"));
            template.put("name", rs.getString("name"));
            template.put("subject", rs.getString("subject"));
            template.put("template", rs.getString("template"));
            template.put("last_updated", rs.getTimestamp("last_updated"));
            
            emailTemplatesList.add(template);
        }
        
        rs.close();
        pstmt.close();
        
        // Récupérer les passerelles de paiement
        String paymentGatewaysQuery = "SELECT id, name, is_active, api_key, secret_key FROM payment_gateways";
        pstmt = conn.prepareStatement(paymentGatewaysQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> gateway = new HashMap<>();
            gateway.put("id", rs.getInt("id"));
            gateway.put("name", rs.getString("name"));
            gateway.put("is_active", rs.getBoolean("is_active"));
            gateway.put("api_key", rs.getString("api_key"));
            gateway.put("secret_key", rs.getString("secret_key"));
            
            paymentGatewaysList.add(gateway);
        }
        
        rs.close();
        pstmt.close();
        
        // Récupérer les intégrations API
        String apiIntegrationsQuery = "SELECT id, name, api_key, is_active, last_used FROM api_integrations";
        pstmt = conn.prepareStatement(apiIntegrationsQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> integration = new HashMap<>();
            integration.put("id", rs.getInt("id"));
            integration.put("name", rs.getString("name"));
            integration.put("api_key", rs.getString("api_key"));
            integration.put("is_active", rs.getBoolean("is_active"));
            integration.put("last_used", rs.getTimestamp("last_used"));
            
            apiIntegrationsList.add(integration);
        }
        
    } catch (Exception e) {
        errorMessage = "Erreur lors de la récupération des paramètres: " + e.getMessage();
        e.printStackTrace();
    } finally {
        // Fermer les ressources de base de données
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
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZAIRTAM - Paramètres du Système</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
        }
        
        .settings-card {
            transition: all 0.3s ease;
        }
        
        .settings-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
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
        
        .tab-content {
            display: none;
        }
        
        .tab-content.active {
            display: block;
        }
    </style>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Sidebar toggle for mobile
            const sidebarToggle = document.getElementById('sidebar-toggle');
            const sidebar = document.getElementById('sidebar');
            
            sidebarToggle.addEventListener('click', function() {
                sidebar.classList.toggle('open');
            });
            
            // Tab navigation functionality
            const tabLinks = document.querySelectorAll('.tab-link');
            const tabContents = document.querySelectorAll('.tab-content');
            
            tabLinks.forEach(link => {
                link.addEventListener('click', function(e) {
                    e.preventDefault();
                    
                    // Get the target tab ID from data attribute
                    const targetTab = this.getAttribute('data-tab');
                    
                    // Remove active class from all tab links and contents
                    tabLinks.forEach(link => link.classList.remove('active'));
                    tabContents.forEach(content => content.classList.remove('active'));
                    
                    // Add active class to current tab link and content
                    this.classList.add('active');
                    document.getElementById(targetTab).classList.add('active');
                });
            });
        });
    </script>
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
                            <a href="hotels.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
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
                                <i class="fas fa-money-bill-wave w-5 text-center"></i>
                                <span class="ml-2">Revenue</span>
                            </a>
                        </li>
                        <li>
                            <a href="Statistiques.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-chart-pie w-5 text-center"></i>
                                <span class="ml-2">Statistics</span>
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
                            <a href="#" class="flex items-center px-3 py-2 text-blue-600 bg-blue-50 rounded-md">
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
        <main class="flex-1 p-6">
            <div class="max-w-7xl mx-auto">
                <!-- Page Header -->
                <div class="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
                    <div>
                        <h1 class="text-2xl font-bold text-gray-900">Paramètres du Système</h1>
                        <p class="mt-1 text-sm text-gray-600">Gérez les paramètres et configurations de votre plateforme</p>
                    </div>
                    <div class="mt-4 md:mt-0">
                        <button class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg shadow-sm flex items-center">
                            <i class="fas fa-sync-alt mr-2"></i>
                            Réinitialiser les paramètres
                        </button>
                    </div>
                </div>
                
                <% if (!successMessage.isEmpty()) { %>
                <div class="bg-green-100 border-l-4 border-green-500 text-green-700 p-4 mb-6 rounded" role="alert">
                    <p><i class="fas fa-check-circle mr-2"></i> <%= successMessage %></p>
                </div>
                <% } %>
                
                <% if (!errorMessage.isEmpty()) { %>
                <div class="bg-red-100 border-l-4 border-red-500 text-red-700 p-4 mb-6 rounded" role="alert">
                    <p><i class="fas fa-exclamation-circle mr-2"></i> <%= errorMessage %></p>
                </div>
                <% } %>
                
                <!-- Settings Tabs -->
                <div class="bg-white rounded-lg shadow-sm overflow-hidden mb-8">
                    <div class="flex border-b">
                        <button class="tab-link active px-6 py-3 text-sm font-medium
                                       text-blue-600 border-b-2 border-blue-600"
                                data-tab="general-tab">
                            <i class="fas fa-sliders-h mr-2"></i> Général
                        </button>
                      
                        <button class="tab-link px-6 py-3 text-sm font-medium text-gray-500 hover:text-gray-700"
                                data-tab="email-tab">
                            <i class="fas fa-envelope mr-2"></i> Email
                        </button>
                      
                        <button class="tab-link px-6 py-3 text-sm font-medium text-gray-500 hover:text-gray-700"
                                data-tab="payment-tab">
                            <i class="fas fa-credit-card mr-2"></i> Paiement
                        </button>
                      
                        <button class="tab-link px-6 py-3 text-sm font-medium text-gray-500 hover:text-gray-700"
                                data-tab="api-tab">
                            <i class="fas fa-plug mr-2"></i> API
                        </button>
                      
                        <button class="tab-link px-6 py-3 text-sm font-medium text-gray-500 hover:text-gray-700"
                                data-tab="templates-tab">
                            <i class="fas fa-file-alt mr-2"></i> Modèles
                        </button>
                      </div>
                      
                    
                    <!-- General Settings Tab -->
                    <div id="general-tab" class="tab-content active p-6">
                        <form action="Settings.jsp" method="post">
                            <input type="hidden" name="action" value="update_general">
                            
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                                <div>
                                    <label for="site_name" class="block text-sm font-medium text-gray-700 mb-1">Nom du site</label>
                                    <input type="text" id="site_name" name="site_name" value="<%= systemSettings.getOrDefault("site_name", "ZAIRTAM") %>" 
                                           class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                                </div>
                                
                                <div>
                                    <label for="site_url" class="block text-sm font-medium text-gray-700 mb-1">URL du site</label>
                                    <input type="url" id="site_url" name="site_url" value="<%= systemSettings.getOrDefault("site_url", "https://zairtam.com") %>" 
                                           class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                                </div>
                                
                                <div>
                                    <label for="admin_email" class="block text-sm font-medium text-gray-700 mb-1">Email administrateur</label>
                                    <input type="email" id="admin_email" name="admin_email" value="<%= systemSettings.getOrDefault("admin_email", "admin@zairtam.com") %>" 
                                           class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                                </div>
                                
                                <div>
                                    <label for="date_format" class="block text-sm font-medium text-gray-700 mb-1">Format de date</label>
                                    <select id="date_format" name="date_format" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                                        <option value="dd/MM/yyyy" <%= systemSettings.getOrDefault("date_format", "dd/MM/yyyy").equals("dd/MM/yyyy") ? "selected" : "" %>>DD/MM/YYYY</option>
                                        <option value="MM/dd/yyyy" <%= systemSettings.getOrDefault("date_format", "dd/MM/yyyy").equals("MM/dd/yyyy") ? "selected" : "" %>>MM/DD/YYYY</option>
                                        <option value="yyyy-MM-dd" <%= systemSettings.getOrDefault("date_format", "dd/MM/yyyy").equals("yyyy-MM-dd") ? "selected" : "" %>>YYYY-MM-DD</option>
                                    </select>
                                </div>
                                
                                <div>
                                    <label for="time_zone" class="block text-sm font-medium text-gray-700 mb-1">Fuseau horaire</label>
                                    <select id="time_zone" name="time_zone" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                                        <option value="UTC" <%= systemSettings.getOrDefault("time_zone", "UTC").equals("UTC") ? "selected" : "" %>>UTC</option>
                                        <option value="Europe/Paris" <%= systemSettings.getOrDefault("time_zone", "UTC").equals("Europe/Paris") ? "selected" : "" %>>Europe/Paris</option>
                                        <option value="America/New_York" <%= systemSettings.getOrDefault("time_zone", "UTC").equals("America/New_York") ? "selected" : "" %>>America/New_York</option>
                                        <option value="Asia/Tokyo" <%= systemSettings.getOrDefault("time_zone", "UTC").equals("Asia/Tokyo") ? "selected" : "" %>>Asia/Tokyo</option>
                                    </select>
                                </div>
                                
                                <div>
                                    <label for="default_language" class="block text-sm font-medium text-gray-700 mb-1">Langue par défaut</label>
                                    <select id="default_language" name="default_language" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                                        <option value="fr" <%= systemSettings.getOrDefault("default_language", "fr").equals("fr") ? "selected" : "" %>>Français</option>
                                        <option value="en" <%= systemSettings.getOrDefault("default_language", "fr").equals("en") ? "selected" : "" %>>English</option>
                                        <option value="es" <%= systemSettings.getOrDefault("default_language", "fr").equals("es") ? "selected" : "" %>>Español</option>
                                        <option value="de" <%= systemSettings.getOrDefault("default_language", "fr").equals("de") ? "selected" : "" %>>Deutsch</option>
                                    </select>
                                </div>
                            </div>
                            
                            <div class="mt-6">
                                <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md">
                                    <i class="fas fa-save mr-2"></i> Enregistrer les modifications
                                </button>
                            </div>
                        </form>
                    </div>
                    
                    <!-- Email Settings Tab -->
                    <div id="email-tab" class="tab-content p-6">
                        <form action="Settings.jsp" method="post">
                            <input type="hidden" name="action" value="update_email">
                            
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                                <div>
                                    <label for="smtp_server" class="block text-sm font-medium text-gray-700 mb-1">Serveur SMTP</label>
                                    <input type="text" id="smtp_server" name="smtp_server" value="<%= systemSettings.getOrDefault("smtp_server", "") %>" class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                                    <p class="mt-1 text-xs text-gray-500">Ex: smtp.gmail.com</p>
                                </div>
                                <div>
                                    <label for="smtp_port" class="block text-sm font-medium text-gray-700 mb-1">Port SMTP</label>
                                    <input type="text" id="smtp_port" name="smtp_port" value="<%= systemSettings.getOrDefault("smtp_port", "587") %>" class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                                    <p class="mt-1 text-xs text-gray-500">Ex: 587 pour TLS, 465 pour SSL</p>
                                </div>
                                <div>
                                    <label for="smtp_username" class="block text-sm font-medium text-gray-700 mb-1">Nom d'utilisateur SMTP</label>
                                    <input type="text" id="smtp_username" name="smtp_username" value="<%= systemSettings.getOrDefault("smtp_username", "") %>" class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                                    <p class="mt-1 text-xs text-gray-500">Généralement votre adresse email</p>
                                </div>
                                <div>
                                    <label for="smtp_password" class="block text-sm font-medium text-gray-700 mb-1">Mot de passe SMTP</label>
                                    <input type="password" id="smtp_password" name="smtp_password" value="<%= systemSettings.getOrDefault("smtp_password", "") %>" class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                                    <p class="mt-1 text-xs text-gray-500">Pour Gmail, utilisez un mot de passe d'application</p>
                                </div>
                                <div>
                                    <label for="smtp_encryption" class="block text-sm font-medium text-gray-700 mb-1">Encryption</label>
                                    <select id="smtp_encryption" name="smtp_encryption" class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                                        <option value="tls" <%= "tls".equals(systemSettings.getOrDefault("smtp_encryption", "tls")) ? "selected" : "" %>>TLS</option>
                                        <option value="ssl" <%= "ssl".equals(systemSettings.getOrDefault("smtp_encryption", "tls")) ? "selected" : "" %>>SSL</option>
                                        <option value="none" <%= "none".equals(systemSettings.getOrDefault("smtp_encryption", "tls")) ? "selected" : "" %>>Aucune</option>
                                    </select>
                                </div>
                            </div>
                            
                            <div class="mt-8">
                                <h3 class="text-lg font-medium text-gray-900 mb-4">Modèles d'emails</h3>
                                <div class="bg-white shadow overflow-hidden rounded-md">
                                    <ul class="divide-y divide-gray-200">
                                        <% for (Map<String, Object> template : emailTemplatesList) { %>
                                        <li class="px-6 py-4 hover:bg-gray-50">
                                            <div class="flex items-center justify-between">
                                                <div>
                                                    <h4 class="text-sm font-medium text-gray-900"><%= template.get("name") %></h4>
                                                    <p class="text-sm text-gray-500">Sujet: <%= template.get("subject") %></p>
                                                </div>
                                                <div>
                                                    <button type="button" class="text-blue-600 hover:text-blue-800 text-sm font-medium">
                                                        Modifier
                                                    </button>
                                                </div>
                                            </div>
                                        </li>
                                        <% } %>
                                    </ul>
                                </div>
                            </div>
                            
                            <div class="mt-6 flex justify-end">
                                <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
                                    Enregistrer les paramètres d'email
                                </button>
                            </div>
                        </form>
                    </div>
                    
                    <!-- Payment Settings Tab -->
                    <div id="payment-tab" class="tab-content p-6">
                        <form action="Settings.jsp" method="post">
                            <input type="hidden" name="action" value="update_payment">
                            
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                                <div>
                                    <label for="currency_code" class="block text-sm font-medium text-gray-700 mb-1">Devise</label>
                                    <select id="currency_code" name="currency_code" class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                                        <option value="EUR" <%= "EUR".equals(systemSettings.getOrDefault("currency_code", "EUR")) ? "selected" : "" %>>Euro (€)</option>
                                        <option value="USD" <%= "USD".equals(systemSettings.getOrDefault("currency_code", "EUR")) ? "selected" : "" %>>Dollar US ($)</option>
                                        <option value="GBP" <%= "GBP".equals(systemSettings.getOrDefault("currency_code", "EUR")) ? "selected" : "" %>>Livre Sterling (£)</option>
                                        <option value="MAD" <%= "MAD".equals(systemSettings.getOrDefault("currency_code", "EUR")) ? "selected" : "" %>>Dirham Marocain (MAD)</option>
                                    </select>
                                </div>
                            </div>
                            
                            <div class="mt-8">
                                <h3 class="text-lg font-medium text-gray-900 mb-4">Passerelles de paiement</h3>
                                
                                <!-- PayPal -->
                                <div class="bg-white shadow overflow-hidden rounded-md mb-6">
                                    <div class="px-6 py-4 border-b">
                                        <div class="flex items-center justify-between">
                                            <div class="flex items-center">
                                                <img src="https://www.paypalobjects.com/webstatic/mktg/logo/pp_cc_mark_37x23.jpg" alt="PayPal" class="h-8">
                                                <h4 class="ml-3 text-lg font-medium text-gray-900">PayPal</h4>
                                            </div>
                                            <div class="flex items-center">
                                                <label class="inline-flex items-center cursor-pointer">
                                                    <input type="checkbox" name="paypal_enabled" class="sr-only peer" <%= "1".equals(systemSettings.getOrDefault("paypal_enabled", "0")) ? "checked" : "" %>>
                                                    <div class="relative w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                                                    <span class="ml-3 text-sm font-medium text-gray-900"><%= "1".equals(systemSettings.getOrDefault("paypal_enabled", "0")) ? "Activé" : "Désactivé" %></span>
                                                </label>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="px-6 py-4">
                                        <div class="mb-4">
                                            <label for="paypal_client_id" class="block text-sm font-medium text-gray-700 mb-1">Client ID</label>
                                            <input type="text" id="paypal_client_id" name="paypal_client_id" value="<%= systemSettings.getOrDefault("paypal_client_id", "") %>" class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                                        </div>
                                    </div>
                                </div>
                                
                                <!-- Stripe -->
                                <div class="bg-white shadow overflow-hidden rounded-md">
                                    <div class="px-6 py-4 border-b">
                                        <div class="flex items-center justify-between">
                                            <div class="flex items-center">
                                                <img src="https://upload.wikimedia.org/wikipedia/commons/b/ba/Stripe_Logo%2C_revised_2016.svg" alt="Stripe" class="h-8">
                                                <h4 class="ml-3 text-lg font-medium text-gray-900">Stripe</h4>
                                            </div>
                                            <div class="flex items-center">
                                                <label class="inline-flex items-center cursor-pointer">
                                                    <input type="checkbox" name="stripe_enabled" class="sr-only peer" <%= "1".equals(systemSettings.getOrDefault("stripe_enabled", "0")) ? "checked" : "" %>>
                                                    <div class="relative w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                                                    <span class="ml-3 text-sm font-medium text-gray-900"><%= "1".equals(systemSettings.getOrDefault("stripe_enabled", "0")) ? "Activé" : "Désactivé" %></span>
                                                </label>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="px-6 py-4">
                                        <div class="mb-4">
                                            <label for="stripe_api_key" class="block text-sm font-medium text-gray-700 mb-1">Clé API</label>
                                            <input type="text" id="stripe_api_key" name="stripe_api_key" value="<%= systemSettings.getOrDefault("stripe_api_key", "") %>" class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                                        </div>
                                    </div>
                                </div>
                            </div>
                            
                            <div class="mt-6 flex justify-end">
                                <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
                                    Enregistrer les paramètres de paiement
                                </button>
                            </div>
                        </form>
                    </div>
                    
                    <!-- API Settings Tab -->
                    <div id="api-tab" class="tab-content p-6">
                        <form action="Settings.jsp" method="post">
                            <input type="hidden" name="action" value="update_api">
                            
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                                <div>
                                    <label for="google_maps_key" class="block text-sm font-medium text-gray-700 mb-1">Clé API Google Maps</label>
                                    <input type="text" id="google_maps_key" name="google_maps_key" value="<%= systemSettings.getOrDefault("google_maps_key", "") %>" class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                                </div>
                                <div>
                                    <label for="weather_api_key" class="block text-sm font-medium text-gray-700 mb-1">Clé API Météo</label>
                                    <input type="text" id="weather_api_key" name="weather_api_key" value="<%= systemSettings.getOrDefault("weather_api_key", "") %>" class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                                </div>
                                <div>
                                    <label for="recaptcha_key" class="block text-sm font-medium text-gray-700 mb-1">Clé reCAPTCHA</label>
                                    <input type="text" id="recaptcha_key" name="recaptcha_key" value="<%= systemSettings.getOrDefault("recaptcha_key", "") %>" class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                                </div>
                            </div>
                            
                            <div class="mt-8">
                                <h3 class="text-lg font-medium text-gray-900 mb-4">Intégrations API</h3>
                                <div class="bg-white shadow overflow-hidden rounded-md">
                                    <ul class="divide-y divide-gray-200">
                                        <% for (Map<String, Object> integration : apiIntegrationsList) { %>
                                        <li class="px-6 py-4 hover:bg-gray-50">
                                            <div class="flex items-center justify-between">
                                                <div>
                                                    <h4 class="text-sm font-medium text-gray-900"><%= integration.get("name") %></h4>
                                                    <p class="text-sm text-gray-500">
                                                        <span class="<%= (Boolean)integration.get("is_active") ? "text-green-600" : "text-red-600" %>">
                                                            <%= (Boolean)integration.get("is_active") ? "Actif" : "Inactif" %>
                                                        </span>
                                                        <% if (integration.get("last_used") != null) { %>
                                                        - Dernière utilisation: <%= new SimpleDateFormat("dd/MM/yyyy HH:mm").format(integration.get("last_used")) %>
                                                        <% } %>
                                                    </p>
                                                </div>
                                                <div>
                                                    <button type="button" class="text-blue-600 hover:text-blue-800 text-sm font-medium">
                                                        Configurer
                                                    </button>
                                                </div>
                                            </div>
                                        </li>
                                        <% } %>
                                    </ul>
                                </div>
                            </div>
                            
                            <div class="mt-6 flex justify-end">
                                <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
                                    Enregistrer les paramètres d'API
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </main>
    </div>
</body>
</html>
<script>
    document.addEventListener('DOMContentLoaded', () => {
    
      /* ---- Sidebar mobile ---- */
      document.getElementById('sidebar-toggle')
              .addEventListener('click', () =>
                  document.getElementById('sidebar').classList.toggle('open')
              );
    
      /* ---- Navigation par onglets ---- */
      const links    = document.querySelectorAll('.tab-link');
      const contents = document.querySelectorAll('.tab-content');
    
      links.forEach(link => {
        link.addEventListener('click', e => {
          e.preventDefault();
    
          /* désactive tout */
          links.forEach(l   => l.classList.remove('active','text-blue-600','border-blue-600'));
          links.forEach(l   => l.classList.add   ('text-gray-500'));
          contents.forEach(c=> c.classList.remove('active'));
    
          /* active l’onglet cliqué */
          link.classList.add('active','text-blue-600','border-b-2','border-blue-600');
          link.classList.remove('text-gray-500');
    
          /* affiche le bloc correspondant */
          const target = document.getElementById(link.dataset.tab);
          if (target) target.classList.add('active');
        });
      });
    
    });
    </script>
    