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
    
    // Define admin variables
    String adminName = "Admin"; // Default value
    String adminImage = ""; // Default empty string
    
    // You might want to get these values from session or database
    // For example:
    // adminName = (String) session.getAttribute("adminName");
    // adminImage = (String) session.getAttribute("adminImage");
    
    // Listes pour stocker les données
    List<Map<String, Object>> faqList = new ArrayList<>();
    List<Map<String, Object>> tutorialsList = new ArrayList<>();
    List<Map<String, Object>> recentTicketsList = new ArrayList<>();
    List<Map<String, Object>> popularTopicsList = new ArrayList<>();
    
    // Statistiques
    int totalFaqs = 0;
    int totalTutorials = 0;
    int totalTickets = 0;
    int resolvedTickets = 0;
    int pendingTickets = 0;
    
    // Données mensuelles pour les graphiques
    List<Integer> monthlyTickets = new ArrayList<>(Arrays.asList(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));
    List<Integer> monthlyResolvedTickets = new ArrayList<>(Arrays.asList(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));
    List<String> months = Arrays.asList("Jan", "Fév", "Mar", "Avr", "Mai", "Juin", "Juil", "Août", "Sep", "Oct", "Nov", "Déc");
    
    // Obtenir le mois et l'année actuels
    Calendar cal = Calendar.getInstance();
    int currentMonth = cal.get(Calendar.MONTH);
    int currentYear = cal.get(Calendar.YEAR);
    
    // Variables pour les messages
    String successMessage = "";
    String errorMessage = "";
    
    // Traitement des actions (création de ticket, réponse, etc.)
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
            if ("create_ticket".equals(action)) {
                // Créer un nouveau ticket
                String subject = request.getParameter("subject");
                String message = request.getParameter("message");
                int userId = Integer.parseInt(request.getParameter("user_id"));
                String priority = request.getParameter("priority");
                
                String insertQuery = "INSERT INTO support_tickets (user_id, subject, message, priority, status, created_at) VALUES (?, ?, ?, ?, 'open', NOW())";
                pstmt = conn.prepareStatement(insertQuery);
                pstmt.setInt(1, userId);
                pstmt.setString(2, subject);
                pstmt.setString(3, message);
                pstmt.setString(4, priority);
                pstmt.executeUpdate();
                
                successMessage = "Ticket créé avec succès.";
            } else if ("reply_ticket".equals(action)) {
                // Répondre à un ticket
                int ticketId = Integer.parseInt(request.getParameter("ticket_id"));
                String reply = request.getParameter("reply");
                int staffId = Integer.parseInt(request.getParameter("staff_id"));
                
                String insertReplyQuery = "INSERT INTO ticket_responses (ticket_id, staff_id, response, created_at) VALUES (?, ?, ?, NOW())";
                pstmt = conn.prepareStatement(insertReplyQuery);
                pstmt.setInt(1, ticketId);
                pstmt.setInt(2, staffId);
                pstmt.setString(3, reply);
                pstmt.executeUpdate();
                
                // Mettre à jour le statut du ticket
                String updateTicketQuery = "UPDATE support_tickets SET status = 'in_progress', updated_at = NOW() WHERE id = ?";
                pstmt = conn.prepareStatement(updateTicketQuery);
                pstmt.setInt(1, ticketId);
                pstmt.executeUpdate();
                
                successMessage = "Réponse ajoutée avec succès.";
            } else if ("close_ticket".equals(action)) {
                // Fermer un ticket
                int ticketId = Integer.parseInt(request.getParameter("ticket_id"));
                
                String updateQuery = "UPDATE support_tickets SET status = 'resolved', resolved_at = NOW(), updated_at = NOW() WHERE id = ?";
                pstmt = conn.prepareStatement(updateQuery);
                pstmt.setInt(1, ticketId);
                pstmt.executeUpdate();
                
                successMessage = "Ticket résolu avec succès.";
            }
        } catch (Exception e) {
            errorMessage = "Erreur lors du traitement de la demande: " + e.getMessage();
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
        // Établir la connexion à la base de données
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(url, username, password);
        
        // Obtenir les statistiques générales
        String statsQuery = "SELECT " +
                           "(SELECT COUNT(*) FROM faqs) as total_faqs, " +
                           "(SELECT COUNT(*) FROM tutorials) as total_tutorials, " +
                           "(SELECT COUNT(*) FROM support_tickets) as total_tickets, " +
                           "(SELECT COUNT(*) FROM support_tickets WHERE status = 'resolved') as resolved_tickets, " +
                           "(SELECT COUNT(*) FROM support_tickets WHERE status = 'open' OR status = 'in_progress') as pending_tickets";
        
        pstmt = conn.prepareStatement(statsQuery);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            totalFaqs = rs.getInt("total_faqs");
            totalTutorials = rs.getInt("total_tutorials");
            totalTickets = rs.getInt("total_tickets");
            resolvedTickets = rs.getInt("resolved_tickets");
            pendingTickets = rs.getInt("pending_tickets");
        }
        
        rs.close();
        pstmt.close();
        
        // Obtenir la liste des FAQs
        String faqQuery = "SELECT id, category, question, answer, views " +
                         "FROM faqs " +
                         "ORDER BY views DESC " +
                         "LIMIT 10";
        
        pstmt = conn.prepareStatement(faqQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> faq = new HashMap<>();
            faq.put("id", rs.getInt("id"));
            faq.put("category", rs.getString("category"));
            faq.put("question", rs.getString("question"));
            faq.put("answer", rs.getString("answer"));
            faq.put("views", rs.getInt("views"));
            
            faqList.add(faq);
        }
        
        rs.close();
        pstmt.close();
        
        // Obtenir la liste des tutoriels
        String tutorialsQuery = "SELECT id, title, description, category, views " +
                               "FROM tutorials " +
                               "ORDER BY views DESC " +
                               "LIMIT 10";
        
        pstmt = conn.prepareStatement(tutorialsQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> tutorial = new HashMap<>();
            tutorial.put("id", rs.getInt("id"));
            tutorial.put("title", rs.getString("title"));
            tutorial.put("description", rs.getString("description"));
            tutorial.put("category", rs.getString("category"));
            tutorial.put("views", rs.getInt("views"));
            
            tutorialsList.add(tutorial);
        }
        
        rs.close();
        pstmt.close();
        
        // Obtenir les tickets récents
        /* tickets récents -------------------------------------------------- */
            String recentTicketsQuery =
                "SELECT t.id,                       " +   // OK (id dans support_tickets)
                "       t.subject, t.status, t.priority, t.created_at, " +
                "       u.first_name, u.last_name, u.email             " +
                "FROM   support_tickets t                              " +
                "JOIN   users u ON t.user_id = u.user_id               " +  // <-- corriger ici
                "ORDER  BY t.created_at DESC                           " +
                "LIMIT  10";

        
        pstmt = conn.prepareStatement(recentTicketsQuery);
        rs = pstmt.executeQuery();
        
        SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy, HH:mm");
        
        while (rs.next()) {
            Map<String, Object> ticket = new HashMap<>();
            ticket.put("id", rs.getInt("id"));
            ticket.put("subject", rs.getString("subject"));
            ticket.put("status", rs.getString("status"));
            ticket.put("priority", rs.getString("priority"));
            ticket.put("created_at", dateFormat.format(rs.getTimestamp("created_at")));
            ticket.put("user_name", rs.getString("first_name") + " " + rs.getString("last_name"));
            ticket.put("user_email", rs.getString("email"));
            
            recentTicketsList.add(ticket);
        }
        
        rs.close();
        pstmt.close();
        
        // Obtenir les sujets populaires
        String popularTopicsQuery = "SELECT category, COUNT(*) as topic_count " +
                                   "FROM (" +
                                   "    SELECT category FROM faqs " +
                                   "    UNION ALL " +
                                   "    SELECT category FROM tutorials" +
                                   ") as all_topics " +
                                   "GROUP BY category " +
                                   "ORDER BY topic_count DESC " +
                                   "LIMIT 10";
        
        pstmt = conn.prepareStatement(popularTopicsQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> topic = new HashMap<>();
            topic.put("category", rs.getString("category"));
            topic.put("count", rs.getInt("topic_count"));
            
            popularTopicsList.add(topic);
        }
        
        rs.close();
        pstmt.close();
        
        // Obtenir les données mensuelles des tickets pour l'année en cours
        String monthlyTicketsQuery = "SELECT MONTH(created_at) as month, " +
                                    "COUNT(*) as ticket_count " +
                                    "FROM support_tickets " +
                                    "WHERE YEAR(created_at) = ? " +
                                    "GROUP BY MONTH(created_at) " +
                                    "ORDER BY month";
        
        pstmt = conn.prepareStatement(monthlyTicketsQuery);
        pstmt.setInt(1, currentYear);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            int month = rs.getInt("month") - 1; // index 0-based
            int ticketCount = rs.getInt("ticket_count");
            monthlyTickets.set(month, ticketCount);
        }
        
        rs.close();
        pstmt.close();
        
        // Obtenir les données mensuelles des tickets résolus pour l'année en cours
        String monthlyResolvedQuery = "SELECT MONTH(resolved_at) as month, " +
                                     "COUNT(*) as resolved_count " +
                                     "FROM support_tickets " +
                                     "WHERE YEAR(resolved_at) = ? " +
                                     "AND status = 'resolved' " +
                                     "GROUP BY MONTH(resolved_at) " +
                                     "ORDER BY month";
        
        pstmt = conn.prepareStatement(monthlyResolvedQuery);
        pstmt.setInt(1, currentYear);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            int month = rs.getInt("month") - 1; // index 0-based
            int resolvedCount = rs.getInt("resolved_count");
            monthlyResolvedTickets.set(month, resolvedCount);
        }
        
    } catch (Exception e) {
        errorMessage = "Erreur lors de la récupération des données: " + e.getMessage();
        e.printStackTrace();
    } finally {
        // Fermer les ressources de la base de données
        try {
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            if (conn != null) conn.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    
    // Convertir les données en JSON pour les graphiques
    StringBuilder monthlyTicketsJson = new StringBuilder("[");
    for (Integer count : monthlyTickets) {
        monthlyTicketsJson.append(count).append(",");
    }
    if (monthlyTicketsJson.charAt(monthlyTicketsJson.length() - 1) == ',') {
        monthlyTicketsJson.setLength(monthlyTicketsJson.length() - 1);
    }
    monthlyTicketsJson.append("]");
    
    StringBuilder monthlyResolvedJson = new StringBuilder("[");
    for (Integer count : monthlyResolvedTickets) {
        monthlyResolvedJson.append(count).append(",");
    }
    if (monthlyResolvedJson.charAt(monthlyResolvedJson.length() - 1) == ',') {
        monthlyResolvedJson.setLength(monthlyResolvedJson.length() - 1);
    }
    monthlyResolvedJson.append("]");
    
    // Données des catégories pour les graphiques
    StringBuilder categoriesJson = new StringBuilder("[");
    StringBuilder categoryCountsJson = new StringBuilder("[");
    
    for (Map<String, Object> topic : popularTopicsList) {
        categoriesJson.append("\"").append(topic.get("category")).append("\",");
        categoryCountsJson.append(topic.get("count")).append(",");
    }
    
    if (categoriesJson.charAt(categoriesJson.length() - 1) == ',') {
        categoriesJson.setLength(categoriesJson.length() - 1);
    }
    categoriesJson.append("]");
    
    if (categoryCountsJson.charAt(categoryCountsJson.length() - 1) == ',') {
        categoryCountsJson.setLength(categoryCountsJson.length() - 1);
    }
    categoryCountsJson.append("]");
%>

<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZAIRTAM - Centre d'Aide</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
        }
        
        .stats-card {
            transition: all 0.3s ease;
        }
        
        .stats-card:hover {
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
        
        .chart-container {
            position: relative;
            height: 300px;
            width: 100%;
        }
        
        .faq-item {
            border-bottom: 1px solid #e5e7eb;
            transition: all 0.3s ease;
        }
        
        .faq-item:hover {
            background-color: #f9fafb;
        }
        
        .ticket-priority-high {
            background-color: #FEE2E2;
            color: #B91C1C;
        }
        
        .ticket-priority-medium {
            background-color: #FEF3C7;
            color: #92400E;
        }
        
        .ticket-priority-low {
            background-color: #DBEAFE;
            color: #1E40AF;
        }
        
        .ticket-status-open {
            background-color: #DBEAFE;
            color: #1E40AF;
        }
        
        .ticket-status-in_progress {
            background-color: #FEF3C7;
            color: #92400E;
        }
        
        .ticket-status-resolved {
            background-color: #D1FAE5;
            color: #065F46;
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
                            <a href="#" class="flex items-center px-3 py-2 text-blue-600 bg-blue-50 rounded-md">
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
        <main class="flex-1 p-4 md:p-6">
            <!-- Page Header -->
            <div class="mb-6">
                <h1 class="text-2xl font-bold text-gray-900">Centre d'Aide</h1>
                <p class="text-gray-600">Gérez les ressources d'aide et les tickets de support</p>
            </div>
            
            <% if (!successMessage.isEmpty()) { %>
            <div class="bg-green-100 border-l-4 border-green-500 text-green-700 p-4 mb-6" role="alert">
                <p><%= successMessage %></p>
            </div>
            <% } %>
            
            <% if (!errorMessage.isEmpty()) { %>
            <div class="bg-red-100 border-l-4 border-red-500 text-red-700 p-4 mb-6" role="alert">
                <p><%= errorMessage %></p>
            </div>
            <% } %>
            
            <!-- Stats Cards -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
                <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                    <div class="flex items-center">
                        <div class="p-3 rounded-full bg-blue-100 text-blue-600">
                            <i class="fas fa-question-circle text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <h3 class="text-sm font-medium text-gray-500">FAQs</h3>
                            <p class="text-2xl font-semibold text-gray-800"><%= totalFaqs %></p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                    <div class="flex items-center">
                        <div class="p-3 rounded-full bg-green-100 text-green-600">
                            <i class="fas fa-book text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <h3 class="text-sm font-medium text-gray-500">Tutoriels</h3>
                            <p class="text-2xl font-semibold text-gray-800"><%= totalTutorials %></p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                    <div class="flex items-center">
                        <div class="p-3 rounded-full bg-yellow-100 text-yellow-600">
                            <i class="fas fa-ticket-alt text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <h3 class="text-sm font-medium text-gray-500">Tickets en attente</h3>
                            <p class="text-2xl font-semibold text-gray-800"><%= pendingTickets %></p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                    <div class="flex items-center">
                        <div class="p-3 rounded-full bg-purple-100 text-purple-600">
                            <i class="fas fa-check-circle text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <h3 class="text-sm font-medium text-gray-500">Tickets résolus</h3>
                            <p class="text-2xl font-semibold text-gray-800"><%= resolvedTickets %></p>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Charts Row -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
                <!-- Monthly Tickets Chart -->
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <h2 class="text-lg font-semibold text-gray-800 mb-4">Tickets mensuels</h2>
                    <div class="chart-container">
                        <canvas id="monthlyTicketsChart"></canvas>
                    </div>
                </div>
                
                <!-- Popular Topics Chart -->
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <h2 class="text-lg font-semibold text-gray-800 mb-4">Sujets populaires</h2>
                    <div class="chart-container">
                        <canvas id="popularTopicsChart"></canvas>
                    </div>
                </div>
            </div>
            
            <!-- Content Sections -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
                <!-- FAQs Section -->
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex justify-between items-center mb-4">
                        <h2 class="text-lg font-semibold text-gray-800">FAQs populaires</h2>
                        <a href="#" class="text-blue-600 hover:text-blue-800 text-sm font-medium" data-modal-target="add-faq-modal">
                            <i class="fas fa-plus mr-1"></i> Ajouter FAQ
                        </a>
                    </div>
                    
                    <div class="mt-4">
                        <% if (faqList.isEmpty()) { %>
                            <p class="text-gray-500 text-center py-4">Aucune FAQ trouvée</p>
                        <% } else { %>
                            <div class="space-y-4">
                                <% for (Map<String, Object> faq : faqList) { %>
                                    <div class="faq-item p-4 rounded-md">
                                        <div class="flex justify-between items-start">
                                            <div>
                                                <h3 class="text-md font-medium text-gray-900"><%= faq.get("question") %></h3>
                                                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 mt-2">
                                                    <%= faq.get("category") %>
                                                </span>
                                                <p class="mt-2 text-sm text-gray-600"><%= faq.get("answer") %></p>
                                            </div>
                                            <div class="flex space-x-2">
                                                <button class="text-gray-400 hover:text-blue-600" title="Modifier">
                                                    <i class="fas fa-edit"></i>
                                                </button>
                                                <button class="text-gray-400 hover:text-red-600" title="Supprimer">
                                                    <i class="fas fa-trash-alt"></i>
                                                </button>
                                            </div>
                                        </div>
                                        <div class="mt-2 text-xs text-gray-500 flex items-center">
                                            <i class="fas fa-eye mr-1"></i> <%= faq.get("views") %> vues
                                        </div>
                                    </div>
                                <% } %>
                            </div>
                        <% } %>
                    </div>
                </div>
                
                <!-- Tutorials Section -->
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex justify-between items-center mb-4">
                        <h2 class="text-lg font-semibold text-gray-800">Tutoriels populaires</h2>
                        <a href="#" class="text-blue-600 hover:text-blue-800 text-sm font-medium" data-modal-target="add-tutorial-modal">
                            <i class="fas fa-plus mr-1"></i> Ajouter tutoriel
                        </a>
                    </div>
                    
                    <div class="mt-4">
                        <% if (tutorialsList.isEmpty()) { %>
                            <p class="text-gray-500 text-center py-4">Aucun tutoriel trouvé</p>
                        <% } else { %>
                            <div class="space-y-4">
                                <% for (Map<String, Object> tutorial : tutorialsList) { %>
                                    <div class="border border-gray-200 rounded-md p-4 hover:bg-gray-50 transition-colors">
                                        <div class="flex justify-between items-start">
                                            <div>
                                                <h3 class="text-md font-medium text-gray-900"><%= tutorial.get("title") %></h3>
                                                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 mt-2">
                                                    <%= tutorial.get("category") %>
                                                </span>
                                                <p class="mt-2 text-sm text-gray-600 line-clamp-2"><%= tutorial.get("description") %></p>
                                            </div>
                                            <div class="flex space-x-2">
                                                <button class="text-gray-400 hover:text-blue-600" title="Modifier">
                                                    <i class="fas fa-edit"></i>
                                                </button>
                                                <button class="text-gray-400 hover:text-red-600" title="Supprimer">
                                                    <i class="fas fa-trash-alt"></i>
                                                </button>
                                            </div>
                                        </div>
                                        <div class="mt-2 text-xs text-gray-500 flex items-center">
                                            <i class="fas fa-eye mr-1"></i> <%= tutorial.get("views") %> vues
                                        </div>
                                    </div>
                                <% } %>
                            </div>
                        <% } %>
                    </div>
                </div>
            </div>
            
            <!-- Support Tickets Section -->
            <div class="bg-white rounded-lg shadow-sm p-6 mb-6">
                <div class="flex justify-between items-center mb-4">
                    <h2 class="text-lg font-semibold text-gray-800">Tickets de support récents</h2>
                    <a href="#" class="text-blue-600 hover:text-blue-800 text-sm font-medium" data-modal-target="create-ticket-modal">
                        <i class="fas fa-plus mr-1"></i> Créer un ticket
                    </a>
                </div>
                
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Sujet</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Utilisateur</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Priorité</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Statut</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                                <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            <% if (recentTicketsList.isEmpty()) { %>
                                <tr>
                                    <td colspan="7" class="px-6 py-4 text-center text-sm text-gray-500">
                                        Aucun ticket trouvé
                                    </td>
                                </tr>
                            <% } else { %>
                                <% for (Map<String, Object> ticket : recentTicketsList) { %>
                                    <tr>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                            #<%= ticket.get("id") %>
                                        </td>
                                        <td class="px-6 py-4 text-sm text-gray-900">
                                            <%= ticket.get("subject") %>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                            <div class="flex items-center">
                                                <div class="flex-shrink-0 h-8 w-8 bg-gray-200 rounded-full flex items-center justify-center">
                                                    <span class="text-xs font-medium text-gray-500">
                                                        <%= ((String)ticket.get("user_name")).substring(0, 1) %>
                                                    </span>
                                                </div>
                                                <div class="ml-3">
                                                    <p class="text-sm font-medium text-gray-900"><%= ticket.get("user_name") %></p>
                                                    <p class="text-xs text-gray-500"><%= ticket.get("user_email") %></p>
                                                </div>
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full ticket-priority-<%= ticket.get("priority") %>">
                                                <%= ticket.get("priority") %>
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full ticket-status-<%= ticket.get("status") %>">
                                                <%= "open".equals(ticket.get("status")) ? "Ouvert" : 
                                                   "in_progress".equals(ticket.get("status")) ? "En cours" : "Résolu" %>
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                            <%= ticket.get("created_at") %>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                            <a href="#" class="text-blue-600 hover:text-blue-900 mr-3" data-ticket-id="<%= ticket.get("id") %>" data-modal-target="view-ticket-modal">
                                                Voir
                                            </a>
                                            <a href="#" class="text-blue-600 hover:text-blue-900" data-ticket-id="<%= ticket.get("id") %>" data-modal-target="reply-ticket-modal">
                                                Répondre
                                            </a>
                                        </td>
                                    </tr>
                                <% } %>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
            
            <!-- Stats Grid -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
                <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                    <div class="flex items-center">
                        <div class="p-3 rounded-full bg-blue-100 text-blue-600">
                            <i class="fas fa-question-circle text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <p class="text-sm font-medium text-gray-500">Total FAQs</p>
                            <p class="text-2xl font-semibold text-gray-900"><%= totalFaqs %></p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                    <div class="flex items-center">
                        <div class="p-3 rounded-full bg-green-100 text-green-600">
                            <i class="fas fa-book text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <p class="text-sm font-medium text-gray-500">Total Tutoriels</p>
                            <p class="text-2xl font-semibold text-gray-900"><%= totalTutorials %></p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                    <div class="flex items-center">
                        <div class="p-3 rounded-full bg-yellow-100 text-yellow-600">
                            <i class="fas fa-ticket-alt text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <p class="text-sm font-medium text-gray-500">Tickets en attente</p>
                            <p class="text-2xl font-semibold text-gray-900"><%= pendingTickets %></p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                    <div class="flex items-center">
                        <div class="p-3 rounded-full bg-purple-100 text-purple-600">
                            <i class="fas fa-check-circle text-xl"></i>
                        </div>
                        <div class="ml-4">
                            <p class="text-sm font-medium text-gray-500">Tickets résolus</p>
                            <p class="text-2xl font-semibold text-gray-900"><%= resolvedTickets %></p>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Charts Section -->
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <h2 class="text-lg font-semibold text-gray-800 mb-4">Tendance mensuelle des tickets</h2>
                    <div class="chart-container">
                        <canvas id="ticketsChart"></canvas>
                    </div>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <h2 class="text-lg font-semibold text-gray-800 mb-4">Catégories populaires</h2>
                    <div class="chart-container">
                        <canvas id="categoriesChart"></canvas>
                    </div>
                </div>
            </div>
        </div>
    </main>
</div>

<!-- Add FAQ Modal -->
<div id="add-faq-modal" class="fixed inset-0 z-50 hidden overflow-y-auto">
    <div class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 transition-opacity" aria-hidden="true">
            <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
        </div>
        <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>
        <div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
            <form action="Help-Center.jsp" method="post">
                <input type="hidden" name="action" value="add_faq">
                <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                    <div class="sm:flex sm:items-start">
                        <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left w-full">
                            <h3 class="text-lg leading-6 font-medium text-gray-900">Ajouter une nouvelle FAQ</h3>
                            <div class="mt-4 space-y-4">
                                <div>
                                    <label for="category" class="block text-sm font-medium text-gray-700">Catégorie</label>
                                    <select id="category" name="category" class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md">
                                        <option value="Réservation">Réservation</option>
                                        <option value="Paiement">Paiement</option>
                                        <option value="Compte">Compte</option>
                                        <option value="Hôtels">Hôtels</option>
                                        <option value="Autre">Autre</option>
                                    </select>
                                </div>
                                <div>
                                    <label for="question" class="block text-sm font-medium text-gray-700">Question</label>
                                    <input type="text" name="question" id="question" class="mt-1 focus:ring-blue-500 focus:border-blue-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md">
                                </div>
                                <div>
                                    <label for="answer" class="block text-sm font-medium text-gray-700">Réponse</label>
                                    <textarea id="answer" name="answer" rows="4" class="mt-1 focus:ring-blue-500 focus:border-blue-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"></textarea>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                    <button type="submit" class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:ml-3 sm:w-auto sm:text-sm">
                        Ajouter
                    </button>
                    <button type="button" class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm modal-close">
                        Annuler
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Add Tutorial Modal -->
<div id="add-tutorial-modal" class="fixed inset-0 z-50 hidden overflow-y-auto">
    <div class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 transition-opacity" aria-hidden="true">
            <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
        </div>
        <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>
        <div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
            <form action="Help-Center.jsp" method="post">
                <input type="hidden" name="action" value="add_tutorial">
                <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                    <div class="sm:flex sm:items-start">
                        <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left w-full">
                            <h3 class="text-lg leading-6 font-medium text-gray-900">Ajouter un nouveau tutoriel</h3>
                            <div class="mt-4 space-y-4">
                                <div>
                                    <label for="tutorial_category" class="block text-sm font-medium text-gray-700">Catégorie</label>
                                    <select id="tutorial_category" name="category" class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md">
                                        <option value="Débutant">Débutant</option>
                                        <option value="Intermédiaire">Intermédiaire</option>
                                        <option value="Avancé">Avancé</option>
                                        <option value="Guide">Guide</option>
                                    </select>
                                </div>
                                <div>
                                    <label for="title" class="block text-sm font-medium text-gray-700">Titre</label>
                                    <input type="text" name="title" id="title" class="mt-1 focus:ring-blue-500 focus:border-blue-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md">
                                </div>
                                <div>
                                    <label for="description" class="block text-sm font-medium text-gray-700">Description</label>
                                    <textarea id="description" name="description" rows="4" class="mt-1 focus:ring-blue-500 focus:border-blue-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"></textarea>
                                </div>
                                <div>
                                    <label for="content" class="block text-sm font-medium text-gray-700">Contenu</label>
                                    <textarea id="content" name="content" rows="6" class="mt-1 focus:ring-blue-500 focus:border-blue-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"></textarea>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                    <button type="submit" class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:ml-3 sm:w-auto sm:text-sm">
                        Ajouter
                    </button>
                    <button type="button" class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm modal-close">
                        Annuler
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Create Ticket Modal -->
<div id="create-ticket-modal" class="fixed inset-0 z-50 hidden overflow-y-auto">
    <div class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 transition-opacity" aria-hidden="true">
            <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
        </div>
        <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>
        <div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
            <form action="Help-Center.jsp" method="post">
                <input type="hidden" name="action" value="create_ticket">
                <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                    <div class="sm:flex sm:items-start">
                        <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left w-full">
                            <h3 class="text-lg leading-6 font-medium text-gray-900">Créer un nouveau ticket</h3>
                            <div class="mt-4 space-y-4">
                                <div>
                                    <label for="user_id" class="block text-sm font-medium text-gray-700">Utilisateur</label>
                                    <select id="user_id" name="user_id" class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md">
                                        <% 
                                        try {
                                            // Établir la connexion à la base de données
                                            Class.forName("com.mysql.cj.jdbc.Driver");
                                            conn = DriverManager.getConnection(url, username, password);
                                            
                                            // Obtenir tous les utilisateurs
                                            String usersQuery = "SELECT id, first_name, last_name, email FROM users ORDER BY first_name, last_name";
                                            pstmt = conn.prepareStatement(usersQuery);
                                            rs = pstmt.executeQuery();
                                            
                                            while (rs.next()) {
                                                int userId = rs.getInt("id");
                                                String userName = rs.getString("first_name") + " " + rs.getString("last_name");
                                                String userEmail = rs.getString("email");
                                        %>
                                            <option value="<%= userId %>"><%= userName %> (<%= userEmail %>)</option>
                                        <% 
                                            }
                                        } catch (Exception e) {
                                            e.printStackTrace();
                                        } finally {
                                            try {
                                                if (rs != null) rs.close();
                                                if (pstmt != null) pstmt.close();
                                                if (conn != null) conn.close();
                                            } catch (SQLException e) {
                                                e.printStackTrace();
                                            }
                                        }
                                        %>
                                    </select>
                                </div>
                                <div>
                                    <label for="subject" class="block text-sm font-medium text-gray-700">Sujet</label>
                                    <input type="text" name="subject" id="subject" class="mt-1 focus:ring-blue-500 focus:border-blue-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md">
                                </div>
                                <div>
                                    <label for="message" class="block text-sm font-medium text-gray-700">Message</label>
                                    <textarea id="message" name="message" rows="4" class="mt-1 focus:ring-blue-500 focus:border-blue-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"></textarea>
                                </div>
                                <div>
                                    <label for="priority" class="block text-sm font-medium text-gray-700">Priorité</label>
                                    <select id="priority" name="priority" class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md">
                                        <option value="low">Basse</option>
                                        <option value="medium">Moyenne</option>
                                        <option value="high">Haute</option>
                                    </select>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                    <button type="submit" class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:ml-3 sm:w-auto sm:text-sm">
                        Créer
                    </button>
                    <button type="button" class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm modal-close">
                        Annuler
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
    // Toggle sidebar on mobile
    document.getElementById('sidebar-toggle').addEventListener('click', function() {
        document.getElementById('sidebar').classList.toggle('open');
    });
    
    // Modal functionality
    document.addEventListener('DOMContentLoaded', function() {
        // Open modals
        const modalTriggers = document.querySelectorAll('[data-modal-target]');
        modalTriggers.forEach(trigger => {
            trigger.addEventListener('click', function(e) {
                e.preventDefault();
                const modalId = this.getAttribute('data-modal-target');
                document.getElementById(modalId).classList.remove('hidden');
            });
        });
        
        // Close modals
        const closeButtons = document.querySelectorAll('.modal-close');
        closeButtons.forEach(button => {
            button.addEventListener('click', function() {
                const modal = this.closest('[id$="-modal"]');
                modal.classList.add('hidden');
            });
        });
        
        // Close modals when clicking outside
        window.addEventListener('click', function(event) {
            document.querySelectorAll('[id$="-modal"]').forEach(modal => {
                if (event.target === modal) {
                    modal.classList.add('hidden');
                }
            });
        });
        
        // FAQ accordion functionality
        const faqItems = document.querySelectorAll('.faq-item');
        faqItems.forEach(item => {
            const question = item.querySelector('.faq-question');
            const answer = item.querySelector('.faq-answer');
            
            question.addEventListener('click', function() {
                const isOpen = answer.classList.contains('block');
                
                // Close all other answers
                document.querySelectorAll('.faq-answer').forEach(el => {
                    el.classList.remove('block');
                    el.classList.add('hidden');
                });
                
                document.querySelectorAll('.faq-icon').forEach(icon => {
                    icon.classList.remove('fa-minus');
                    icon.classList.add('fa-plus');
                });
                
                // Toggle current answer
                if (isOpen) {
                    answer.classList.remove('block');
                    answer.classList.add('hidden');
                    item.querySelector('.faq-icon').classList.remove('fa-minus');
                    item.querySelector('.faq-icon').classList.add('fa-plus');
                } else {
                    answer.classList.remove('hidden');
                    answer.classList.add('block');
                    item.querySelector('.faq-icon').classList.remove('fa-plus');
                    item.querySelector('.faq-icon').classList.add('fa-minus');
                }
            });
        });
    });
    
    // Charts
    const monthlyCtx = document.getElementById('monthlyChart').getContext('2d');
    const monthlyChart = new Chart(monthlyCtx, {
        type: 'line',
        data: {
            labels: <%= Arrays.toString(months.toArray()) %>,
            datasets: [
                {
                    label: 'Tickets créés',
                    data: <%= monthlyTicketsJson.toString() %>,
                    backgroundColor: 'rgba(59, 130, 246, 0.2)',
                    borderColor: 'rgba(59, 130, 246, 1)',
                    borderWidth: 2,
                    tension: 0.3,
                    pointBackgroundColor: 'rgba(59, 130, 246, 1)',
                    pointRadius: 4
                },
                {
                    label: 'Tickets résolus',
                    data: <%= monthlyResolvedJson.toString() %>,
                    backgroundColor: 'rgba(16, 185, 129, 0.2)',
                    borderColor: 'rgba(16, 185, 129, 1)',
                    borderWidth: 2,
                    tension: 0.3,
                    pointBackgroundColor: 'rgba(16, 185, 129, 1)',
                    pointRadius: 4
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        precision: 0
                    }
                }
            }
        }
    });
    
    const categoriesCtx = document.getElementById('categoriesChart').getContext('2d');
    const categoriesChart = new Chart(categoriesCtx, {
        type: 'doughnut',
        data: {
            labels: <%= categoriesJson.toString() %>,
            datasets: [{
                data: <%= categoryCountsJson.toString() %>,
                backgroundColor: [
                    'rgba(59, 130, 246, 0.8)',
                    'rgba(16, 185, 129, 0.8)',
                    'rgba(245, 158, 11, 0.8)',
                    'rgba(239, 68, 68, 0.8)',
                    'rgba(139, 92, 246, 0.8)',
                    'rgba(236, 72, 153, 0.8)',
                    'rgba(75, 85, 99, 0.8)',
                    'rgba(14, 165, 233, 0.8)',
                    'rgba(168, 85, 247, 0.8)',
                    'rgba(234, 179, 8, 0.8)'
                ],
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'right',
                    labels: {
                        boxWidth: 15,
                        padding: 15
                    }
                }
            }
        }
    });
    
    // Form validation
    const ticketForm = document.getElementById('create-ticket-form');
    if (ticketForm) {
        ticketForm.addEventListener('submit', function(e) {
            const subject = document.getElementById('subject').value.trim();
            const message = document.getElementById('message').value.trim();
            
            if (subject === '' || message === '') {
                e.preventDefault();
                alert('Veuillez remplir tous les champs obligatoires.');
            }
        });
    }
</script>
</body>
</html>