<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    // Database connection parameters
    String jdbcURL = "jdbc:mysql://localhost:3306/hotels_db"; // Change to your database name
    String dbUser = "root"; // Change to your database username
    String password = ""; // Change to your database password
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    // Search parameters
    String destination = request.getParameter("destination");
    String checkIn = request.getParameter("checkIn");
    String checkOut = request.getParameter("checkOut");
    String guests = request.getParameter("guests");
    String maxPrice = request.getParameter("maxPrice");
    String starRating = request.getParameter("starRating");
    
    // List to store search results
    List<Map<String, Object>> hotelResults = new ArrayList<>();
    
    try {
        // Establish database connection
        Class.forName("com.mysql.jdbc.Driver");
        conn = DriverManager.getConnection(jdbcURL, dbUser, password);
        
        // Build the search query
        StringBuilder queryBuilder = new StringBuilder();
        queryBuilder.append("SELECT h.hotel_id, h.name, h.description, h.address_line1, h.city, h.country, ");
        queryBuilder.append("h.rating, rt.base_price, COUNT(r.room_id) as available_rooms ");
        queryBuilder.append("FROM hotels h ");
        queryBuilder.append("JOIN room_types rt ON h.hotel_id = rt.hotel_id ");
        queryBuilder.append("JOIN rooms r ON rt.room_type_id = r.room_type_id ");
        queryBuilder.append("WHERE r.status = 'available' ");
        
        // Add search filters
        if (destination != null && !destination.isEmpty()) {
            queryBuilder.append("AND (h.city LIKE ? OR h.country LIKE ?) ");
        }
        
        if (maxPrice != null && !maxPrice.isEmpty()) {
            queryBuilder.append("AND rt.base_price <= ? ");
        }
        
        if (starRating != null && !starRating.isEmpty()) {
            queryBuilder.append("AND h.rating >= ? ");
        }
        
        // Group by hotel
        queryBuilder.append("GROUP BY h.hotel_id, rt.room_type_id ");
        queryBuilder.append("HAVING available_rooms > 0 ");
        queryBuilder.append("ORDER BY h.rating DESC, rt.base_price ASC");
        
        pstmt = conn.prepareStatement(queryBuilder.toString());
        
        // Set query parameters
        int paramIndex = 1;
        if (destination != null && !destination.isEmpty()) {
            pstmt.setString(paramIndex++, "%" + destination + "%");
            pstmt.setString(paramIndex++, "%" + destination + "%");
        }
        
        if (maxPrice != null && !maxPrice.isEmpty()) {
            pstmt.setDouble(paramIndex++, Double.parseDouble(maxPrice));
        }
        
        if (starRating != null && !starRating.isEmpty()) {
            pstmt.setDouble(paramIndex++, Double.parseDouble(starRating));
        }
        
        // Execute query
        rs = pstmt.executeQuery();
        
        // Process results
        while (rs.next()) {
            Map<String, Object> hotel = new HashMap<>();
            hotel.put("id", rs.getLong("hotel_id"));
            hotel.put("name", rs.getString("name"));
            hotel.put("description", rs.getString("description"));
            hotel.put("address", rs.getString("address_line1"));
            hotel.put("city", rs.getString("city"));
            hotel.put("country", rs.getString("country"));
            hotel.put("rating", rs.getDouble("rating"));
            hotel.put("price", rs.getDouble("base_price"));
            hotel.put("availableRooms", rs.getInt("available_rooms"));
            
            // Add placeholder image URL (you can replace this with actual image URLs from your database)
            hotel.put("imageUrl", "https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=80");
            
            hotelResults.add(hotel);
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
    
    // Store results in request attribute for display in JSP
    request.setAttribute("hotelResults", hotelResults);
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZAIRTAM - Hotel Search Results</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
        }
        
        .hotel-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
        }
        
        .hotel-card {
            transition: all 0.3s ease;
        }
        
        .star-rating .fas {
            color: #FFD700;
        }
        
        .star-rating .far {
            color: #E5E7EB;
        }
        
        input[type="range"]::-webkit-slider-thumb {
            -webkit-appearance: none;
            appearance: none;
            width: 18px;
            height: 18px;
            background: #3B82F6;
            border-radius: 50%;
            cursor: pointer;
        }
        
        @media (max-width: 768px) {
            .filters-sidebar {
                position: fixed;
                top: 0;
                left: 0;
                height: 100vh;
                width: 80%;
                max-width: 300px;
                z-index: 50;
                transform: translateX(-100%);
                transition: transform 0.3s ease;
            }
            
            .filters-sidebar.open {
                transform: translateX(0);
            }
        }
    </style>
</head>
<body class="bg-gray-50">
    <!-- Navigation -->
    <jsp:include page="WEB-INF/components/header.jsp" />

    <!-- Search Results Header -->
    <div class="bg-blue-600 py-8">
        <div class="max-w-7xl mx-auto px-4">
            <div class="flex flex-col md:flex-row justify-between items-start md:items-center">
                <div class="text-white mb-4 md:mb-0">
                    <h1 class="text-2xl font-bold">Hotels in ${param.destination}</h1>
                    <p class="text-blue-100">${param.checkIn} - ${param.checkOut} · ${param.guests}</p>
                </div>
                
                <div class="bg-white rounded-lg shadow-sm p-3 w-full md:w-auto">
                    <form action="search" method="post">
                        <div class="flex flex-col md:flex-row space-y-2 md:space-y-0 md:space-x-4">
                            <div class="relative">
                                <input type="text" name="destination" value="${param.destination}" class="w-full md:w-48 px-3 py-2 border rounded-md text-sm">
                                <i class="fas fa-map-marker-alt absolute right-3 top-2.5 text-gray-400"></i>
                            </div>
                            
                            <div class="flex space-x-2">
                                <input type="date" name="checkIn" value="${param.checkIn}" class="w-28 px-2 py-2 border rounded-md text-sm">
                                <input type="date" name="checkOut" value="${param.checkOut}" class="w-28 px-2 py-2 border rounded-md text-sm">
                            </div>
                            
                            <div class="relative">
                                <input type="text" name="guests" value="${param.guests}" class="w-full md:w-32 px-3 py-2 border rounded-md text-sm">
                                <i class="fas fa-user absolute right-3 top-2.5 text-gray-400"></i>
                            </div>
                            
                            <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium">
                                <i class="fas fa-search mr-1"></i> Search
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- Main Content -->
    <div class="max-w-7xl mx-auto px-4 py-8">
        <div class="flex flex-col lg:flex-row gap-6">
            <!-- Filters Sidebar -->
            <div class="lg:w-1/4">
                <div class="bg-white rounded-lg shadow-sm p-5 sticky top-20 filters-sidebar">
                    <div class="flex justify-between items-center mb-6">
                        <h2 class="text-lg font-semibold">Filters</h2>
                        <button id="close-filters" class="lg:hidden text-gray-500 hover:text-gray-700">
                            <i class="fas fa-times"></i>
                        </button>
                    </div>
                    
                    <!-- Price Range Filter -->
                    <form id="filter-form" action="search" method="post">
                        <!-- Hidden fields to maintain search parameters -->
                        <input type="hidden" name="destination" value="${param.destination}">
                        <input type="hidden" name="checkIn" value="${param.checkIn}">
                        <input type="hidden" name="checkOut" value="${param.checkOut}">
                        <input type="hidden" name="guests" value="${param.guests}">
                        
                        <div class="mb-6">
                            <h3 class="font-medium mb-3">Price Range</h3>
                            <div class="mb-4">
                                <input type="range" name="maxPrice" min="0" max="500" value="${param.maxPrice != null ? param.maxPrice : 300}" class="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer" id="price-range">
                            </div>
                            <div class="flex justify-between">
                                <span class="text-sm text-gray-600">$0</span>
                                <span class="text-sm text-gray-600" id="price-display">Max: $${param.maxPrice != null ? param.maxPrice : 300}</span>
                            </div>
                        </div>
                        
                        <!-- Star Rating Filter -->
                        <div class="mb-6 star-rating-filter">
                            <h3 class="font-medium mb-3">Star Rating</h3>
                            <div class="space-y-2">
                                <label class="flex items-center">
                                    <input type="checkbox" name="starRating" value="5" ${param.starRating == '5' ? 'checked' : ''} class="form-checkbox h-4 w-4 text-blue-600">
                                    <span class="ml-2 text-sm">
                                        <i class="fas fa-star text-yellow-400"></i>
                                        <i class="fas fa-star text-yellow-400"></i>
                                        <i class="fas fa-star text-yellow-400"></i>
                                        <i class="fas fa-star text-yellow-400"></i>
                                        <i class="fas fa-star text-yellow-400"></i>
                                    </span>
                                </label>
                                <label class="flex items-center">
                                    <input type="checkbox" name="starRating" value="4" ${param.starRating == '4' ? 'checked' : ''} class="form-checkbox h-4 w-4 text-blue-600">
                                    <span class="ml-2 text-sm">
                                        <i class="fas fa-star text-yellow-400"></i>
                                        <i class="fas fa-star text-yellow-400"></i>
                                        <i class="fas fa-star text-yellow-400"></i>
                                        <i class="fas fa-star text-yellow-400"></i>
                                    </span>
                                </label>
                                <label class="flex items-center">
                                    <input type="checkbox" name="starRating" value="3" ${param.starRating == '3' ? 'checked' : ''} class="form-checkbox h-4 w-4 text-blue-600">
                                    <span class="ml-2 text-sm">
                                        <i class="fas fa-star text-yellow-400"></i>
                                        <i class="fas fa-star text-yellow-400"></i>
                                        <i class="fas fa-star text-yellow-400"></i>
                                    </span>
                                </label>
                                <label class="flex items-center">
                                    <input type="checkbox" name="starRating" value="2" ${param.starRating == '2' ? 'checked' : ''} class="form-checkbox h-4 w-4 text-blue-600">
                                    <span class="ml-2 text-sm">
                                        <i class="fas fa-star text-yellow-400"></i>
                                        <i class="fas fa-star text-yellow-400"></i>
                                    </span>
                                </label>
                            </div>
                        </div>
                        
                        <!-- Amenities Filter -->
                        <div class="mb-6">
                            <h3 class="font-medium mb-3">Amenities</h3>
                            <div class="space-y-2">
                                <label class="flex items-center">
                                    <input type="checkbox" name="amenities" value="wifi" ${param.amenities == 'wifi' ? 'checked' : ''} class="form-checkbox h-4 w-4 text-blue-600">
                                    <span class="ml-2 text-sm">Free WiFi</span>
                                </label>
                                <label class="flex items-center">
                                    <input type="checkbox" name="amenities" value="breakfast" ${param.amenities == 'breakfast' ? 'checked' : ''} class="form-checkbox h-4 w-4 text-blue-600">
                                    <span class="ml-2 text-sm">Breakfast Included</span>
                                </label>
                                <label class="flex items-center">
                                    <input type="checkbox" name="amenities" value="pool" ${param.amenities == 'pool' ? 'checked' : ''} class="form-checkbox h-4 w-4 text-blue-600">
                                    <span class="ml-2 text-sm">Swimming Pool</span>
                                </label>
                                <label class="flex items-center">
                                    <input type="checkbox" name="amenities" value="parking" ${param.amenities == 'parking' ? 'checked' : ''} class="form-checkbox h-4 w-4 text-blue-600">
                                    <span class="ml-2 text-sm">Parking</span>
                                </label>
                                <label class="flex items-center">
                                    <input type="checkbox" name="amenities" value="ac" ${param.amenities == 'ac' ? 'checked' : ''} class="form-checkbox h-4 w-4 text-blue-600">
                                    <span class="ml-2 text-sm">Air Conditioning</span>
                                </label>
                                <label class="flex items-center">
                                    <input type="checkbox" name="amenities" value="pet" ${param.amenities == 'pet' ? 'checked' : ''} class="form-checkbox h-4 w-4 text-blue-600">
                                    <span class="ml-2 text-sm">Pet Friendly</span>
                                </label>
                            </div>
                        </div>
                        
                        <!-- Availability Filter -->
                        <div class="mb-6">
                            <h3 class="font-medium mb-3">Availability</h3>
                            <div class="space-y-2">
                                <label class="flex items-center">
                                    <input type="checkbox" name="available" value="true" ${param.available == 'true' ? 'checked' : ''} class="form-checkbox h-4 w-4 text-blue-600" checked>
                                    <span class="ml-2 text-sm">Show only available hotels</span>
                                </label>
                            </div>
                        </div>
                        
                        <button type="submit" class="w-full bg-blue-600 hover:bg-blue-700 text-white py-2 rounded-md font-medium">
                            Apply Filters
                        </button>
                    </form>
                </div>
            </div>
            
            <!-- Hotel Results -->
            <div class="lg:w-3/4">
                <div class="mb-4 flex justify-between items-center">
                    <h2 class="text-lg font-semibold">${hotelResults.size()} hotels found</h2>
                    <div class="flex items-center">
                        <span class="text-sm text-gray-600 mr-2">Sort by:</span>
                        <select class="border rounded-md px-2 py-1 text-sm">
                            <option>Recommended</option>
                            <option>Price (low to high)</option>
                            <option>Price (high to low)</option>
                            <option>Rating (high to low)</option>
                        </select>
                    </div>
                </div>
                
                <!-- Hotel Cards -->
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mt-6">
                    <c:forEach items="${hotelResults}" var="hotel">
                        <div class="hotel-card bg-white rounded-lg shadow-sm overflow-hidden">
                            <div class="relative">
                                <img src="${hotel.imageUrl}" alt="${hotel.name}" class="w-full h-48 object-cover">
                                <div class="absolute top-2 right-2 bg-white rounded-full p-2 shadow-sm">
                                    <div class="star-rating">
                                        <c:forEach begin="1" end="5" var="i">
                                            <c:choose>
                                                <c:when test="${i <= hotel.rating}">
                                                    <i class="fas fa-star"></i>
                                                </c:when>
                                                <c:otherwise>
                                                    <i class="far fa-star"></i>
                                                </c:otherwise>
                                            </c:choose>
                                        </c:forEach>
                                    </div>
                                </div>
                            </div>
                            
                            <div class="p-4">
                                <h3 class="text-lg font-bold text-gray-800">${hotel.name}</h3>
                                <p class="text-gray-600 text-sm mb-2">
                                    <i class="fas fa-map-marker-alt mr-1"></i> ${hotel.city}, ${hotel.country}
                                </p>
                                
                                <p class="text-sm text-gray-600 mb-3 line-clamp-2">${hotel.description}</p>
                                
                                <div class="flex justify-between items-center mt-4">
                                    <div>
                                        <span class="text-lg font-bold text-gray-800">$${hotel.price}</span>
                                        <span class="text-gray-600 text-sm">/night</span>
                                    </div>
                                    
                                    <a href="reservation.jsp?hotelId=${hotel.id}&checkIn=${param.checkIn}&checkOut=${param.checkOut}&guests=${param.guests}" 
                                       class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium">
                                        Reserve
                                    </a>
                                </div>
                                
                                <div class="text-sm text-gray-600 mt-2">
                                    <i class="fas fa-door-open mr-1"></i> ${hotel.availableRooms} rooms available
                                </div>
                            </div>
                        </div>
                    </c:forEach>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Footer -->
    <footer class="bg-gray-800 text-white py-12">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="grid grid-cols-1 md:grid-cols-4 gap-8">
                <div>
                    <div class="flex items-center mb-4">
                        <i class="fas fa-hotel text-blue-400 text-2xl mr-2"></i>
                        <span class="text-xl font-bold">ZAIRTAM</span>
                    </div>
                    <p class="text-gray-400 text-sm mb-4">
                        Find the perfect accommodation for your next trip with ZAIRTAM, your trusted hotel booking platform.
                    </p>
                    <div class="flex space-x-4">
                        <a href="#" class="text-gray-400 hover:text-white">
                            <i class="fab fa-facebook-f"></i>
                        </a>
                        <a href="#" class="text-gray-400 hover:text-white">
                            <i class="fab fa-twitter"></i>
                        </a>
                        <a href="#" class="text-gray-400 hover:text-white">
                            <i class="fab fa-instagram"></i>
                        </a>
                        <a href="#" class="text-gray-400 hover:text-white">
                            <i class="fab fa-linkedin-in"></i>
                        </a>
                    </div>
                </div>
                
                <div>
                    <h3 class="text-lg font-semibold mb-4">Quick Links</h3>
                    <ul class="space-y-2 text-gray-400">
                        <li><a href="index.jsp" class="hover:text-white">Home</a></li>
                        <li><a href="search.jsp" class="hover:text-white">Search</a></li>
                        <li><a href="deals.jsp" class="hover:text-white">Deals</a></li>
                        <li><a href="about.jsp" class="hover:text-white">About Us</a></li>
                        <li><a href="contact.jsp" class="hover:text-white">Contact</a></li>
                    </ul>
                </div>
                
                <div>
                    <h3 class="text-lg font-semibold mb-4">Support</h3>
                    <ul class="space-y-2 text-gray-400">
                        <li><a href="#" class="hover:text-white">Help Center</a></li>
                        <li><a href="#" class="hover:text-white">FAQs</a></li>
                        <li><a href="#" class="hover:text-white">Cancellation Policy</a></li>
                        <li><a href="#" class="hover:text-white">Privacy Policy</a></li>
                        <li><a href="#" class="hover:text-white">Terms of Service</a></li>
                    </ul>
                </div>
                
                <div>
                    <h3 class="text-lg font-semibold mb-4">Contact Us</h3>
                    <ul class="space-y-2 text-gray-400">
                        <li class="flex items-start">
                            <i class="fas fa-map-marker-alt mt-1 mr-2"></i>
                            <span>123 Hotel Street, City, Country</span>
                        </li>
                        <li class="flex items-start">
                            <i class="fas fa-phone-alt mt-1 mr-2"></i>
                            <span>+1 234 567 8900</span>
                        </li>
                        <li class="flex items-start">
                            <i class="fas fa-envelope mt-1 mr-2"></i>
                            <span>info@zairtam.com</span>
                        </li>
                    </ul>
                    
                    <div class="mt-4">
                        <h4 class="text-sm font-semibold mb-2">Subscribe to our newsletter</h4>
                        <div class="flex">
                            <input type="email" placeholder="Your email" class="px-3 py-2 text-sm text-gray-800 bg-gray-100 rounded-l-md focus:outline-none w-full">
                            <button class="bg-blue-600 hover:bg-blue-700 text-white px-3 py-2 rounded-r-md text-sm">
                                <i class="fas fa-paper-plane"></i>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="border-t border-gray-700 mt-8 pt-8 text-center text-gray-400 text-sm">
                <p>&copy; 2023 ZAIRTAM. All rights reserved.</p>
            </div>
        </div>
    </footer>

    <!-- JavaScript -->
    <script>
        // Mobile menu toggle
        const mobileMenuButton = document.getElementById('mobile-menu-button');
        const mobileMenu = document.getElementById('mobile-menu');
        
        mobileMenuButton.addEventListener('click', () => {
            mobileMenu.classList.toggle('hidden');
        });
        
        // Filters sidebar toggle for mobile
        const showFiltersButton = document.getElementById('show-filters');
        const closeFiltersButton = document.getElementById('close-filters');
        const filtersSidebar = document.querySelector('.filters-sidebar');
        
        if (showFiltersButton) {
            showFiltersButton.addEventListener('click', () => {
                filtersSidebar.classList.add('open');
                document.body.style.overflow = 'hidden'; // Prevent scrolling
            });
        }
        
        if (closeFiltersButton) {
            closeFiltersButton.addEventListener('click', () => {
                filtersSidebar.classList.remove('open');
                document.body.style.overflow = ''; // Re-enable scrolling
            });
        }
        
        // Price range slider
        const priceRange = document.getElementById('price-range');
        const priceDisplay = document.getElementById('price-display');
        
        if (priceRange && priceDisplay) {
            priceRange.addEventListener('input', () => {
                priceDisplay.textContent = `Max: $${priceRange.value}`;
            });
        }
        
        // Sorting functionality
        const sortSelect = document.getElementById('sort-select');
        const hotelResults = document.getElementById('hotel-results');
        
        if (sortSelect && hotelResults) {
            sortSelect.addEventListener('change', () => {
                const sortValue = sortSelect.value;
                const hotelCards = Array.from(hotelResults.querySelectorAll('.hotel-card'));
                
                hotelCards.sort((a, b) => {
                    if (sortValue === 'price-asc') {
                        return parseFloat(a.dataset.price) - parseFloat(b.dataset.price);
                    } else if (sortValue === 'price-desc') {
                        return parseFloat(b.dataset.price) - parseFloat(a.dataset.price);
                    } else if (sortValue === 'rating-desc') {
                        return parseFloat(b.dataset.rating) - parseFloat(a.dataset.rating);
                    }
                    // Default: recommended (no sorting)
                    return 0;
                });
                
                // Clear and re-append sorted hotel cards
                hotelResults.innerHTML = '';
                hotelCards.forEach(card => {
                    hotelResults.appendChild(card);
                });
                
                // Update URL with sort parameter
                const urlParams = new URLSearchParams(window.location.search);
                urlParams.set('sort', sortValue);
                const newUrl = window.location.pathname + '?' + urlParams.toString();
                history.replaceState(null, '', newUrl);
            });
        }
        
        // Handle form submission with all parameters
        document.getElementById('filter-form').addEventListener('submit', function(e) {
            e.preventDefault();
            
            // Get current URL parameters
            const urlParams = new URLSearchParams(window.location.search);
            
            // Add sort parameter if it exists
            if (sortSelect && sortSelect.value) {
                this.elements['sort'].value = sortSelect.value;
            }
            
            // Submit the form
            this.submit();
        });
    </script>
</body>
</html>
