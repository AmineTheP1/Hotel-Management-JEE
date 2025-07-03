<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    // Paramètres de connexion à la base de données
    String url = "jdbc:mysql://localhost:3306/hotels_db"; // Changez selon votre base de données
    String username = "root"; // Changez selon votre nom d'utilisateur
    String password = ""; // Changez selon votre mot de passe
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // Liste pour stocker les données des administrateurs
    List<Map<String, Object>> adminUsersList = new ArrayList<>();
    
    // Statistiques
    int totalAdmins = 0;
    int activeAdmins = 0;
    int inactiveAdmins = 0;
    
    // Variables pour les messages
    String successMessage = "";
    String errorMessage = "";
    
    // Traitement des actions (ajout, modification, suppression)
    if (request.getMethod().equals("POST")) {
        String action = request.getParameter("action");
        
        try {
            // Établir la connexion à la base de données
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(url, username, password);
            
            if ("add".equals(action)) {
                // Récupérer les données du formulaire
                String firstName = request.getParameter("firstName");
                String lastName = request.getParameter("lastName");
                String email = request.getParameter("email");
                String userPassword = request.getParameter("password");
                String role = request.getParameter("role");
                String status = request.getParameter("status");
                
                // Vérifier si l'email existe déjà
                pstmt = conn.prepareStatement("SELECT COUNT(*) FROM admin_users WHERE email = ?");
                pstmt.setString(1, email);
                rs = pstmt.executeQuery();
                
                if (rs.next() && rs.getInt(1) > 0) {
                    errorMessage = "Un administrateur avec cet email existe déjà.";
                } else {
                    // Insérer le nouvel administrateur
                    pstmt = conn.prepareStatement(
                        "INSERT INTO admin_users (first_name, last_name, email, password, role, status, created_at) " +
                        "VALUES (?, ?, ?, ?, ?, ?, NOW())"
                    );
                    pstmt.setString(1, firstName);
                    pstmt.setString(2, lastName);
                    pstmt.setString(3, email);
                    pstmt.setString(4, userPassword); // En production, utilisez un hachage sécurisé
                    pstmt.setString(5, role);
                    pstmt.setString(6, status);
                    
                    int result = pstmt.executeUpdate();
                    if (result > 0) {
                        successMessage = "Administrateur ajouté avec succès.";
                    } else {
                        errorMessage = "Échec de l'ajout de l'administrateur.";
                    }
                }
            } else if ("update".equals(action)) {
                // Récupérer les données du formulaire
                int adminId = Integer.parseInt(request.getParameter("adminId"));
                String firstName = request.getParameter("firstName");
                String lastName = request.getParameter("lastName");
                String email = request.getParameter("email");
                String role = request.getParameter("role");
                String status = request.getParameter("status");
                
                // Vérifier si l'email existe déjà pour un autre administrateur
                pstmt = conn.prepareStatement("SELECT COUNT(*) FROM admin_users WHERE email = ? AND id != ?");
                pstmt.setString(1, email);
                pstmt.setInt(2, adminId);
                rs = pstmt.executeQuery();
                
                if (rs.next() && rs.getInt(1) > 0) {
                    errorMessage = "Un autre administrateur utilise déjà cet email.";
                } else {
                    // Mettre à jour l'administrateur
                    String updateQuery = "UPDATE admin_users SET first_name = ?, last_name = ?, email = ?, role = ?, status = ?, updated_at = NOW() WHERE id = ?";
                    
                    // Si un nouveau mot de passe est fourni, le mettre à jour également
                    String password = request.getParameter("password");
                    if (password != null && !password.trim().isEmpty()) {
                        updateQuery = "UPDATE admin_users SET first_name = ?, last_name = ?, email = ?, password = ?, role = ?, status = ?, updated_at = NOW() WHERE id = ?";
                    }
                    
                    pstmt = conn.prepareStatement(updateQuery);
                    pstmt.setString(1, firstName);
                    pstmt.setString(2, lastName);
                    pstmt.setString(3, email);
                    
                    if (password != null && !password.trim().isEmpty()) {
                        pstmt.setString(4, password); // En production, utilisez un hachage sécurisé
                        pstmt.setString(5, role);
                        pstmt.setString(6, status);
                        pstmt.setInt(7, adminId);
                    } else {
                        pstmt.setString(4, role);
                        pstmt.setString(5, status);
                        pstmt.setInt(6, adminId);
                    }
                    
                    int result = pstmt.executeUpdate();
                    if (result > 0) {
                        successMessage = "Administrateur mis à jour avec succès.";
                    } else {
                        errorMessage = "Échec de la mise à jour de l'administrateur.";
                    }
                }
            } else if ("delete".equals(action)) {
                // Récupérer l'ID de l'administrateur à supprimer
                int adminId = Integer.parseInt(request.getParameter("adminId"));
                
                // Supprimer l'administrateur
                pstmt = conn.prepareStatement("DELETE FROM admin_users WHERE id = ?");
                pstmt.setInt(1, adminId);
                
                int result = pstmt.executeUpdate();
                if (result > 0) {
                    successMessage = "Administrateur supprimé avec succès.";
                } else {
                    errorMessage = "Échec de la suppression de l'administrateur.";
                }
            }
            
            // Fermer les ressources
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            if (conn != null) conn.close();
        } catch (Exception e) {
            errorMessage = "Erreur: " + e.getMessage();
            e.printStackTrace();
        }
    }
    
    try {
        // Établir la connexion à la base de données
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(url, username, password);
        
        // Obtenir les statistiques des administrateurs
        String statsQuery = "SELECT " +
                           "COUNT(*) as total_admins, " +
                           "SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active_admins, " +
                           "SUM(CASE WHEN status = 'inactive' THEN 1 ELSE 0 END) as inactive_admins " +
                           "FROM admin_users";
        
        pstmt = conn.prepareStatement(statsQuery);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            totalAdmins = rs.getInt("total_admins");
            activeAdmins = rs.getInt("active_admins");
            inactiveAdmins = rs.getInt("inactive_admins");
        }
        
        rs.close();
        pstmt.close();
        
        // Obtenir la liste des administrateurs
        String adminsQuery = "SELECT id, first_name, last_name, email, role, status, created_at, last_login " +
                            "FROM admin_users " +
                            "ORDER BY created_at DESC";
        
        pstmt = conn.prepareStatement(adminsQuery);
        rs = pstmt.executeQuery();
        
        SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy, HH:mm");
        
        while (rs.next()) {
            Map<String, Object> admin = new HashMap<>();
            admin.put("id", rs.getInt("id"));
            admin.put("first_name", rs.getString("first_name"));
            admin.put("last_name", rs.getString("last_name"));
            admin.put("email", rs.getString("email"));
            admin.put("role", rs.getString("role"));
            admin.put("status", rs.getString("status"));
            
            Timestamp createdAt = rs.getTimestamp("created_at");
            if (createdAt != null) {
                admin.put("created_at", dateFormat.format(createdAt));
            } else {
                admin.put("created_at", "N/A");
            }
            
            Timestamp lastLogin = rs.getTimestamp("last_login");
            if (lastLogin != null) {
                admin.put("last_login", dateFormat.format(lastLogin));
            } else {
                admin.put("last_login", "Jamais");
            }
            
            adminUsersList.add(admin);
        }
        
    } catch (Exception e) {
        errorMessage = "Erreur: " + e.getMessage();
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
%>

<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZAIRTAM - Gestion des Administrateurs</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
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
        
        .modal {
            transition: opacity 0.25s ease;
        }
        
        .modal-active {
            overflow-y: visible !important;
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
                        <input type="text" placeholder="Rechercher un administrateur..." class="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
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
                            <img src="https://randomuser.me/api/portraits/women/28.jpg" alt="Profile" class="h-8 w-8 rounded-full object-cover">
                            <span class="ml-2 hidden md:block">Admin Smith</span>
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
                    <h3 class="text-xs uppercase text-gray-500 font-semibold tracking-wider">Principal</h3>
                    <ul class="mt-3 space-y-1">
                        <li>
                            <a href="admin-dashboard.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-tachometer-alt w-5 text-center"></i>
                                <span class="ml-2">Tableau de bord</span>
                            </a>
                        </li>
                        <li>
                            <a href="hotels.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-hotel w-5 text-center"></i>
                                <span class="ml-2">Hôtels</span>
                            </a>
                        </li>
                        <li>
                            <a href="users.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-users w-5 text-center"></i>
                                <span class="ml-2">Utilisateurs</span>
                            </a>
                        </li>
                        <li>
                            <a href="bookings.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-calendar-alt w-5 text-center"></i>
                                <span class="ml-2">Réservations</span>
                            </a>
                        </li>
                        <li>
                            <a href="AdminUsers.jsp" class="flex items-center px-3 py-2 text-blue-600 bg-blue-50 rounded-md">
                                <i class="fas fa-user-shield w-5 text-center"></i>
                                <span class="ml-2">Administrateurs</span>
                            </a>
                        </li>
                    </ul>
                </div>
                
                <div class="mb-6">
                    <h3 class="text-xs uppercase text-gray-500 font-semibold tracking-wider">Analytique</h3>
                    <ul class="mt-3 space-y-1">
                        <li>
                            <a href="Reports.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-chart-line w-5 text-center"></i>
                                <span class="ml-2">Rapports</span>
                            </a>
                        </li>
                        <li>
                            <a href="Revenue.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-money-bill-wave w-5 text-center"></i>
                                <span class="ml-2">Revenus</span>
                            </a>
                        </li>
                        <li>
                            <a href="Statistiques.jsp" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-chart-pie w-5 text-center"></i>
                                <span class="ml-2">Statistiques</span>
                            </a>
                        </li>
                    </ul>
                </div>
                
                <div class="mb-6">
                    <h3 class="text-xs uppercase text-gray-500 font-semibold tracking-wider">Paramètres</h3>
                    <ul class="mt-3 space-y-1">
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-cog w-5 text-center"></i>
                                <span class="ml-2">Général</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-lock w-5 text-center"></i>
                                <span class="ml-2">Sécurité</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-sign-out-alt w-5 text-center"></i>
                                <span class="ml-2">Déconnexion</span>
                            </a>
                        </li>
                    </ul>
                </div>
            </div>
        </aside>

        <!-- Main Content -->
        <main class="flex-1 p-4 lg:p-8">
            <div class="max-w-7xl mx-auto">
                <!-- Page Header -->
                <div class="flex flex-col md:flex-row md:items-center md:justify-between mb-8">
                    <div>
                        <h1 class="text-2xl font-bold text-gray-900">Gestion des Administrateurs</h1>
                        <p class="mt-1 text-sm text-gray-600">Gérez les comptes administrateurs du système</p>
                    </div>
                    <div class="mt-4 md:mt-0">
                        <button id="add-admin-btn" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg flex items-center">
                            <i class="fas fa-plus mr-2"></i>
                            Ajouter un administrateur
                        </button>
                    </div>
                </div>
                
                <!-- Messages de notification -->
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
                
                <!-- Statistics Cards -->
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                    <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                        <div class="flex items-center">
                            <div class="p-3 rounded-full bg-blue-100 text-blue-600">
                                <i class="fas fa-users text-xl"></i>
                            </div>
                            <div class="ml-4">
                                <h2 class="text-sm font-medium text-gray-600">Total Administrateurs</h2>
                                <p class="text-2xl font-bold text-gray-900"><%= totalAdmins %></p>
                            </div>
                        </div>
                    </div>
                    
                    <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                        <div class="flex items-center">
                            <div class="p-3 rounded-full bg-green-100 text-green-600">
                                <i class="fas fa-user-check text-xl"></i>
                            </div>
                            <div class="ml-4">
                                <h2 class="text-sm font-medium text-gray-600">Administrateurs Actifs</h2>
                                <p class="text-2xl font-bold text-gray-900"><%= activeAdmins %></p>
                            </div>
                        </div>
                    </div>
                    
                    <div class="bg-white rounded-lg shadow-sm p-6 stats-card">
                        <div class="flex items-center">
                            <div class="p-3 rounded-full bg-red-100 text-red-600">
                                <i class="fas fa-user-times text-xl"></i>
                            </div>
                            <div class="ml-4">
                                <h2 class="text-sm font-medium text-gray-600">Administrateurs Inactifs</h2>
                                <p class="text-2xl font-bold text-gray-900"><%= inactiveAdmins %></p>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Admin Users Table -->
                <div class="bg-white rounded-lg shadow-sm overflow-hidden mb-8">
                    <div class="px-6 py-4 border-b border-gray-200 bg-gray-50">
                        <h3 class="text-lg font-medium text-gray-900">Liste des Administrateurs</h3>
                    </div>
                    
                    <div class="overflow-x-auto">
                        <table class="min-w-full divide-y divide-gray-200">
                            <thead class="bg-gray-50">
                                <tr>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Nom</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Rôle</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Statut</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date de création</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Dernière connexion</th>
                                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                                </tr>
                            </thead>
                            <tbody class="bg-white divide-y divide-gray-200">
                                <% if (adminUsersList.isEmpty()) { %>
                                <tr>
                                    <td colspan="8" class="px-6 py-4 text-center text-sm text-gray-500">
                                        Aucun administrateur trouvé
                                    </td>
                                </tr>
                                <% } else { %>
                                    <% for (Map<String, Object> admin : adminUsersList) { %>
                                    <tr>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                            <%= admin.get("id") %>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div class="flex items-center">
                                                <div class="flex-shrink-0 h-10 w-10">
                                                    <div class="h-10 w-10 rounded-full bg-gray-200 flex items-center justify-center text-gray-600">
                                                        <i class="fas fa-user"></i>
                                                    </div>
                                                </div>
                                                <div class="ml-4">
                                                    <div class="text-sm font-medium text-gray-900">
                                                        <%= admin.get("first_name") %> <%= admin.get("last_name") %>
                                                    </div>
                                                </div>
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                            <%= admin.get("email") %>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                            <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800">
                                                <%= admin.get("role") %>
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                            <% if (admin.get("status").equals("active")) { %>
                                                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                                                    Actif
                                                </span>
                                            <% } else { %>
                                                <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800">
                                                    Inactif
                                                </span>
                                            <% } %>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                            <%= admin.get("created_at") %>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                            <%= admin.get("last_login") %>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                            <div class="flex space-x-2">
                                                <button class="edit-admin-btn text-blue-600 hover:text-blue-900" 
                                                        data-id="<%= admin.get("id") %>"
                                                        data-firstname="<%= admin.get("first_name") %>"
                                                        data-lastname="<%= admin.get("last_name") %>"
                                                        data-email="<%= admin.get("email") %>"
                                                        data-role="<%= admin.get("role") %>"
                                                        data-status="<%= admin.get("status") %>">
                                                    <i class="fas fa-edit"></i>
                                                </button>
                                                <button class="delete-admin-btn text-red-600 hover:text-red-900"
                                                        data-id="<%= admin.get("id") %>"
                                                        data-name="<%= admin.get("first_name") %> <%= admin.get("last_name") %>">
                                                    <i class="fas fa-trash-alt"></i>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                    <% } %>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                    
                    <div class="px-6 py-4 border-t border-gray-200 bg-gray-50 flex items-center justify-between">
                        <div class="text-sm text-gray-600">
                            Affichage de <span class="font-medium"><%= adminUsersList.size() %></span> administrateurs
                        </div>
                        <div class="flex space-x-2">
                            <button class="px-3 py-1 text-sm text-gray-500 bg-white border rounded-md hover:bg-gray-100 disabled:opacity-50" disabled>
                                <i class="fas fa-chevron-left mr-1"></i> Précédent
                            </button>
                            <button class="px-3 py-1 text-sm text-gray-500 bg-white border rounded-md hover:bg-gray-100 disabled:opacity-50" disabled>
                                Suivant <i class="fas fa-chevron-right ml-1"></i>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    </div>
    
    <!-- Modal Ajout Administrateur -->
    <div id="add-admin-modal" class="modal fixed inset-0 bg-gray-900 bg-opacity-50 z-50 flex items-center justify-center hidden">
        <div class="bg-white rounded-lg shadow-xl max-w-md w-full mx-4 overflow-hidden">
            <div class="px-6 py-4 border-b flex justify-between items-center">
                <h3 class="text-lg font-semibold text-gray-900">Ajouter un administrateur</h3>
                <button class="modal-close text-gray-400 hover:text-gray-500">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <form action="AdminUsers.jsp" method="post">
                <input type="hidden" name="action" value="add">
                <div class="p-6 space-y-4">
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label for="firstName" class="block text-sm font-medium text-gray-700 mb-1">Prénom</label>
                            <input type="text" id="firstName" name="firstName" required class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                        </div>
                        <div>
                            <label for="lastName" class="block text-sm font-medium text-gray-700 mb-1">Nom</label>
                            <input type="text" id="lastName" name="lastName" required class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                        </div>
                    </div>
                    <div>
                        <label for="email" class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                        <input type="email" id="email" name="email" required class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                    </div>
                    <div>
                        <label for="password" class="block text-sm font-medium text-gray-700 mb-1">Mot de passe</label>
                        <input type="password" id="password" name="password" required class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                    </div>
                    <div>
                        <label for="role" class="block text-sm font-medium text-gray-700 mb-1">Rôle</label>
                        <select id="role" name="role" required class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                            <option value="admin">Administrateur</option>
                            <option value="manager">Gestionnaire</option>
                            <option value="editor">Éditeur</option>
                        </select>
                    </div>
                    <div>
                        <label for="status" class="block text-sm font-medium text-gray-700 mb-1">Statut</label>
                        <select id="status" name="status" required class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                            <option value="active">Actif</option>
                            <option value="inactive">Inactif</option>
                        </select>
                    </div>
                </div>
                <div class="px-6 py-4 bg-gray-50 flex justify-end space-x-3">
                    <button type="button" class="modal-close px-4 py-2 text-sm font-medium text-gray-700 bg-white border rounded-md hover:bg-gray-50">
                        Annuler
                    </button>
                    <button type="submit" class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700">
                        Ajouter
                    </button>
                </div>
            </form>
        </div>
    </div>
    
    <!-- Modal Modification Administrateur -->
    <div id="edit-admin-modal" class="modal fixed inset-0 bg-gray-900 bg-opacity-50 z-50 flex items-center justify-center hidden">
        <div class="bg-white rounded-lg shadow-xl max-w-md w-full mx-4 overflow-hidden">
            <div class="px-6 py-4 border-b flex justify-between items-center">
                <h3 class="text-lg font-semibold text-gray-900">Modifier un administrateur</h3>
                <button class="modal-close text-gray-400 hover:text-gray-500">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <form action="AdminUsers.jsp" method="post">
                <input type="hidden" name="action" value="update">
                <input type="hidden" id="edit-adminId" name="adminId" value="">
                <div class="p-6 space-y-4">
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label for="edit-firstName" class="block text-sm font-medium text-gray-700 mb-1">Prénom</label>
                            <input type="text" id="edit-firstName" name="firstName" required class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                        </div>
                        <div>
                            <label for="edit-lastName" class="block text-sm font-medium text-gray-700 mb-1">Nom</label>
                            <input type="text" id="edit-lastName" name="lastName" required class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                        </div>
                    </div>
                    <div>
                        <label for="edit-email" class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                        <input type="email" id="edit-email" name="email" required class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                    </div>
                    <div>
                        <label for="edit-password" class="block text-sm font-medium text-gray-700 mb-1">Mot de passe (laisser vide pour ne pas changer)</label>
                        <input type="password" id="edit-password" name="password" class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                    </div>
                    <div>
                        <label for="edit-role" class="block text-sm font-medium text-gray-700 mb-1">Rôle</label>
                        <select id="edit-role" name="role" required class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                            <option value="admin">Administrateur</option>
                            <option value="manager">Gestionnaire</option>
                            <option value="editor">Éditeur</option>
                        </select>
                    </div>
                    <div>
                        <label for="edit-status" class="block text-sm font-medium text-gray-700 mb-1">Statut</label>
                        <select id="edit-status" name="status" required class="w-full px-3 py-2 border rounded-md focus:ring-blue-500 focus:border-blue-500">
                            <option value="active">Actif</option>
                            <option value="inactive">Inactif</option>
                        </select>
                    </div>
                </div>
                <div class="px-6 py-4 bg-gray-50 flex justify-end space-x-3">
                    <button type="button" class="modal-close px-4 py-2 text-sm font-medium text-gray-700 bg-white border rounded-md hover:bg-gray-50">
                        Annuler
                    </button>
                    <button type="submit" class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700">
                        Enregistrer
                    </button>
                </div>
            </form>
        </div>
    </div>
    
    <!-- Modal Confirmation Suppression -->
    <div id="delete-admin-modal" class="modal fixed inset-0 bg-gray-900 bg-opacity-50 z-50 flex items-center justify-center hidden">
        <div class="bg-white rounded-lg shadow-xl max-w-md w-full mx-4 overflow-hidden">
            <div class="px-6 py-4 border-b flex justify-between items-center">
                <h3 class="text-lg font-semibold text-gray-900">Confirmer la suppression</h3>
                <button class="modal-close text-gray-400 hover:text-gray-500">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <div class="p-6">
                <p class="text-gray-700">Êtes-vous sûr de vouloir supprimer cet administrateur ? Cette action est irréversible.</p>
            </div>
            <form action="AdminUsers.jsp" method="post">
                <input type="hidden" name="action" value="delete">
                <input type="hidden" id="delete-adminId" name="adminId" value="">
                <div class="px-6 py-4 bg-gray-50 flex justify-end space-x-3">
                    <button type="button" class="modal-close px-4 py-2 text-sm font-medium text-gray-700 bg-white border rounded-md hover:bg-gray-50">
                        Annuler
                    </button>
                    <button type="submit" class="px-4 py-2 text-sm font-medium text-white bg-red-600 rounded-md hover:bg-red-700">
                        Supprimer
                    </button>
                </div>
            </form>
        </div>
    </div>
    
    <!-- JavaScript -->
    <script>
        // Sidebar toggle
        document.getElementById('sidebar-toggle').addEventListener('click', function() {
            document.getElementById('sidebar').classList.toggle('open');
        });
        
        // Close sidebar when clicking outside on mobile
        document.addEventListener('click', function(event) {
            const sidebar = document.getElementById('sidebar');
            const sidebarToggle = document.getElementById('sidebar-toggle');
            
            if (window.innerWidth < 1024 && 
                !sidebar.contains(event.target) && 
                !sidebarToggle.contains(event.target) &&
                sidebar.classList.contains('open')) {
                sidebar.classList.remove('open');
            }
        });
        
        // Modal functionality
        const modals = document.querySelectorAll('.modal');
        const modalCloseButtons = document.querySelectorAll('.modal-close');
        
        // Open Add Admin Modal
        document.getElementById('add-admin-btn').addEventListener('click', function() {
            document.getElementById('add-admin-modal').classList.remove('hidden');
            document.body.classList.add('modal-active');
        });
        
        // Close Modals
        modalCloseButtons.forEach(button => {
            button.addEventListener('click', function() {
                modals.forEach(modal => {
                    modal.classList.add('hidden');
                });
                document.body.classList.remove('modal-active');
            });
        });
        
        // Close Modal when clicking outside
        modals.forEach(modal => {
            modal.addEventListener('click', function(event) {
                if (event.target === modal) {
                    modal.classList.add('hidden');
                    document.body.classList.remove('modal-active');
                }
            });
        });
        
        // Edit Admin functionality
        const editButtons = document.querySelectorAll('.edit-admin-btn');
        
        editButtons.forEach(button => {
            button.addEventListener('click', function() {
                const adminId = this.getAttribute('data-id');
                const firstName = this.getAttribute('data-firstname');
                const lastName = this.getAttribute('data-lastname');
                const email = this.getAttribute('data-email');
                const role = this.getAttribute('data-role');
                const status = this.getAttribute('data-status');
                
                document.getElementById('edit-adminId').value = adminId;
                document.getElementById('edit-firstName').value = firstName;
                document.getElementById('edit-lastName').value = lastName;
                document.getElementById('edit-email').value = email;
                document.getElementById('edit-password').value = '';
                
                const roleSelect = document.getElementById('edit-role');
                for (let i = 0; i < roleSelect.options.length; i++) {
                    if (roleSelect.options[i].value === role) {
                        roleSelect.selectedIndex = i;
                        break;
                    }
                }
                
                const statusSelect = document.getElementById('edit-status');
                for (let i = 0; i < statusSelect.options.length; i++) {
                    if (statusSelect.options[i].value === status) {
                        statusSelect.selectedIndex = i;
                        break;
                    }
                }
                
                document.getElementById('edit-admin-modal').classList.remove('hidden');
                document.body.classList.add('modal-active');
            });
        });
        
        // Delete Admin functionality
        const deleteButtons = document.querySelectorAll('.delete-admin-btn');
        
        deleteButtons.forEach(button => {
            button.addEventListener('click', function() {
                const adminId = this.getAttribute('data-id');
                document.getElementById('delete-adminId').value = adminId;
                
                document.getElementById('delete-admin-modal').classList.remove('hidden');
                document.body.classList.add('modal-active');
            });
        });
    </script>
</body>
</html>