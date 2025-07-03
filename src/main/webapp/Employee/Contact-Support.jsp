<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
    // Database connection parameters
    String jdbcURL = "jdbc:mysql://localhost:3306/hotels_db";
    String dbUser = "root";
    String dbPassword = "";
    
    // Initialize connection objects
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // Guest information (would normally come from session)
    String guestName = "";
    String guestEmail = "";
    String guestImage = "https://randomuser.me/api/portraits/men/32.jpg";
    
    // Check if user is logged in
    String userId = (String) session.getAttribute("userId");
    if (userId != null) {
        try {
            // Establish database connection
            Class.forName("com.mysql.jdbc.Driver");
            conn = DriverManager.getConnection(jdbcURL, dbUser, dbPassword);
            
            // Fetch user information
            String userQuery = "SELECT * FROM users WHERE id = ?";
            pstmt = conn.prepareStatement(userQuery);
            pstmt.setString(1, userId);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                guestName = rs.getString("first_name") + " " + rs.getString("last_name");
                guestEmail = rs.getString("email");
                if (rs.getString("profile_image") != null && !rs.getString("profile_image").isEmpty()) {
                    guestImage = rs.getString("profile_image");
                }
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
    }
    
    // Lists to store support categories and user tickets
    List<Map<String, Object>> supportCategoriesList = new ArrayList<>();
    List<Map<String, Object>> userTicketsList = new ArrayList<>();
    
    // Messages for form submission
    String successMessage = "";
    String errorMessage = "";
    
    // Process support ticket submission
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        
        if ("submit_ticket".equals(action)) {
            try {
                // Establish database connection
                Class.forName("com.mysql.jdbc.Driver");
                conn = DriverManager.getConnection(jdbcURL, dbUser, dbPassword);
                
                // Get form data
                String subject = request.getParameter("subject");
                String category = request.getParameter("category");
                String priority = request.getParameter("priority");
                String message = request.getParameter("message");
                
                // Insert ticket into database
                String insertTicketQuery = "INSERT INTO support_tickets (user_id, subject, category, priority, message, status, created_at) " +
                                          "VALUES (?, ?, ?, ?, ?, 'open', NOW())";
                
                pstmt = conn.prepareStatement(insertTicketQuery);
                pstmt.setString(1, userId);
                pstmt.setString(2, subject);
                pstmt.setString(3, category);
                pstmt.setString(4, priority);
                pstmt.setString(5, message);
                
                int rowsAffected = pstmt.executeUpdate();
                
                if (rowsAffected > 0) {
                    // Ticket submission successful
                    successMessage = "Votre ticket de support a été soumis avec succès. Notre équipe vous répondra sous peu.";
                } else {
                    errorMessage = "Échec de la soumission de votre ticket. Veuillez réessayer.";
                }
                
            } catch (Exception e) {
                errorMessage = "Erreur: " + e.getMessage();
                e.printStackTrace();
            }
        }
    }
    
    try {
        // Establish database connection
        Class.forName("com.mysql.jdbc.Driver");
        conn = DriverManager.getConnection(jdbcURL, dbUser, dbPassword);
        
        // Fetch support categories
        String categoriesQuery = "SELECT DISTINCT category FROM faqs ORDER BY category";
        pstmt = conn.prepareStatement(categoriesQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> category = new HashMap<>();
            category.put("name", rs.getString("category"));
            supportCategoriesList.add(category);
        }
        
        // If user is logged in, fetch their support tickets
        if (userId != null) {
            String ticketsQuery = "SELECT * FROM support_tickets WHERE user_id = ? ORDER BY created_at DESC LIMIT 5";
            pstmt = conn.prepareStatement(ticketsQuery);
            pstmt.setString(1, userId);
            rs = pstmt.executeQuery();
            
            while (rs.next()) {
                Map<String, Object> ticket = new HashMap<>();
                ticket.put("id", rs.getInt("id"));
                ticket.put("subject", rs.getString("subject"));
                ticket.put("category", rs.getString("category"));
                ticket.put("priority", rs.getString("priority"));
                ticket.put("status", rs.getString("status"));
                ticket.put("created_at", rs.getTimestamp("created_at"));
                ticket.put("last_updated", rs.getTimestamp("last_updated"));
                userTicketsList.add(ticket);
            }
        }
        
    } catch (Exception e) {
        errorMessage = "Erreur: " + e.getMessage();
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
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZAIRTAM - Contacter le Support</title>
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
        
        .ticket-badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 500;
        }
        
        .ticket-open {
            background-color: #E0F2FE;
            color: #0369A1;
        }
        
        .ticket-in-progress {
            background-color: #FEF3C7;
            color: #92400E;
        }
        
        .ticket-resolved {
            background-color: #ECFDF5;
            color: #065F46;
        }
        
        .ticket-closed {
            background-color: #F3F4F6;
            color: #4B5563;
        }
        
        .priority-badge {
            display: inline-block;
            padding: 0.25rem 0.5rem;
            border-radius: 0.25rem;
            font-size: 0.75rem;
            font-weight: 500;
        }
        
        .priority-low {
            background-color: #ECFDF5;
            color: #065F46;
        }
        
        .priority-medium {
            background-color: #FEF3C7;
            color: #92400E;
        }
        
        .priority-high {
            background-color: #FEE2E2;
            color: #B91C1C;
        }
    </style>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Sidebar toggle for mobile
            const sidebarToggle = document.getElementById('sidebar-toggle');
            const sidebar = document.getElementById('sidebar');
            
            if (sidebarToggle) {
                sidebarToggle.addEventListener('click', function() {
                    sidebar.classList.toggle('open');
                });
            }
            
            // Close sidebar when clicking outside
            document.addEventListener('click', function(event) {
                if (!sidebar.contains(event.target) && !sidebarToggle.contains(event.target) && sidebar.classList.contains('open')) {
                    sidebar.classList.remove('open');
                }
            });
            
            // Form validation
            const supportForm = document.getElementById('supportForm');
            if (supportForm) {
                supportForm.addEventListener('submit', function(event) {
                    const subject = document.getElementById('subject');
                    const message = document.getElementById('message');
                    
                    if (!subject.value.trim()) {
                        event.preventDefault();
                        alert('Veuillez entrer un sujet pour votre ticket');
                        subject.focus();
                        return false;
                    }
                    
                    if (!message.value.trim()) {
                        event.preventDefault();
                        alert('Veuillez entrer un message décrivant votre problème');
                        message.focus();
                        return false;
                    }
                    
                    // Show loading state
                    const submitButton = document.querySelector('button[type="submit"]');
                    if (submitButton) {
                        submitButton.disabled = true;
                        submitButton.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i> Soumission en cours...';
                    }
                    
                    return true;
                });
            }
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
                    <a href="index.jsp" class="flex items-center">
                        <i class="fas fa-hotel text-blue-600 text-2xl mr-2"></i>
                        <span class="text-xl font-bold text-gray-800">ZAIRTAM</span>
                    </a>
                </div>
                
                <!-- Right Nav Items -->
                <div class="flex items-center space-x-4">
                    <% if (userId != null) { %>
                        <a href="Reservations.jsp" class="text-gray-500 hover:text-gray-700">
                            <i class="fas fa-calendar-check text-xl"></i>
                        </a>
                        <div class="relative">
                            <button class="flex items-center text-gray-800 hover:text-blue-600">
                                <img src="<%= guestImage %>" alt="Profile" class="h-8 w-8 rounded-full object-cover">
                                <span class="ml-2 hidden md:block"><%= guestName %></span>
                                <i class="fas fa-chevron-down ml-1 text-xs hidden md:block"></i>
                            </button>
                        </div>
                    <% } else { %>
                        <a href="../login.jsp" class="text-gray-600 hover:text-blue-600">
                            <i class="fas fa-sign-in-alt mr-1"></i> Connexion
                        </a>
                        <a href="../register.jsp" class="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
                            Inscription
                        </a>
                    <% } %>
                </div>
            </div>
        </div>
    </nav>

    <div class="flex">
        <!-- Sidebar -->
        <aside class="bg-white w-64 shadow-sm sidebar" id="sidebar">
            <div class="p-4">
                <div class="mb-6">
                    <h2 class="text-lg font-semibold text-gray-900">Catégories d'aide</h2>
                    <nav class="mt-3 space-y-1">
                        <a href="Help-Center.jsp#bookings" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                            <i class="fas fa-calendar-alt w-5 h-5 mr-3 text-gray-400"></i>
                            Réservations
                        </a>
                        <a href="Help-Center.jsp#payments" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                            <i class="fas fa-credit-card w-5 h-5 mr-3 text-gray-400"></i>
                            Paiements & Facturation
                        </a>
                        <a href="Help-Center.jsp#account" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                            <i class="fas fa-user-circle w-5 h-5 mr-3 text-gray-400"></i>
                            Gestion de compte
                        </a>
                        <a href="Help-Center.jsp#rooms" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                            <i class="fas fa-bed w-5 h-5 mr-3 text-gray-400"></i>
                            Informations sur les chambres
                        </a>
                        <a href="Help-Center.jsp#policies" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                            <i class="fas fa-shield-alt w-5 h-5 mr-3 text-gray-400"></i>
                            Politiques & Conditions
                        </a>
                    </nav>
                </div>
                
                <div class="mb-6">
                    <h2 class="text-lg font-semibold text-gray-900">Liens rapides</h2>
                    <div class="mt-3 space-y-2">
                        <a href="Help-Center.jsp" class="block px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                            <i class="fas fa-question-circle mr-2 text-gray-400"></i> Centre d'aide
                        </a>
                        <a href="Contact-Support.jsp" class="block px-3 py-2 text-sm font-medium text-blue-600 bg-blue-50 rounded-md">
                            <i class="fas fa-headset mr-2 text-blue-500"></i> Contacter le support
                        </a>
                        <a href="Profile.jsp" class="block px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                            <i class="fas fa-user mr-2 text-gray-400"></i> Mon profil
                        </a>
                    </div>
                </div>
                
                <div>
                    <h2 class="text-lg font-semibold text-gray-900">Besoin d'aide urgente?</h2>
                    <div class="mt-3">
                        <a href="tel:+33123456789" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                            <i class="fas fa-phone-alt w-5 h-5 mr-3 text-gray-400"></i>
                            +33 1 23 45 67 89
                        </a>
                        <p class="text-xs text-gray-500 mt-1 px-3">Disponible 24/7 pour les urgences</p>
                    </div>
                </div>
            </div>
        </aside>

        <!-- Main Content -->
        <main class="flex-1 p-4 sm:p-6 lg:p-8">
            <div class="max-w-4xl mx-auto">
                <!-- Header -->
                <div class="mb-8">
                    <h1 class="text-2xl font-bold text-gray-900 sm:text-3xl">Contacter le Support</h1>
                    <p class="mt-2 text-gray-600">Besoin d'aide? Notre équipe de support est là pour vous aider à résoudre vos problèmes.</p>
                </div>
                
                <!-- Success/Error Messages -->
                <% if (!successMessage.isEmpty()) { %>
                    <div class="mb-6 p-4 bg-green-50 border border-green-200 text-green-700 rounded-md">
                        <div class="flex">
                            <i class="fas fa-check-circle text-green-500 mt-1 mr-3"></i>
                            <p><%= successMessage %></p>
                        </div>
                    </div>
                <% } %>
                
                <% if (!errorMessage.isEmpty()) { %>
                    <div class="mb-6 p-4 bg-red-50 border border-red-200 text-red-700 rounded-md">
                        <div class="flex">
                            <i class="fas fa-exclamation-circle text-red-500 mt-1 mr-3"></i>
                            <p><%= errorMessage %></p>
                        </div>
                    </div>
                <% } %>
                
                <!-- Contact Options -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
                    <!-- Support Ticket Form -->
                    <div class="bg-white p-6 rounded-lg shadow-sm">
                        <h2 class="text-xl font-semibold text-gray-800 mb-4">Créer un ticket de support</h2>
                        
                        <% if (userId != null) { %>
                            <form id="supportForm" method="post" action="Contact-Support.jsp" class="space-y-4">
                                <input type="hidden" name="action" value="submit_ticket">
                                
                                <div>
                                    <label for="subject" class="block text-sm font-medium text-gray-700 mb-1">Sujet</label>
                                    <input type="text" id="subject" name="subject" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500" placeholder="Résumez votre problème">
                                </div>
                                
                                <div>
                                    <label for="category" class="block text-sm font-medium text-gray-700 mb-1">Catégorie</label>
                                    <select id="category" name="category" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
                                        <% if (!supportCategoriesList.isEmpty()) { %>
                                            <% for (Map<String, Object> category : supportCategoriesList) { %>
                                                <option value="<%= category.get("name") %>"><%= category.get("name") %></option>
                                            <% } %>
                                        <% } else { %>
                                            <option value="Réservations">Réservations</option>
                                            <option value="Paiements">Paiements & Facturation</option>
                                            <option value="Compte">Gestion de compte</option>
                                            <option value="Chambres">Informations sur les chambres</option>
                                            <option value="Politiques">Politiques & Conditions</option>
                                        <% } %>
                                    </select>
                                </div>
                                
                                <div>
                                    <label for="priority" class="block text-sm font-medium text-gray-700 mb-1">Priorité</label>
                                    <select id="priority" name="priority" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
                                        <option value="low">Basse</option>
                                        <option value="medium" selected>Moyenne</option>
                                        <option value="high">Haute</option>
                                    </select>
                                </div>
                                
                                <div>
                                    <label for="message" class="block text-sm font-medium text-gray-700 mb-1">Message</label>
                                    <textarea id="message" name="message" rows="5" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500" placeholder="Décrivez votre problème en détail"></textarea>
                                </div>
                                
                                <div>
                                    <button type="submit" class="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
                                        Soumettre le ticket
                                    </button>
                                </div>
                            </form>
                        <% } else { %>
                            <div class="text-center py-6">
                                <i class="fas fa-lock text-gray-400 text-4xl mb-3"></i>
                                <p class="text-gray-600 mb-4">Veuillez vous connecter pour créer un ticket de support</p>
                                <a href="../login.jsp" class="inline-block bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700">
                                    Se connecter
                                </a>
                            </div>
                        <% } %>
                    </div>
                    
                    <!-- Other Contact Methods -->
                    <div class="space-y-6">
                        <!-- Direct Contact -->
                        <div class="bg-white p-6 rounded-lg shadow-sm">
                            <h2 class="text-xl font-semibold text-gray-800 mb-4">Nous contacter directement</h2>
                            
                            <div class="space-y-4">
                                <div class="flex items-start">
                                    <div class="flex-shrink-0 mt-1">
                                        <i class="fas fa-phone-alt text-blue-500"></i>
                                    </div>
                                    <div class="ml-3">
                                        <p class="text-sm font-medium text-gray-900">Téléphone</p>
                                        <p class="text-sm text-gray-600">+33 1 23 45 67 89</p>
                                        <p class="text-xs text-gray-500">Lun-Ven, 9h-18h</p>
                                    </div>
                                </div>
                                
                                <div class="flex items-start">
                                    <div class="flex-shrink-0 mt-1">
                                        <i class="fas fa-envelope text-blue-500"></i>
                                    </div>
                                    <div class="ml-3">
                                        <p class="text-sm font-medium text-gray-900">Email</p>
                                        <p class="text-sm text-gray-600">support@zairtam.com</p>
                                        <p class="text-xs text-gray-500">Réponse sous 24-48h</p>
                                    </div>
                                </div>
                                
                                <div class="flex items-start">
                                    <div class="flex-shrink-0 mt-1">
                                        <i class="fas fa-comment-dots text-blue-500"></i>
                                    </div>
                                    <div class="ml-3">
                                        <p class="text-sm font-medium text-gray-900">Chat en direct</p>
                                        <p class="text-sm text-gray-600">Disponible sur notre site web</p>
                                        <p class="text-xs text-gray-500">Tous les jours, 9h-22h</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <!-- FAQ Link -->
                        <div class="bg-white p-6 rounded-lg shadow-sm">
                            <h2 class="text-xl font-semibold text-gray-800 mb-4">Consultez notre FAQ</h2>
                            <p class="text-gray-600 mb-4">Trouvez rapidement des réponses à vos questions dans notre centre d'aide.</p>
                            <a href="Help-Center.jsp" class="inline-flex items-center text-blue-600 hover:text-blue-800">
                                Voir la FAQ
                                <i class="fas fa-arrow-right ml-2"></i>
                            </a>
                        </div>
                    </div>
                </div>
                
                <!-- Recent Tickets -->
                <% if (userId != null && !userTicketsList.isEmpty()) { %>
                    <div class="bg-white p-6 rounded-lg shadow-sm mb-8">
                        <h2 class="text-xl font-semibold text-gray-800 mb-4">Vos tickets récents</h2>
                        
                        <div class="overflow-x-auto">
                            <table class="min-w-full divide-y divide-gray-200">
                                <thead class="bg-gray-50">
                                    <tr>
                                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Sujet</th>
                                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Catégorie</th>
                                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Priorité</th>
                                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Statut</th>
                                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                                    </tr>
                                </thead>
                                <tbody class="bg-white divide-y divide-gray-200">
                                    <% for (Map<String, Object> ticket : userTicketsList) { %>
                                        <tr>
                                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">#<%= ticket.get("id") %></td>
                                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900"><%= ticket.get("subject") %></td>
                                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"><%= ticket.get("category") %></td>
                                            <td class="px-6 py-4 whitespace-nowrap">
                                                <% 
                                                String priorityClass = "";
                                                String priorityText = "";
                                                String priority = (String) ticket.get("priority");
                                                
                                                if ("low".equals(priority)) {
                                                    priorityClass = "priority-low";
                                                    priorityText = "Basse";
                                                } else if ("medium".equals(priority)) {
                                                    priorityClass = "priority-medium";
                                                    priorityText = "Moyenne";
                                                } else if ("high".equals(priority)) {
                                                    priorityClass = "priority-high";
                                                    priorityText = "Haute";
                                                }
                                                %>
                                                <span class="priority-badge <%= priorityClass %>"><%= priorityText %></span>
                                            </td>
                                            <td class="px-6 py-4 whitespace-nowrap">
                                                <% 
                                                String statusClass = "";
                                                String statusText = "";
                                                String status = (String) ticket.get("status");
                                                
                                                if ("open".equals(status)) {
                                                    statusClass = "ticket-open";
                                                    statusText = "Ouvert";
                                                } else if ("in_progress".equals(status)) {
                                                    statusClass = "ticket-in-progress";
                                                    statusText = "En cours";
                                                } else if ("resolved".equals(status)) {
                                                    statusClass = "ticket-resolved";
                                                    statusText = "Résolu";
                                                } else if ("closed".equals(status)) {
                                                    statusClass = "ticket-closed";
                                                    statusText = "Fermé";
                                                }
                                                %>
                                                <span class="ticket-badge <%= statusClass %>"><%= statusText %></span>
                                            </td>
                                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                                <% 
                                                SimpleDateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy HH:mm");
                                                String formattedDate = dateFormat.format(ticket.get("created_at"));
                                                %>
                                                <%= formattedDate %>
                                            </td>
                                        </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                        
                        <div class="mt-4 text-right">
                            <a href="Tickets.jsp" class="text-sm font-medium text-blue-600 hover:text-blue-800">
                                Voir tous vos tickets <i class="fas fa-arrow-right ml-1"></i>
                            </a>
                        </div>
                    </div>
                <% } %>
                
                <!-- FAQ Section -->
                <div class="bg-white p-6 rounded-lg shadow-sm">
                    <h2 class="text-xl font-semibold text-gray-800 mb-4">Questions fréquemment posées</h2>
                    
                    <div class="space-y-4">
                        <div class="border border-gray-200 rounded-md overflow-hidden">
                            <button class="flex justify-between items-center w-full px-4 py-3 text-left text-gray-800 font-medium bg-gray-50 hover:bg-gray-100 focus:outline-none">
                                <span>Comment puis-je modifier ma réservation?</span>
                                <i class="fas fa-plus text-gray-500"></i>
                            </button>
                            <div class="px-4 py-3 bg-white text-gray-600 hidden">
                                <p>Pour modifier votre réservation, connectez-vous à votre compte et accédez à la section "Mes réservations". Cliquez sur la réservation que vous souhaitez modifier, puis sur le bouton "Modifier". Vous pourrez alors changer les dates, le type de chambre ou d'autres détails selon les conditions de votre réservation.</p>
                            </div>
                        </div>
                        
                        <div class="border border-gray-200 rounded-md overflow-hidden">
                            <button class="flex justify-between items-center w-full px-4 py-3 text-left text-gray-800 font-medium bg-gray-50 hover:bg-gray-100 focus:outline-none">
                                <span>Quelle est la politique d'annulation?</span>
                                <i class="fas fa-plus text-gray-500"></i>
                            </button>
                            <div class="px-4 py-3 bg-white text-gray-600 hidden">
                                <p>Notre politique d'annulation standard permet une annulation gratuite jusqu'à 48 heures avant l'arrivée. Pour les annulations effectuées moins de 48 heures avant l'arrivée, des frais équivalents à une nuit peuvent être appliqués. Veuillez noter que certaines offres spéciales peuvent avoir des conditions d'annulation différentes.</p>
                            </div>
                        </div>
                        
                        <div class="border border-gray-200 rounded-md overflow-hidden">
                            <button class="flex justify-between items-center w-full px-4 py-3 text-left text-gray-800 font-medium bg-gray-50 hover:bg-gray-100 focus:outline-none">
                                <span>Comment puis-je obtenir une facture pour mon séjour?</span>
                                <i class="fas fa-plus text-gray-500"></i>
                            </button>
                            <div class="px-4 py-3 bg-white text-gray-600 hidden">
                                <p>Les factures sont automatiquement envoyées par email à la fin de votre séjour. Si vous n'avez pas reçu votre facture ou si vous avez besoin d'une facture avant votre départ, vous pouvez la demander à la réception de l'hôtel ou via la section "Mes réservations" de votre compte.</p>
                            </div>
                        </div>
                    </div>
                    
                    <div class="mt-4 text-center">
                        <a href="Help-Center.jsp" class="inline-block px-4 py-2 bg-gray-100 text-gray-800 font-medium rounded-md hover:bg-gray-200">
                            Voir toutes les FAQ <i class="fas fa-arrow-right ml-1"></i>
                        </a>
                    </div>
                </div>
            </div>
        </main>
    </div>
    
    <script>
        // FAQ accordion functionality
        document.addEventListener('DOMContentLoaded', function() {
            const faqButtons = document.querySelectorAll('.border.border-gray-200 button');
            
            faqButtons.forEach(button => {
                button.addEventListener('click', function() {
                    const answer = this.nextElementSibling;
                    const icon = this.querySelector('i');
                    
                    // Toggle answer visibility
                    answer.classList.toggle('hidden');
                    
                    // Toggle icon
                    if (answer.classList.contains('hidden')) {
                        icon.classList.remove('fa-minus');
                        icon.classList.add('fa-plus');
                    } else {
                        icon.classList.remove('fa-plus');
                        icon.classList.add('fa-minus');
                    }
                });
            });
        });
    </script>
</body>
</html>