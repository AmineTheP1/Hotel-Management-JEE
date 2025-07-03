<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!-- Navigation -->
<nav class="bg-white shadow-sm sticky top-0 z-50">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between items-center h-16">
            <!-- Logo -->
            <div class="flex items-center">
                <a href="index.jsp" class="flex items-center">
                    <i class="fas fa-hotel text-blue-600 text-2xl mr-2"></i>
                    <span class="text-xl font-bold text-gray-800">ZAIRTAM</span>
                </a>
            </div>
            
            <!-- Desktop Navigation -->
            <div class="hidden md:flex items-center space-x-8">
                <a href="index.jsp" class="text-gray-800 hover:text-blue-600 font-medium">Home</a>
                <a href="search-results.jsp" class="text-gray-800 hover:text-blue-600 font-medium">Search</a>
                <a href="deals.jsp" class="text-gray-800 hover:text-blue-600 font-medium">Deals</a>
                <a href="about.jsp" class="text-gray-800 hover:text-blue-600 font-medium">About</a>
                
                <div class="relative">
                    <button class="flex items-center text-gray-800 hover:text-blue-600">
                        <i class="fas fa-globe mr-1"></i>
                        <span>English</span>
                        <i class="fas fa-chevron-down ml-1 text-xs"></i>
                    </button>
                </div>
                
                <c:choose>
                    <c:when test="${sessionScope.userId != null}">
                        <div class="relative group">
                            <button class="flex items-center text-gray-800 hover:text-blue-600">
                                <i class="fas fa-user-circle mr-1"></i>
                                <span>${sessionScope.firstName}</span>
                                <i class="fas fa-chevron-down ml-1 text-xs"></i>
                            </button>
                            <div class="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 hidden group-hover:block">
                                <c:choose>
                                    <c:when test="${sessionScope.userRole == 'client'}">
                                        <a href="Client/dashboard.jsp" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                                            <i class="fas fa-user mr-2"></i>Dashboard
                                        </a>
                                        <a href="Client/bookings.jsp" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                                            <i class="fas fa-calendar-check mr-2"></i>My Bookings
                                        </a>
                                    </c:when>
                                    <c:when test="${sessionScope.userRole == 'employee'}">
                                        <a href="Employee/Dashboard.jsp" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                                            <i class="fas fa-briefcase mr-2"></i>Dashboard
                                        </a>
                                        <a href="Employee/Booking.jsp" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                                            <i class="fas fa-calendar-alt mr-2"></i>Bookings
                                        </a>
                                    </c:when>
                                    <c:when test="${sessionScope.userRole == 'manager'}">
                                        <a href="Manager/admin-dashboard.jsp" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                                            <i class="fas fa-user-shield mr-2"></i>Dashboard
                                        </a>
                                        <a href="Manager/users.jsp" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                                            <i class="fas fa-users-cog mr-2"></i>Users
                                        </a>
                                    </c:when>
                                </c:choose>
                                <a href="account-settings.jsp" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Account Settings</a>
                                <a href="logout.jsp" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Logout</a>
                            </div>
                        </div>
                    </c:when>
                    <c:otherwise>
                        <a href="login.jsp" class="text-gray-800 hover:text-blue-600 font-medium">Login</a>
                        <a href="register.jsp" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md font-medium">Sign Up</a>
                    </c:otherwise>
                </c:choose>
            </div>
            
            <!-- Mobile menu button -->
            <div class="md:hidden">
                <button id="mobile-menu-button" class="text-gray-800 hover:text-blue-600 focus:outline-none">
                    <i class="fas fa-bars text-xl"></i>
                </button>
            </div>
        </div>
    </div>
    
    <!-- Mobile menu -->
    <div id="mobile-menu" class="hidden md:hidden bg-white pb-4 px-4">
        <div class="pt-2 space-y-2">
            <a href="index.jsp" class="block px-4 py-2 text-gray-800 hover:text-blue-600 font-medium">Home</a>
            <a href="search-results.jsp" class="block px-4 py-2 text-gray-800 hover:text-blue-600 font-medium">Search</a>
            <a href="deals.jsp" class="block px-4 py-2 text-gray-800 hover:text-blue-600 font-medium">Deals</a>
            <a href="about.jsp" class="block px-4 py-2 text-gray-800 hover:text-blue-600 font-medium">About</a>
            
            <div class="relative mb-2">
                <button class="flex items-center w-full px-4 py-2 text-gray-800 hover:text-blue-600 font-medium">
                    <i class="fas fa-globe mr-2"></i>
                    <span>Language</span>
                    <i class="fas fa-chevron-down ml-auto text-xs"></i>
                </button>
            </div>
            
            <c:choose>
                <c:when test="${sessionScope.userId != null}">
                    <a href="account-settings.jsp" class="block px-4 py-2 text-gray-800 hover:text-blue-600 font-medium">Account</a>
                    <a href="logout.jsp" class="block px-4 py-2 text-gray-800 hover:text-blue-600 font-medium">Logout</a>
                </c:when>
                <c:otherwise>
                    <a href="login.jsp" class="block px-4 py-2 text-gray-800 hover:text-blue-600 font-medium">Login</a>
                    <a href="register.jsp" class="block px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md font-medium text-center">Sign Up</a>
                </c:otherwise>
            </c:choose>
        </div>
    </div>
</nav>

<script>
    // Mobile menu toggle
    document.getElementById('mobile-menu-button').addEventListener('click', function() {
        const mobileMenu = document.getElementById('mobile-menu');
        mobileMenu.classList.toggle('hidden');
    });
</script>