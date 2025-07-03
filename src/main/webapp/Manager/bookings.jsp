<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    // Database connection parameters
    String url = "jdbc:mysql://localhost:3306/hotels_db"; // Change to your database name
    String username = "root"; // Change to your database username
    String password = ""; // Change to your database password
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // Lists to store data
    List<Map<String, Object>> bookingsList = new ArrayList<>();
    
    // Statistics
    int totalBookings = 0;
    int confirmedBookings = 0;
    int pendingBookings = 0;
    int cancelledBookings = 0;
    
    try {
        // Establish database connection
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(url, username, password);
        
        // Get booking statistics
        String statsQuery = "SELECT " +
                           "COUNT(*) as total, " +
                           "SUM(CASE WHEN status = 'confirmed' THEN 1 ELSE 0 END) as confirmed, " +
                           "SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending, " +
                           "SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled " +
                           "FROM bookings";
        
        pstmt = conn.prepareStatement(statsQuery);
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            totalBookings = rs.getInt("total");
            confirmedBookings = rs.getInt("confirmed");
            pendingBookings = rs.getInt("pending");
            cancelledBookings = rs.getInt("cancelled");
        }
        
        rs.close();
        pstmt.close();
        
        // Get recent bookings
        String bookingsQuery = "SELECT b.*, u.first_name, u.last_name, u.email, h.name as hotel_name, r.room_type " +
                              "FROM bookings b " +
                              "JOIN users u ON b.user_id = u.id " +
                              "JOIN hotels h ON b.hotel_id = h.id " +
                              "JOIN rooms r ON b.room_id = r.id " +
                              "ORDER BY b.booking_date DESC LIMIT 10";
        
        pstmt = conn.prepareStatement(bookingsQuery);
        rs = pstmt.executeQuery();
        
        SimpleDateFormat dateFormat = new SimpleDateFormat("MMM dd, yyyy");
        
        while (rs.next()) {
            Map<String, Object> booking = new HashMap<>();
            
            booking.put("id", rs.getString("id"));
            booking.put("booking_id", "BK-" + rs.getString("id"));
            booking.put("booking_date", dateFormat.format(rs.getDate("booking_date")));
            booking.put("guest_name", rs.getString("first_name") + " " + rs.getString("last_name"));
            booking.put("guest_email", rs.getString("email"));
            booking.put("hotel_name", rs.getString("hotel_name"));
            booking.put("check_in", dateFormat.format(rs.getDate("check_in_date")));
            booking.put("check_out", dateFormat.format(rs.getDate("check_out_date")));
            booking.put("room_type", rs.getString("room_type"));
            booking.put("amount", rs.getDouble("total_amount"));
            booking.put("status", rs.getString("status"));
            
            bookingsList.add(booking);
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
    <title>ZAIRTAM - Bookings Management</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
        }
        
        .booking-card {
            transition: all 0.3s ease;
        }
        
        .booking-card:hover {
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
        
        .status-badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 500;
        }
        
        .status-confirmed {
            background-color: #D1FAE5;
            color: #065F46;
        }
        
        .status-pending {
            background-color: #FEF3C7;
            color: #92400E;
        }
        
        .status-cancelled {
            background-color: #FEE2E2;
            color: #B91C1C;
        }
        
        .status-completed {
            background-color: #E0E7FF;
            color: #3730A3;
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
                        <input type="text" placeholder="Search for bookings by ID, guest name..." class="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
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
                            <a href="bookings.jsp" class="flex items-center px-3 py-2 text-blue-600 bg-blue-50 rounded-md">
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
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-chart-line w-5 text-center"></i>
                                <span class="ml-2">Reports</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-money-bill-wave w-5 text-center"></i>
                                <span class="ml-2">Revenue</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
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
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-user-shield w-5 text-center"></i>
                                <span class="ml-2">Admin Users</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-cog w-5 text-center"></i>
                                <span class="ml-2">Settings</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
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
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
                                <i class="fas fa-question-circle w-5 text-center"></i>
                                <span class="ml-2">Help Center</span>
                            </a>
                        </li>
                        <li>
                            <a href="#" class="flex items-center px-3 py-2 text-gray-700 hover:bg-gray-100 rounded-md">
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
            <div class="flex justify-between items-center mb-8">
                <div>
                    <h1 class="text-2xl font-bold text-gray-800">Bookings Management</h1>
                    <p class="text-gray-600">Manage all bookings across your hotel network</p>
                </div>
                <button class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg transition duration-200 flex items-center">
                    <i class="fas fa-plus mr-2"></i> Create New Booking
                </button>
            </div>
            
            <!-- Filters Section -->
            <div class="bg-white rounded-lg shadow-sm p-6 mb-8">
                <div class="flex flex-wrap items-center justify-between">
                    <h3 class="text-lg font-semibold text-gray-800 mb-4 md:mb-0">Filter Bookings</h3>
                    
                    <div class="flex flex-wrap gap-4">
                        <div class="w-full md:w-auto">
                            <label for="hotel-filter" class="block text-sm font-medium text-gray-700 mb-1">Hotel</label>
                            <select id="hotel-filter" class="w-full md:w-48 px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                <option value="all">All Hotels</option>
                                <% 
                                // Get unique hotels from bookings
                                Set<String> hotels = new HashSet<>();
                                for (Map<String, Object> booking : bookingsList) {
                                    hotels.add((String)booking.get("hotel_name"));
                                }
                                
                                for (String hotel : hotels) {
                                %>
                                <option value="<%= hotel.toLowerCase().replace(" ", "-") %>"><%= hotel %></option>
                                <% } %>
                            </select>
                        </div>
                        
                        <div class="w-full md:w-auto">
                            <label for="status-filter" class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                            <select id="status-filter" class="w-full md:w-48 px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                <option value="all">All Status</option>
                                <option value="confirmed">Confirmed</option>
                                <option value="pending">Pending</option>
                                <option value="cancelled">Cancelled</option>
                                <option value="completed">Completed</option>
                            </select>
                        </div>
                        
                        <div class="w-full md:w-auto">
                            <label for="date-filter" class="block text-sm font-medium text-gray-700 mb-1">Date Range</label>
                            <select id="date-filter" class="w-full md:w-48 px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                <option value="all">All Dates</option>
                                <option value="today">Today</option>
                                <option value="tomorrow">Tomorrow</option>
                                <option value="this-week">This Week</option>
                                <option value="next-week">Next Week</option>
                                <option value="this-month">This Month</option>
                                <option value="custom">Custom Range</option>
                            </select>
                        </div>
                        
                        <div class="w-full md:w-auto flex items-end">
                            <button class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg transition duration-200">
                                <i class="fas fa-filter mr-1"></i> Apply Filters
                            </button>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Bookings Stats Cards -->
            <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Total Bookings</h3>
                        <div class="bg-blue-100 p-2 rounded-md">
                            <i class="fas fa-calendar-check text-blue-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= totalBookings %></p>
                        <p class="text-green-600 text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-up mr-1"></i>8%
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Compared to last month</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Confirmed</h3>
                        <div class="bg-green-100 p-2 rounded-md">
                            <i class="fas fa-check-circle text-green-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= confirmedBookings %></p>
                        <p class="text-green-600 text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-up mr-1"></i>12%
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Compared to last month</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Pending</h3>
                        <div class="bg-yellow-100 p-2 rounded-md">
                            <i class="fas fa-clock text-yellow-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= pendingBookings %></p>
                        <p class="text-red-600 text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-down mr-1"></i>3%
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Compared to last month</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-gray-500 text-sm font-medium">Cancelled</h3>
                        <div class="bg-red-100 p-2 rounded-md">
                            <i class="fas fa-times-circle text-red-600"></i>
                        </div>
                    </div>
                    <div class="flex items-end">
                        <p class="text-2xl font-bold text-gray-800"><%= cancelledBookings %></p>
                        <p class="text-green-600 text-sm ml-2 mb-1">
                            <i class="fas fa-arrow-down mr-1"></i>5%
                        </p>
                    </div>
                    <p class="text-gray-500 text-sm mt-1">Compared to last month</p>
                </div>
            </div>
            
            <!-- Bookings Table -->
            <div class="bg-white rounded-lg shadow-sm overflow-hidden mb-8">
                <div class="p-6 border-b">
                    <h3 class="text-lg font-semibold text-gray-800">Recent Bookings</h3>
                </div>
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Booking ID
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Guest
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Hotel
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Check In/Out
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Room Type
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Amount
                                </th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Status
                                </th>
                                <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Actions
                                </th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            <% for (Map<String, Object> booking : bookingsList) { %>
                            <tr>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm font-medium text-gray-900"><%= booking.get("booking_id") %></div>
                                    <div class="text-xs text-gray-500"><%= booking.get("booking_date") %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm font-medium text-gray-900"><%= booking.get("guest_name") %></div>
                                    <div class="text-xs text-gray-500"><%= booking.get("guest_email") %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm text-gray-900"><%= booking.get("hotel_name") %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm text-gray-900"><%= booking.get("check_in") %></div>
                                    <div class="text-xs text-gray-500">to <%= booking.get("check_out") %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm text-gray-900"><%= booking.get("room_type") %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="text-sm font-medium text-gray-900">$<%= String.format("%.2f", booking.get("amount")) %></div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <% 
                                    String statusClass = "";
                                    String status = (String)booking.get("status");
                                    
                                    if (status.equals("confirmed")) {
                                        statusClass = "status-confirmed";
                                    } else if (status.equals("pending")) {
                                        statusClass = "status-pending";
                                    } else if (status.equals("cancelled")) {
                                        statusClass = "status-cancelled";
                                    } else if (status.equals("completed")) {
                                        statusClass = "status-completed";
                                    }
                                    %>
                                    <span class="status-badge <%= statusClass %>">
                                        <%= status.substring(0, 1).toUpperCase() + status.substring(1) %>
                                    </span>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                    <div class="flex justify-end space-x-2">
                                        <button class="text-blue-600 hover:text-blue-900" title="View Details">
                                            <i class="fas fa-eye"></i>
                                        </button>
                                        <button class="text-green-600 hover:text-green-900" title="Edit">
                                            <i class="fas fa-edit"></i>
                                        </button>
                                        <button class="text-red-600 hover:text-red-900" title="Delete">
                                            <i class="fas fa-trash"></i>
                                        </button>
                                    </div>
                                </td>
                            </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
                <div class="px-6 py-4 border-t">
                    <div class="flex items-center justify-between">
                        <div class="text-sm text-gray-600">
                            Showing <span class="font-medium">1</span> to <span class="font-medium"><%= bookingsList.size() %></span> of <span class="font-medium"><%= totalBookings %></span> bookings
                        </div>
                        <div class="flex space-x-2">
                            <button class="px-3 py-1 border rounded-md text-sm text-gray-600 hover:bg-gray-50 disabled:opacity-50" disabled>
                                Previous
                            </button>
                            <button class="px-3 py-1 border rounded-md bg-blue-50 text-blue-600 text-sm font-medium">
                                1
                            </button>
                            <button class="px-3 py-1 border rounded-md text-sm text-gray-600 hover:bg-gray-50">
                                2
                            </button>
                            <button class="px-3 py-1 border rounded-md text-sm text-gray-600 hover:bg-gray-50">
                                3
                            </button>
                            <button class="px-3 py-1 border rounded-md text-sm text-gray-600 hover:bg-gray-50">
                                Next
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    </div>

    <!-- JavaScript -->
    <script>
        // Mobile menu toggle
        const sidebarToggle = document.getElementById('sidebar-toggle');
        const sidebar = document.getElementById('sidebar');
        
        sidebarToggle.addEventListener('click', () => {
            sidebar.classList.toggle('open');
        });
        
        // Filter functionality
        document.addEventListener('DOMContentLoaded', function() {
            const hotelFilter = document.getElementById('hotel-filter');
            const statusFilter = document.getElementById('status-filter');
            const dateFilter = document.getElementById('date-filter');
            const applyFilterBtn = document.querySelector('.bg-blue-600');
            
            applyFilterBtn.addEventListener('click', function() {
                // Get filter values
                const hotel = hotelFilter.value;
                const status = statusFilter.value;
                const dateRange = dateFilter.value;
                
                // Apply filters to table rows
                const tableRows = document.querySelectorAll('tbody tr');
                
                tableRows.forEach(row => {
                    let showRow = true;
                    
                    // Hotel filter
                    if (hotel !== 'all') {
                        const hotelCell = row.querySelector('td:nth-child(3)').textContent.trim().toLowerCase().replace(/\s+/g, '-');
                        if (!hotelCell.includes(hotel)) {
                            showRow = false;
                        }
                    }
                    
                    // Status filter
                    if (status !== 'all') {
                        const statusCell = row.querySelector('td:nth-child(7)').textContent.trim().toLowerCase();
                        if (statusCell !== status) {
                            showRow = false;
                        }
                    }
                    
                    // Date filter (simplified for demo)
                    if (dateRange !== 'all') {
                        // This would normally involve more complex date parsing
                        // For now, we'll just do a simple check
                        const dateCell = row.querySelector('td:nth-child(4)').textContent.trim().toLowerCase();
                        
                        const today = new Date();
                        const tomorrow = new Date(today);
                        tomorrow.setDate(tomorrow.getDate() + 1);
                        
                        // Simple date filtering logic
                        if (dateRange === 'today' && !dateCell.includes(today.toLocaleDateString('en-US', {month: 'short', day: 'numeric'}))) {
                            showRow = false;
                        }
                    }
                    
                    // Show or hide row
                    row.style.display = showRow ? '' : 'none';
                });
                
                // Update counts in the UI
                updateFilteredCounts();
            });
            
            // Function to update counts after filtering
            function updateFilteredCounts() {
                const visibleRows = document.querySelectorAll('tbody tr:not([style*="display: none"])');
                document.querySelector('.px-6.py-4 p span:nth-child(2)').textContent = visibleRows.length;
            }
            
            // Status update functionality
            const statusButtons = document.querySelectorAll('.status-update-btn');
            statusButtons.forEach(button => {
                button.addEventListener('click', function() {
                    const bookingId = this.getAttribute('data-booking-id');
                    const newStatus = this.getAttribute('data-status');
                    
                    // Here you would normally make an AJAX call to update the status
                    // For demo purposes, we'll just update the UI
                    const statusCell = this.closest('tr').querySelector('td:nth-child(7) span');
                    
                    // Remove old status classes
                    statusCell.classList.remove('status-confirmed', 'status-pending', 'status-cancelled', 'status-completed');
                    
                    // Add new status class and update text
                    statusCell.classList.add('status-' + newStatus);
                    statusCell.textContent = newStatus.charAt(0).toUpperCase() + newStatus.slice(1);
                    
                    // Close dropdown
                    this.closest('.relative').querySelector('.dropdown-content').classList.add('hidden');
                });
            });
            
            // Dropdown toggle
            const dropdownToggles = document.querySelectorAll('.dropdown-toggle');
            dropdownToggles.forEach(toggle => {
                toggle.addEventListener('click', function(e) {
                    e.preventDefault();
                    const dropdown = this.nextElementSibling;
                    dropdown.classList.toggle('hidden');
                    
                    // Close other dropdowns
                    document.querySelectorAll('.dropdown-content').forEach(menu => {
                        if (menu !== dropdown) {
                            menu.classList.add('hidden');
                        }
                    });
                });
            });
            
            // Close dropdowns when clicking outside
            document.addEventListener('click', function(e) {
                if (!e.target.closest('.relative')) {
                    document.querySelectorAll('.dropdown-content').forEach(dropdown => {
                        dropdown.classList.add('hidden');
                    });
                }
            });
            
            // View booking details
            const viewButtons = document.querySelectorAll('.view-booking-btn');
            viewButtons.forEach(button => {
                button.addEventListener('click', function() {
                    const bookingId = this.getAttribute('data-booking-id');
                    // Redirect to booking details page
                    window.location.href = 'booking-details.jsp?id=' + bookingId;
                });
            });
        });
    </script>
</body>
</html>