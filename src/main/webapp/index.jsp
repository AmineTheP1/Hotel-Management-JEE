<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZAIRTAM - Book Hotels Worldwide</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
        }
        
        .hero-banner {
            background-image: linear-gradient(rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.5)), url('https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80');
            background-size: cover;
            background-position: center;
            height: 70vh;
            min-height: 400px;
        }
        
        .destination-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
        }
        
        .destination-card {
            transition: all 0.3s ease;
        }
        
        .search-box {
            transform: translateY(50%);
        }
        
        @media (max-width: 768px) {
            .hero-banner {
                height: 60vh;
            }
            
            .search-box {
                transform: translateY(20%);
            }
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
                    <i class="fas fa-hotel text-blue-600 text-2xl mr-2"></i>
                    <span class="text-xl font-bold text-gray-800">ZAIRTAM</span>
                </div>
                
                <!-- Desktop Navigation -->
                <div class="hidden md:flex items-center space-x-8">
                    <a href="index.jsp" class="text-gray-800 hover:text-blue-600 font-medium">Home</a>
                    <a href="search.jsp" class="text-gray-800 hover:text-blue-600 font-medium">Search</a>
                    <a href="deals.jsp" class="text-gray-800 hover:text-blue-600 font-medium">Deals</a>
                    <a href="about.jsp" class="text-gray-800 hover:text-blue-600 font-medium">About</a>
                    
                    <div class="relative">
                        <button class="flex items-center text-gray-800 hover:text-blue-600">
                            <i class="fas fa-globe mr-1"></i>
                            <span>English</span>
                            <i class="fas fa-chevron-down ml-1 text-xs"></i>
                        </button>
                    </div>
                    
                    <a href="login.jsp" class="text-gray-800 hover:text-blue-600 font-medium">Login</a>
                    <a href="register.jsp" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md font-medium">Sign Up</a>
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
                <a href="search.jsp" class="block px-4 py-2 text-gray-800 hover:text-blue-600 font-medium">Search</a>
                <a href="deals.jsp" class="block px-4 py-2 text-gray-800 hover:text-blue-600 font-medium">Deals</a>
                <a href="about.jsp" class="block px-4 py-2 text-gray-800 hover:text-blue-600 font-medium">About</a>
                
                <div class="relative mb-2">
                    <button class="flex items-center w-full px-4 py-2 text-gray-800 hover:text-blue-600 font-medium">
                        <i class="fas fa-globe mr-2"></i>
                        <span>Language</span>
                        <i class="fas fa-chevron-down ml-auto text-xs"></i>
                    </button>
                </div>
                
                <a href="login.jsp" class="block px-4 py-2 text-gray-800 hover:text-blue-600 font-medium">Login</a>
                <a href="register.jsp" class="block px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md font-medium text-center">Sign Up</a>
            </div>
        </div>
    </nav>

    <!-- Hero Banner -->
    <section class="hero-banner flex items-center justify-center text-white relative">
        <div class="text-center px-4">
            <h1 class="text-4xl md:text-5xl font-bold mb-4">Find Your Perfect Stay</h1>
            <p class="text-xl md:text-2xl mb-8">Discover amazing hotels, resorts, and apartments worldwide</p>
        </div>
        
        <!-- Search Box -->
        <div class="search-box absolute w-full max-w-5xl px-4">
            <div class="bg-white rounded-lg shadow-xl p-4 md:p-6">
                <form action="search" method="post">
                    <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
                        <div>
                            <label for="destination" class="block text-sm font-medium text-gray-700 mb-1">Destination</label>
                            <div class="relative">
                                <input type="text" id="destination" name="destination" placeholder="Where are you going?" class="w-full px-4 py-3 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                <i class="fas fa-map-marker-alt absolute right-3 top-3.5 text-gray-400"></i>
                            </div>
                        </div>
                        
                        <div>
                            <label for="check-in" class="block text-sm font-medium text-gray-700 mb-1">Check-in</label>
                            <input type="date" id="check-in" name="checkIn" class="w-full px-4 py-3 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                        </div>
                        
                        <div>
                            <label for="check-out" class="block text-sm font-medium text-gray-700 mb-1">Check-out</label>
                            <input type="date" id="check-out" name="checkOut" class="w-full px-4 py-3 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                        </div>
                        
                        <div>
                            <label for="guests" class="block text-sm font-medium text-gray-700 mb-1">Guests</label>
                            <div class="relative">
                                <input type="text" id="guests" name="guests" placeholder="1 room, 2 guests" class="w-full px-4 py-3 border rounded-lg focus:ring-blue-500 focus:border-blue-500">
                                <i class="fas fa-user absolute right-3 top-3.5 text-gray-400"></i>
                            </div>
                        </div>
                    </div>
                    
                    <button type="submit" class="w-full mt-4 bg-blue-600 hover:bg-blue-700 text-white py-3 rounded-lg font-medium">
                        <i class="fas fa-search mr-2"></i> Search Hotels
                    </button>
                </form>
            </div>
        </div>
    </section>

    <!-- Popular Destinations -->
    <section class="max-w-7xl mx-auto px-4 py-20 md:py-28">
        <div class="text-center mb-12">
            <h2 class="text-3xl md:text-4xl font-bold text-gray-800 mb-4">Popular Destinations</h2>
            <p class="text-lg text-gray-600 max-w-2xl mx-auto">Explore our most sought-after destinations loved by travelers worldwide</p>
        </div>
        
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            <!-- Dynamic Destinations from Database -->
            <c:forEach var="hotel" items="${popularHotels}" varStatus="status">
                <div class="destination-card bg-white rounded-xl overflow-hidden shadow-md">
                    <div class="relative h-48">
                        <img src="${hotel.imageUrl != null ? hotel.imageUrl : 'https://images.unsplash.com/photo-1483729558449-99ef109a84c7?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80'}" 
                             alt="${hotel.name}" class="w-full h-full object-cover">
                        <div class="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent"></div>
                        <div class="absolute bottom-4 left-4 text-white">
                            <h3 class="text-xl font-bold">${hotel.name}</h3>
                            <p class="text-sm">${hotel.country}</p>
                        </div>
                    </div>
                    <div class="p-4">
                        <div class="flex justify-between items-center">
                            <span class="text-gray-600 text-sm">From $${hotel.minPrice}/night</span>
                            <a href="hotel?id=${hotel.id}" class="text-blue-600 hover:text-blue-800 font-medium text-sm">Explore</a>
                        </div>
                    </div>
                </div>
            </c:forEach>
            
            <!-- Fallback static destinations if no data from database -->
            <c:if test="${empty popularHotels}">
                <!-- Destination 1 -->
                <div class="destination-card bg-white rounded-xl overflow-hidden shadow-md">
                    <div class="relative h-48">
                        <img src="https://images.unsplash.com/photo-1483729558449-99ef109a84c7?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80" alt="Paris" class="w-full h-full object-cover">
                        <div class="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent"></div>
                        <div class="absolute bottom-4 left-4 text-white">
                            <h3 class="text-xl font-bold">Paris</h3>
                            <p class="text-sm">France</p>
                        </div>
                    </div>
                    <div class="p-4">
                        <div class="flex justify-between items-center">
                            <span class="text-gray-600 text-sm">From $120/night</span>
                            <a href="hotel?id=1" class="text-blue-600 hover:text-blue-800 font-medium text-sm">Explore</a>
                        </div>
                    </div>
                </div>
                
                <!-- Destination 2 -->
                <div class="destination-card bg-white rounded-xl overflow-hidden shadow-md">
                    <div class="relative h-48">
                        <img src="https://images.unsplash.com/photo-1538970272646-f61fabb3a0a3?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80" alt="New York" class="w-full h-full object-cover">
                        <div class="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent"></div>
                        <div class="absolute bottom-4 left-4 text-white">
                            <h3 class="text-xl font-bold">New York</h3>
                            <p class="text-sm">USA</p>
                        </div>
                    </div>
                    <div class="p-4">
                        <div class="flex justify-between items-center">
                            <span class="text-gray-600 text-sm">From $150/night</span>
                            <a href="hotel?id=2" class="text-blue-600 hover:text-blue-800 font-medium text-sm">Explore</a>
                        </div>
                    </div>
                </div>
                
                <!-- Destination 3 -->
                <div class="destination-card bg-white rounded-xl overflow-hidden shadow-md">
                    <div class="relative h-48">
                        <img src="https://images.unsplash.com/photo-1523482580672-f109ba8cb9be?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80" alt="Tokyo" class="w-full h-full object-cover">
                        <div class="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent"></div>
                        <div class="absolute bottom-4 left-4 text-white">
                            <h3 class="text-xl font-bold">Tokyo</h3>
                            <p class="text-sm">Japan</p>
                        </div>
                    </div>
                    <div class="p-4">
                        <div class="flex justify-between items-center">
                            <span class="text-gray-600 text-sm">From $110/night</span>
                            <a href="hotel?id=3" class="text-blue-600 hover:text-blue-800 font-medium text-sm">Explore</a>
                        </div>
                    </div>
                </div>
                
                <!-- Destination 4 -->
                <div class="destination-card bg-white rounded-xl overflow-hidden shadow-md">
                    <div class="relative h-48">
                        <img src="https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80" alt="Rome" class="w-full h-full object-cover">
                        <div class="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent"></div>
                        <div class="absolute bottom-4 left-4 text-white">
                            <h3 class="text-xl font-bold">Rome</h3>
                            <p class="text-sm">Italy</p>
                        </div>
                    </div>
                    <div class="p-4">
                        <div class="flex justify-between items-center">
                            <span class="text-gray-600 text-sm">From $130/night</span>
                            <a href="hotel?id=4" class="text-blue-600 hover:text-blue-800 font-medium text-sm">Explore</a>
                        </div>
                    </div>
                </div>
            </c:if>
        </div>
        
        <div class="text-center mt-10">
            <a href="destinations.jsp" class="bg-white hover:bg-gray-100 text-gray-800 font-semibold py-2 px-6 border border-gray-300 rounded-lg shadow-sm">
                View All Destinations
            </a>
        </div>
    </section>

    <!-- Why Choose Us -->
    <section class="bg-gray-100 py-16">
        <div class="max-w-7xl mx-auto px-4">
            <div class="text-center mb-12">
                <h2 class="text-3xl md:text-4xl font-bold text-gray-800 mb-4">Why Choose ZAIRTAM</h2>
                <p class="text-lg text-gray-600 max-w-2xl mx-auto">We provide the best experience for your travel needs</p>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
                <div class="bg-white p-6 rounded-xl shadow-sm text-center">
                    <div class="bg-blue-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                        <i class="fas fa-shield-alt text-blue-600 text-2xl"></i>
                    </div>
                    <h3 class="text-xl font-semibold mb-2 text-gray-800">Secure Payments</h3>
                    <p class="text-gray-600">Your transactions are protected with industry-standard encryption</p>
                </div>
                
                <div class="bg-white p-6 rounded-xl shadow-sm text-center">
                    <div class="bg-blue-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                        <i class="fas fa-tag text-blue-600 text-2xl"></i>
                    </div>
                    <h3 class="text-xl font-semibold mb-2 text-gray-800">Best Price Guarantee</h3>
                    <p class="text-gray-600">We guarantee you'll find the best prices for your perfect stay</p>
                </div>
                
                <div class="bg-white p-6 rounded-xl shadow-sm text-center">
                    <div class="bg-blue-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                        <i class="fas fa-headset text-blue-600 text-2xl"></i>
                    </div>
                    <h3 class="text-xl font-semibold mb-2 text-gray-800">24/7 Customer Support</h3>
                    <p class="text-gray-600">Our team is available around the clock to assist you</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer class="bg-gray-800 text-white py-12">
        <div class="max-w-7xl mx-auto px-4">
            <div class="grid grid-cols-1 md:grid-cols-4 gap-8">
                <div>
                    <h3 class="text-xl font-bold mb-4 flex items-center">
                        <i class="fas fa-hotel text-blue-400 mr-2"></i> ZAIRTAM
                    </h3>
                    <p class="text-gray-400">Find your perfect stay anywhere in the world.</p>
                    <div class="flex space-x-4 mt-4">
                        <a href="#" class="text-gray-400 hover:text-white"><i class="fab fa-facebook-f"></i></a>
                        <a href="#" class="text-gray-400 hover:text-white"><i class="fab fa-twitter"></i></a>
                        <a href="#" class="text-gray-400 hover:text-white"><i class="fab fa-instagram"></i></a>
                        <a href="#" class="text-gray-400 hover:text-white"><i class="fab fa-linkedin-in"></i></a>
                    </div>
                </div>
                <div>
                    <h4 class="font-semibold mb-4">Company</h4>
                    <ul class="space-y-2">
                        <li><a href="#" class="text-gray-400 hover:text-white">About Us</a></li>
                        <li><a href="#" class="text-gray-400 hover:text-white">Careers</a></li>
                        <li><a href="#" class="text-gray-400 hover:text-white">Press</a></li>
                        <li><a href="#" class="text-gray-400 hover:text-white">Blog</a></li>
                    </ul>
                </div>
                <div>
                    <h4 class="font-semibold mb-4">Support</h4>
                    <ul class="space-y-2">
                        <li><a href="#" class="text-gray-400 hover:text-white">Help Center</a></li>
                        <li><a href="#" class="text-gray-400 hover:text-white">Safety</a></li>
                        <li><a href="#" class="text-gray-400 hover:text-white">Cancellation</a></li>
                        <li><a href="#" class="text-gray-400 hover:text-white">FAQ</a></li>
                    </ul>
                </div>
                <div>
                    <h4 class="font-semibold mb-4">Contact</h4>
                    <ul class="space-y-2">
                        <li class="text-gray-400"><i class="fas fa-map-marker-alt mr-2"></i> 123 Travel St, New York</li>
                        <li class="text-gray-400"><i class="fas fa-phone mr-2"></i> +1 (555) 123-4567</li>
                        <li class="text-gray-400"><i class="fas fa-envelope mr-2"></i> contact@zairtam.com</li>
                    </ul>
                </div>
            </div>
            <div class="border-t border-gray-700 mt-8 pt-8 text-center text-gray-400">
                <p>&copy; <%= java.time.Year.now().getValue() %> ZAIRTAM. All rights reserved.</p>
            </div>
        </div>
    </footer>

    <script>
        // Mobile menu toggle
        const mobileMenuButton = document.getElementById('mobile-menu-button');
        const mobileMenu = document.getElementById('mobile-menu');
        
        mobileMenuButton.addEventListener('click', () => {
            mobileMenu.classList.toggle('hidden');
        });
        
        // Language dropdown functionality would go here
        // Search form submission would go here
    </script>
</body>
</html>