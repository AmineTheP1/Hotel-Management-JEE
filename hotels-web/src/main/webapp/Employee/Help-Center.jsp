<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
    // Database connection parameters
    String jdbcURL = "jdbc:mysql://localhost:4200/hotel?useSSL=false";
    String dbUser = "root";
    String dbPassword = "Hamza_13579";
    
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
    
    // Lists to store help center data
    List<Map<String, Object>> faqList = new ArrayList<>();
    List<Map<String, Object>> popularTopicsList = new ArrayList<>();
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
                    successMessage = "Your support ticket has been submitted successfully. Our team will respond shortly.";
                } else {
                    errorMessage = "Failed to submit your ticket. Please try again.";
                }
                
            } catch (Exception e) {
                errorMessage = "Error: " + e.getMessage();
                e.printStackTrace();
            }
        }
    }
    
    try {
        // Establish database connection
        Class.forName("com.mysql.jdbc.Driver");
        conn = DriverManager.getConnection(jdbcURL, dbUser, dbPassword);
        
        // Fetch FAQs
        String faqQuery = "SELECT * FROM faqs WHERE is_active = 1 ORDER BY category, id LIMIT 10";
        pstmt = conn.prepareStatement(faqQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> faq = new HashMap<>();
            faq.put("id", rs.getInt("id"));
            faq.put("question", rs.getString("question"));
            faq.put("answer", rs.getString("answer"));
            faq.put("category", rs.getString("category"));
            faqList.add(faq);
        }
        
        // Fetch popular topics
        String topicsQuery = "SELECT category, COUNT(*) as count FROM faqs GROUP BY category ORDER BY count DESC LIMIT 5";
        pstmt = conn.prepareStatement(topicsQuery);
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> topic = new HashMap<>();
            topic.put("category", rs.getString("category"));
            topic.put("count", rs.getInt("count"));
            popularTopicsList.add(topic);
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
        errorMessage = "Error: " + e.getMessage();
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
    <title>ZAIRTAM - Help Center</title>
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
        
        .faq-item {
            border-radius: 0.5rem;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
            transition: all 0.3s ease;
        }
        
        .faq-item:hover {
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        
        .faq-answer {
            max-height: 0;
            overflow: hidden;
            transition: max-height 0.3s ease;
        }
        
        .faq-answer.open {
            max-height: 500px;
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
            
            // FAQ accordion functionality
            const faqItems = document.querySelectorAll('.faq-question');
            faqItems.forEach(item => {
                item.addEventListener('click', function() {
                    const answer = this.nextElementSibling;
                    const icon = this.querySelector('i');
                    
                    // Toggle answer visibility
                    answer.classList.toggle('open');
                    
                    // Toggle icon
                    if (answer.classList.contains('open')) {
                        icon.classList.remove('fa-plus');
                        icon.classList.add('fa-minus');
                    } else {
                        icon.classList.remove('fa-minus');
                        icon.classList.add('fa-plus');
                    }
                });
            });
            
            // Search functionality
            const searchInput = document.getElementById('faq-search');
            if (searchInput) {
                searchInput.addEventListener('input', function() {
                    const searchTerm = this.value.toLowerCase();
                    const faqItems = document.querySelectorAll('.faq-item');
                    
                    faqItems.forEach(item => {
                        const question = item.querySelector('.faq-question').textContent.toLowerCase();
                        const answer = item.querySelector('.faq-answer').textContent.toLowerCase();
                        
                        if (question.includes(searchTerm) || answer.includes(searchTerm)) {
                            item.style.display = 'block';
                        } else {
                            item.style.display = 'none';
                        }
                    });
                });
            }
            
            // Form validation
            const supportForm = document.getElementById('supportForm');
            if (supportForm) {
                supportForm.addEventListener('submit', function(event) {
                    const subject = document.getElementById('subject');
                    const message = document.getElementById('message');
                    
                    if (!subject.value.trim()) {
                        event.preventDefault();
                        alert('Please enter a subject for your ticket');
                        subject.focus();
                        return false;
                    }
                    
                    if (!message.value.trim()) {
                        event.preventDefault();
                        alert('Please enter a message describing your issue');
                        message.focus();
                        return false;
                    }
                    
                    // Show loading state
                    const submitButton = document.querySelector('button[type="submit"]');
                    if (submitButton) {
                        submitButton.disabled = true;
                        submitButton.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i> Submitting...';
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
                            <i class="fas fa-sign-in-alt mr-1"></i> Login
                        </a>
                        <a href="../register.jsp" class="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
                            Register
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
                    <h2 class="text-lg font-semibold text-gray-900">Help Categories</h2>
                    <nav class="mt-3 space-y-1">
                        <a href="#bookings" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                            <i class="fas fa-calendar-alt w-5 h-5 mr-3 text-gray-400"></i>
                            Bookings & Reservations
                        </a>
                        <a href="#payments" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                            <i class="fas fa-credit-card w-5 h-5 mr-3 text-gray-400"></i>
                            Payments & Billing
                        </a>
                        <a href="#account" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                            <i class="fas fa-user-circle w-5 h-5 mr-3 text-gray-400"></i>
                            Account Management
                        </a>
                        <a href="#rooms" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                            <i class="fas fa-bed w-5 h-5 mr-3 text-gray-400"></i>
                            Room Information
                        </a>
                        <a href="#policies" class="flex items-center px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                            <i class="fas fa-shield-alt w-5 h-5 mr-3 text-gray-400"></i>
                            Policies & Terms
                        </a>
                    </nav>
                </div>
                
                <div class="mb-6">
                    <h2 class="text-lg font-semibold text-gray-900">Popular Topics</h2>
                    <div class="mt-3 space-y-2">
                        <% if (!popularTopicsList.isEmpty()) { %>
                            <% for (Map<String, Object> topic : popularTopicsList) { %>
                                <a href="#<%= topic.get("category").toString().toLowerCase().replace(" ", "-") %>" class="block px-3 py-2 text-sm font-medium text-gray-600 rounded-md hover:bg-gray-50 hover:text-blue-600">
                                    <%= topic.get("category") %> (<%= topic.get("count") %>)
                                </a>
                            <% } %>
                        <% } else { %>
                            <div class="px-3 py-2 text-sm text-gray-500">
                                No topics available
                            </div>
                        <% } %>
                    </div>
                </div>
                
                <div>
                    <h2 class="text-lg font-semibold text-gray-900">Need More Help?</h2>
                    <div class="mt-3">
                        <a href="#contact-support" class="block w-full px-4 py-2 text-sm font-medium text-center text-white bg-blue-600 rounded-md hover:bg-blue-700">
                            Contact Support
                        </a>
                    </div>
                </div>
            </div>
        </aside>

        <!-- Main Content -->
        <main class="flex-1 p-4 sm:p-6 lg:p-8">
            <div class="max-w-4xl mx-auto">
                <!-- Header -->
                <div class="mb-8">
                    <h1 class="text-2xl font-bold text-gray-900 sm:text-3xl">Help Center</h1>
                    <p class="mt-2 text-gray-600">Find answers to common questions or contact our support team for assistance.</p>
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
                
                <!-- Search Bar -->
                <div class="mb-8">
                    <div class="relative">
                        <input type="text" id="faq-search" placeholder="Search for help..." class="w-full px-4 py-3 pl-12 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                            <i class="fas fa-search text-gray-400"></i>
                        </div>
                    </div>
                </div>
                
                <!-- FAQ Sections -->
                <div class="mb-12">
                    <h2 id="bookings" class="text-xl font-semibold text-gray-900 mb-4">Bookings & Reservations</h2>
                    <div class="space-y-4">
                        <% 
                        boolean hasBookingFaqs = false;
                        for (Map<String, Object> faq : faqList) {
                            if ("Bookings & Reservations".equals(faq.get("category"))) {
                                hasBookingFaqs = true;
                        %>
                            <div class="faq-item bg-white overflow-hidden">
                                <div class="faq-question p-4 cursor-pointer flex justify-between items-center">
                                    <h3 class="text-base font-medium text-gray-900"><%= faq.get("question") %></h3>
                                    <i class="fas fa-plus text-gray-500 transition-transform"></i>
                                </div>
                                <div class="faq-answer bg-gray-50 px-4 py-3 text-gray-600">
                                    <%= faq.get("answer") %>
                                </div>
                            </div>
                        <% 
                            }
                        }
                        if (!hasBookingFaqs) {
                        %>
                            <div class="p-4 bg-gray-50 rounded-md text-gray-500 text-center">
                                No FAQs available for this category.
                            </div>
                        <% } %>
                    </div>
                </div>
                
                <div class="mb-12">
                    <h2 id="payments" class="text-xl font-semibold text-gray-900 mb-4">Payments & Billing</h2>
                    <div class="space-y-4">
                        <% 
                        boolean hasPaymentFaqs = false;
                        for (Map<String, Object> faq : faqList) {
                            if ("Payments & Billing".equals(faq.get("category"))) {
                                hasPaymentFaqs = true;
                        %>
                            <div class="faq-item bg-white overflow-hidden">
                                <div class="faq-question p-4 cursor-pointer flex justify-between items-center">
                                    <h3 class="text-base font-medium text-gray-900"><%= faq.get("question") %></h3>
                                    <i class="fas fa-plus text-gray-500 transition-transform"></i>
                                </div>
                                <div class="faq-answer bg-gray-50 px-4 py-3 text-gray-600">
                                    <%= faq.get("answer") %>
                                </div>
                            </div>
                        <% 
                            }
                        }
                        if (!hasPaymentFaqs) {
                        %>
                            <div class="p-4 bg-gray-50 rounded-md text-gray-500 text-center">
                                No FAQs available for this category.
                            </div>
                        <% } %>
                    </div>
                </div>
                
                <div class="mb-12">
                    <h2 id="account" class="text-xl font-semibold text-gray-900 mb-4">Account Management</h2>
                    <div class="space-y-4">
                        <% 
                        boolean hasAccountFaqs = false;
                        for (Map<String, Object> faq : faqList) {
                            if ("Account Management".equals(faq.get("category"))) {
                                hasAccountFaqs = true;
                        %>
                            <div class="faq-item bg-white overflow-hidden">
                                <div class="faq-question p-4 cursor-pointer flex justify-between items-center">
                                    <h3 class="text-base font-medium text-gray-900"><%= faq.get("question") %></h3>
                                    <i class="fas fa-plus text-gray-500 transition-transform"></i>
                                </div>
                                <div class="faq-answer bg-gray-50 px-4 py-3 text-gray-600">
                                    <%= faq.get("answer") %>
                                </div>
                            </div>
                        <% 
                            }
                        }
                        if (!hasAccountFaqs) {
                        %>
                            <div class="p-4 bg-gray-50 rounded-md text-gray-500 text-center">
                                No FAQs available for this category.
                            </div>
                        <% } %>
                    </div>
                </div>
                
                <div class="mb-12">
                    <h2 id="rooms" class="text-xl font-semibold text-gray-900 mb-4">Room Information</h2>
                    <div class="space-y-4">
                        <% 
                        boolean hasRoomFaqs = false;
                        for (Map<String, Object> faq : faqList) {
                            if ("Room Information".equals(faq.get("category"))) {
                                hasRoomFaqs = true;
                        %>
                            <div class="faq-item bg-white overflow-hidden">
                                <div class="faq-question p-4 cursor-pointer flex justify-between items-center">
                                    <h3 class="text-base font-medium text-gray-900"><%= faq.get("question") %></h3>
                                    <i class="fas fa-plus text-gray-500 transition-transform"></i>
                                </div>
                                <div class="faq-answer bg-gray-50 px-4 py-3 text-gray-600">
                                    <%= faq.get("answer") %>
                                </div>
                            </div>
                        <% 
                            }
                        }
                        if (!hasRoomFaqs) {
                        %>
                            <div class="p-4 bg-gray-50 rounded-md text-gray-500 text-center">
                                No FAQs available for this category.
                            </div>
                        <% } %>
                    </div>
                </div>
                
                <div class="mb-12">
                    <h2 id="policies" class="text-xl font-semibold text-gray-900 mb-4">Policies & Terms</h2>
                    <div class="space-y-4">
                        <% 
                        boolean hasPolicyFaqs = false;
                        for (Map<String, Object> faq : faqList) {
                            if ("Policies & Terms".equals(faq.get("category"))) {
                                hasPolicyFaqs = true;
                        %>
                            <div class="faq-item bg-white overflow-hidden">
                                <div class="faq-question p-4 cursor-pointer flex justify-between items-center">
                                    <h3 class="text-base font-medium text-gray-900"><%= faq.get("question") %></h3>
                                    <i class="fas fa-plus text-gray-500 transition-transform"></i>
                                </div>
                                <div class="faq-answer bg-gray-50 px-4 py-3 text-gray-600">
                                    <%= faq.get("answer") %>
                                </div>
                            </div>
                        <% 
                            }
                        }
                        if (!hasPolicyFaqs) {
                        %>
                            <div class="p-4 bg-gray-50 rounded-md text-gray-500 text-center">
                                No FAQs available for this category.
                            </div>
                        <% } %>
                    </div>
                </div>
                
                <!-- User Tickets Section (if logged in) -->
                <% if (userId != null && !userTicketsList.isEmpty()) { %>
                    <div class="mb-12">
                        <h2 class="text-xl font-semibold text-gray-900 mb-4">Your Recent Support Tickets</h2>
                        <div class="bg-white rounded-lg shadow overflow-hidden">
                            <div class="overflow-x-auto">
                                <table class="min-w-full divide-y divide-gray-200">
                                    <thead class="bg-gray-50">
                                        <tr>
                                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Subject</th>
                                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Category</th>
                                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Priority</th>
                                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                                            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                                        </tr>
                                    </thead>
                                    <tbody class="bg-white divide-y divide-gray-200">
                                        <% 
                                        SimpleDateFormat dateFormat = new SimpleDateFormat("MMM d, yyyy");
                                        for (Map<String, Object> ticket : userTicketsList) {
                                            String priorityClass = "";
                                            if ("low".equalsIgnoreCase((String)ticket.get("priority"))) {
                                                priorityClass = "priority-low";
                                            } else if ("medium".equalsIgnoreCase((String)ticket.get("priority"))) {
                                                priorityClass = "priority-medium";
                                            } else if ("high".equalsIgnoreCase((String)ticket.get("priority"))) {
                                                priorityClass = "priority-high";
                                            }
                                            
                                            String statusClass = "";
                                            if ("open".equalsIgnoreCase((String)ticket.get("status"))) {
                                                statusClass = "ticket-open";
                                            } else if ("in progress".equalsIgnoreCase((String)ticket.get("status"))) {
                                                statusClass = "ticket-in-progress";
                                            } else if ("resolved".equalsIgnoreCase((String)ticket.get("status"))) {
                                                statusClass = "ticket-resolved";
                                            } else if ("closed".equalsIgnoreCase((String)ticket.get("status"))) {
                                                statusClass = "ticket-closed";
                                            }
                                        %>
                                            <tr>
                                                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                                                    <%= ticket.get("subject") %>
                                                </td>
                                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                                    <%= ticket.get("category") %>
                                                </td>
                                                <td class="px-6 py-4 whitespace-nowrap">
                                                    <span class="<%= priorityClass %>">
                                                        <%= ticket.get("priority") %>
                                                    </span>
                                                </td>
                                                <td class="px-6 py-4 whitespace-nowrap">
                                                    <span class="<%= statusClass %>">
                                                        <%= ticket.get("status") %>
                                                    </span>
                                                </td>
                                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                                    <%= dateFormat.format(ticket.get("created_at")) %>
                                                </td>
                                            </tr>
                                        <% } %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                <% } %>
                
                <!-- Contact Support Form -->
                <div id="contact-support" class="mb-8">
                    <h2 class="text-xl font-semibold text-gray-900 mb-4">Contact Support</h2>
                    
                    <% if (userId != null) { %>
                        <div class="bg-white rounded-lg shadow-sm p-6">
                            <form id="supportForm" method="post" action="Help-Center.jsp">
                                <input type="hidden" name="action" value="submit_ticket">
                                
                                <div class="mb-4">
                                    <label for="subject" class="block text-sm font-medium text-gray-700 mb-1">Subject</label>
                                    <input type="text" id="subject" name="subject" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500" placeholder="Brief description of your issue">
                                </div>
                                
                                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                                    <div>
                                        <label for="category" class="block text-sm font-medium text-gray-700 mb-1">Category</label>
                                        <select id="category" name="category" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                                            <option value="Bookings & Reservations">Bookings & Reservations</option>
                                            <option value="Payments & Billing">Payments & Billing</option>
                                            <option value="Account Management">Account Management</option>
                                            <option value="Room Information">Room Information</option>
                                            <option value="Policies & Terms">Policies & Terms</option>
                                            <option value="Other">Other</option>
                                        </select>
                                    </div>
                                    
                                    <div>
                                        <label for="priority" class="block text-sm font-medium text-gray-700 mb-1">Priority</label>
                                        <select id="priority" name="priority" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500">
                                            <option value="low">Low</option>
                                            <option value="medium">Medium</option>
                                            <option value="high">High</option>
                                        </select>
                                    </div>
                                </div>
                                
                                <div class="mb-4">
                                    <label for="message" class="block text-sm font-medium text-gray-700 mb-1">Message</label>
                                    <textarea id="message" name="message" rows="5" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500" placeholder="Please describe your issue in detail"></textarea>
                                </div>
                                
                                <div class="flex justify-end">
                                    <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
                                        Submit Ticket
                                    </button>
                                </div>
                            </form>
                        </div>
                    <% } else { %>
                        <div class="bg-white rounded-lg shadow-sm p-6 text-center">
                            <i class="fas fa-user-lock text-gray-400 text-4xl mb-3"></i>
                            <h3 class="text-lg font-medium text-gray-900 mb-2">Login Required</h3>
                            <p class="text-gray-600 mb-4">You need to be logged in to submit a support ticket.</p>
                            <div class="flex justify-center space-x-4">
                                <a href="../login.jsp" class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">
                                    Login
                                </a>
                                <a href="../register.jsp" class="px-4 py-2 bg-gray-200 text-gray-800 rounded-md hover:bg-gray-300">
                                    Register
                                </a>
                            </div>
                        </div>
                    <% } %>
                </div>
                
                <!-- Additional Help Options -->
                <div class="mb-8">
                    <h2 class="text-xl font-semibold text-gray-900 mb-4">Additional Help Options</h2>
                    
                    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <div class="bg-white p-5 rounded-lg shadow-sm text-center">
                            <div class="w-12 h-12 mx-auto mb-3 flex items-center justify-center bg-blue-100 text-blue-600 rounded-full">
                                <i class="fas fa-phone-alt"></i>
                            </div>
                            <h3 class="text-lg font-medium text-gray-900 mb-1">Call Us</h3>
                            <p class="text-gray-600 mb-3">Available 24/7 for urgent issues</p>
                            <a href="tel:+1234567890" class="text-blue-600 hover:text-blue-800 font-medium">
                                +1 (234) 567-890
                            </a>
                        </div>
                        
                        <div class="bg-white p-5 rounded-lg shadow-sm text-center">
                            <div class="w-12 h-12 mx-auto mb-3 flex items-center justify-center bg-green-100 text-green-600 rounded-full">
                                <i class="fas fa-envelope"></i>
                            </div>
                            <h3 class="text-lg font-medium text-gray-900 mb-1">Email Us</h3>
                            <p class="text-gray-600 mb-3">We'll respond within 24 hours</p>
                            <a href="mailto:support@zairtam.com" class="text-blue-600 hover:text-blue-800 font-medium">
                                support@zairtam.com
                            </a>
                        </div>
                        
                        <div class="bg-white p-5 rounded-lg shadow-sm text-center">
                            <div class="w-12 h-12 mx-auto mb-3 flex items-center justify-center bg-purple-100 text-purple-600 rounded-full">
                                <i class="fas fa-comments"></i>
                            </div>
                            <h3 class="text-lg font-medium text-gray-900 mb-1">Live Chat</h3>
                            <p class="text-gray-600 mb-3">Chat with our support team</p>
                            <button class="text-blue-600 hover:text-blue-800 font-medium">
                                Start Chat
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    </div>
    
    <!-- Footer -->
    <footer class="bg-white border-t border-gray-200 py-8">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="md:flex md:items-center md:justify-between">
                <div class="flex justify-center md:justify-start">
                    <a href="index.jsp" class="flex items-center">
                        <i class="fas fa-hotel text-blue-600 text-2xl mr-2"></i>
                        <span class="text-xl font-bold text-gray-800">ZAIRTAM</span>
                    </a>
                </div>
                
                <div class="mt-8 md:mt-0">
                    <p class="text-center md:text-right text-sm text-gray-500">
                        &copy; 2023 ZAIRTAM Hotels. All rights reserved.
                    </p>
                </div>
            </div>
        </div>
    </footer>
</body>
</html>