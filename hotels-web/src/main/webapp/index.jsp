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
    <jsp:include page="WEB-INF/components/header.jsp" />

    <!-- Hero Banner -->
    <section class="hero-banner flex items-center justify-center text-white relative">
        <div class="text-center px-4">
            <h1 class="text-4xl md:text-5xl font-bold mb-4">Find Your Perfect Stay</h1>
            <p class="text-xl md:text-2xl mb-8">Discover amazing hotels, resorts, and apartments worldwide</p>
        </div>
        
        <!-- Search Box -->
        <div class="search-box absolute w-full max-w-5xl px-4">
            <div class="bg-white rounded-lg shadow-xl p-4 md:p-6">
                <form action="search-results.jsp" method="post">
                    <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
                        <div>
                            <label for="destination" class="block text-sm font-medium text-gray-700 mb-1">Destination</label>
                            <div class="relative">
                                <input type="text" id="destination" name="destination" placeholder="Where are you going?" class="w-full px-4 py-3 border rounded-lg focus:ring-blue-500 focus:border-blue-500 text-black" autocomplete="off">
                                <i class="fas fa-map-marker-alt absolute right-3 top-3.5 text-gray-400"></i>
                                <!-- Destination suggestions dropdown -->
                                <div id="destination-suggestions" class="absolute z-10 w-full bg-white mt-1 rounded-md shadow-lg hidden">
                                    <!-- Suggestions will be populated here -->
                                </div>
                            </div>
                        </div>
                        
                        <div>
                            <label for="check-in" class="block text-sm font-medium text-gray-700 mb-1">Check-in</label>
                            <input type="text" id="check-in" name="checkIn" class="w-full px-4 py-3 border rounded-lg focus:ring-blue-500 focus:border-blue-500 text-black" placeholder="Select date" readonly>
                        </div>
                        
                        <div>
                            <label for="check-out" class="block text-sm font-medium text-gray-700 mb-1">Check-out</label>
                            <input type="text" id="check-out" name="checkOut" class="w-full px-4 py-3 border rounded-lg focus:ring-blue-500 focus:border-blue-500 text-black" placeholder="Select date" readonly>
                        </div>
                        
                        <div>
                            <label for="guests" class="block text-sm font-medium text-gray-700 mb-1">Guests</label>
                            <div class="relative">
                                <input type="text" id="guests-display" readonly value="1 room, 2 guests" class="w-full px-4 py-3 border rounded-lg focus:ring-blue-500 focus:border-blue-500 cursor-pointer text-black">
                                <input type="hidden" id="guests" name="guests" value="1,2,0">
                                <i class="fas fa-user absolute right-3 top-3.5 text-gray-400"></i>
                                
                                <!-- Guests dropdown -->
                                <div id="guests-dropdown" class="absolute z-10 w-full bg-white mt-1 rounded-md shadow-lg p-4 hidden">
                                    <div class="mb-3">
                                        <div class="flex justify-between items-center">
                                            <span class="font-medium text-black">Adults</span>
                                            <div class="flex items-center">
                                                <button type="button" class="w-8 h-8 flex items-center justify-center bg-gray-200 rounded-full" id="adults-minus">
                                                    <i class="fas fa-minus text-sm"></i>
                                                </button>
                                                <span class="mx-3 w-6 text-center text-black" id="adults-count">2</span>
                                                <button type="button" class="w-8 h-8 flex items-center justify-center bg-gray-200 rounded-full" id="adults-plus">
                                                    <i class="fas fa-plus text-sm"></i>
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="mb-3">
                                        <div class="flex justify-between items-center">
                                            <span class="font-medium text-black">Children</span>
                                            <div class="flex items-center">
                                                <button type="button" class="w-8 h-8 flex items-center justify-center bg-gray-200 rounded-full" id="children-minus">
                                                    <i class="fas fa-minus text-sm"></i>
                                                </button>
                                                <span class="mx-3 w-6 text-center text-black" id="children-count">0</span>
                                                <button type="button" class="w-8 h-8 flex items-center justify-center bg-gray-200 rounded-full" id="children-plus">
                                                    <i class="fas fa-plus text-sm"></i>
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                    <div>
                                        <div class="flex justify-between items-center">
                                            <span class="font-medium text-black">Rooms</span>
                                            <div class="flex items-center">
                                                <button type="button" class="w-8 h-8 flex items-center justify-center bg-gray-200 rounded-full" id="rooms-minus">
                                                    <i class="fas fa-minus text-sm"></i>
                                                </button>
                                                <span class="mx-3 w-6 text-center text-black" id="rooms-count">1</span>
                                                <button type="button" class="w-8 h-8 flex items-center justify-center bg-gray-200 rounded-full" id="rooms-plus">
                                                    <i class="fas fa-plus text-sm"></i>
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                    <button type="button" class="w-full mt-4 bg-blue-600 text-white py-2 rounded-md" id="apply-guests">Apply</button>
                                </div>
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
                        <img src="https://img.static-af.com/transform/45cb9a13-b167-4842-8ea8-05d0cc7a4d04/" alt="Paris" class="w-full h-full object-cover">
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
                        <img src="https://images.unsplash.com/photo-1538970272646-f61fabb3a0a3?auto=format&fit=crop&w=1470&q=80" alt="New York" class="w-full h-full object-cover">
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

    <script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">
    <!-- Add this script before the closing </body> tag -->
    <script>
    document.addEventListener('DOMContentLoaded', function() {
        // Initial values
        let adults = 2;
        let children = 0;
        let rooms = 1;
    
        // Elements
        const adultsCount = document.getElementById('adults-count');
        const childrenCount = document.getElementById('children-count');
        const roomsCount = document.getElementById('rooms-count');
        const guestsDisplay = document.getElementById('guests-display');
        const guestsHidden = document.getElementById('guests');
        const guestsDropdown = document.getElementById('guests-dropdown');
        const applyGuests = document.getElementById('apply-guests');
    
        // Show/hide dropdown
        guestsDisplay.addEventListener('click', function(e) {
            e.stopPropagation();
            guestsDropdown.classList.toggle('hidden');
        });
    
        // Adults
        document.getElementById('adults-plus').onclick = function() {
            adults++;
            adultsCount.textContent = adults;
        };
        document.getElementById('adults-minus').onclick = function() {
            if (adults > 1) {
                adults--;
                adultsCount.textContent = adults;
            }
        };
    
        // Children
        document.getElementById('children-plus').onclick = function() {
            children++;
            childrenCount.textContent = children;
        };
        document.getElementById('children-minus').onclick = function() {
            if (children > 0) {
                children--;
                childrenCount.textContent = children;
            }
        };
    
        // Rooms
        document.getElementById('rooms-plus').onclick = function() {
            rooms++;
            roomsCount.textContent = rooms;
        };
        document.getElementById('rooms-minus').onclick = function() {
            if (rooms > 1) {
                rooms--;
                roomsCount.textContent = rooms;
            }
        };
    
        // Apply button
        applyGuests.addEventListener('click', function() {
            guestsDropdown.classList.add('hidden');
            let displayText = rooms + ' room' + (rooms > 1 ? 's' : '') + ', ' + adults + ' guest' + (adults > 1 ? 's' : '');
            if (children > 0) {
                displayText += ', ' + children + ' child' + (children > 1 ? 'ren' : '');
            }
            guestsDisplay.value = displayText;
    
            // Only include children in the hidden input if > 0
            if (children > 0) {
                guestsHidden.value = rooms + ',' + adults + ',' + children;
            } else {
                guestsHidden.value = rooms + ',' + adults;
            }
        });
    
        // Optional: Close dropdown when clicking outside
        document.addEventListener('click', function(event) {
            if (!guestsDisplay.contains(event.target) && !guestsDropdown.contains(event.target)) {
                guestsDropdown.classList.add('hidden');
            }
        });
    });
  
    
    // Hide dropdown when clicking outside
    document.addEventListener('click', function(e) {
        if (!guestsDisplay.contains(e.target) && !guestsDropdown.contains(e.target)) {
            guestsDropdown.classList.add('hidden');
        }
    });
    
    // Update guest counts
    function updateGuestCounts() {
        const adults = parseInt(adultsCount.textContent);
        const children = parseInt(childrenCount.textContent);
        const rooms = parseInt(roomsCount.textContent);
    
        // Update hidden input value
        guestsInput.value = `${rooms},${adults},${children}`;
    
        // Update display text
        const roomText = rooms === 1 ? 'room' : 'rooms';
        const guestText = (adults + children) === 1 ? 'guest' : 'guests';
        guestsDisplay.value = `${rooms} ${roomText}, ${adults + children} ${guestText}`;
    
        // Disable minus buttons if count is at minimum
        adultsMinus.disabled = adults <= 1;
        adultsMinus.classList.toggle('opacity-50', adults <= 1);
    
        childrenMinus.disabled = children <= 0;
        childrenMinus.classList.toggle('opacity-50', children <= 0);
    
        roomsMinus.disabled = rooms <= 1;
        roomsMinus.classList.toggle('opacity-50', rooms <= 1);
    }
    
    // Initialize guest counts
    updateGuestCounts();
    
    // Add event listeners for plus/minus buttons
    adultsPlus.addEventListener('click', function() {
        const current = parseInt(adultsCount.textContent);
        if (current < 10) {
            adultsCount.textContent = current + 1;
            updateGuestCounts();
        }
    });
    
    adultsMinus.addEventListener('click', function() {
        const current = parseInt(adultsCount.textContent);
        if (current > 1) {
            adultsCount.textContent = current - 1;
            updateGuestCounts();
        }
    });
    
    childrenPlus.addEventListener('click', function() {
        const current = parseInt(childrenCount.textContent);
        if (current < 6) {
            childrenCount.textContent = current + 1;
            updateGuestCounts();
        }
    });
    
    childrenMinus.addEventListener('click', function() {
        const current = parseInt(childrenCount.textContent);
        if (current > 0) {
            childrenCount.textContent = current - 1;
            updateGuestCounts();
        }
    });
    
    roomsPlus.addEventListener('click', function() {
        const current = parseInt(roomsCount.textContent);
        if (current < 5) {
            roomsCount.textContent = current + 1;
            updateGuestCounts();
        }
    });
    
    roomsMinus.addEventListener('click', function() {
        const current = parseInt(roomsCount.textContent);
        if (current > 1) {
            roomsCount.textContent = current - 1;
            updateGuestCounts();
        }
    });
    
    // Apply button
    applyButton.addEventListener('click', function() {
        const adults = parseInt(adultsCount.textContent);
        const children = parseInt(childrenCount.textContent);
        const rooms = parseInt(roomsCount.textContent);
    
        // Update display text
        const roomText = rooms === 1 ? 'room' : 'rooms';
        const guestText = (adults + children) === 1 ? 'guest' : 'guests';
        guestsDisplay.value = `${rooms} ${roomText}, ${adults + children} ${guestText}`;
    
        guestsDropdown.classList.add('hidden');
    });

</script>
    <script>
        // Initialize flatpickr for check-in and check-out
        flatpickr("#check-in", {
            dateFormat: "Y-m-d",
            minDate: "today",
            onChange: function(selectedDates, dateStr, instance) {
                // Set the minimum date for check-out to be the day after check-in
                if(selectedDates.length > 0) {
                    let minCheckout = new Date(selectedDates[0]);
                    minCheckout.setDate(minCheckout.getDate() + 1);
                    flatpickr("#check-out", {
                        dateFormat: "Y-m-d",
                        minDate: minCheckout
                    });
                }
            }
        });
        flatpickr("#check-out", {
            dateFormat: "Y-m-d",
            minDate: "today"
        });
    </script>
    <script>
        /* ---------- AUTOCOMPLETE “Destination” ---------- */
        (() => {
          const input        = document.getElementById("destination");
          const box          = document.getElementById("destination-suggestions");
          let   debounceId   = null;
        
          // Fermer la liste lorsqu’on clique ailleurs
          document.addEventListener("click", () => box.classList.add("hidden"));
        
          // Gère la frappe utilisateur
          input.addEventListener("input", () => {
              const q = input.value.trim();
              clearTimeout(debounceId);
              if (q.length < 2) {                       // On attend ≥2 caractères
                  box.innerHTML = "";
                  box.classList.add("hidden");
                  return;
              }
              debounceId = setTimeout(() => fetchSuggest(q), 300); // 300 ms de pause
          });
        
          function fetchSuggest(query) {
              fetch(`<c:url value='/autocomplete'/>?query=` + encodeURIComponent(query))
                  .then(r => r.ok ? r.json() : [])
                  .then(showSuggestions)
                  .catch(() => { box.classList.add("hidden"); });
          }
        
          function showSuggestions(arr) {
              if (!arr.length) { box.classList.add("hidden"); return; }
              box.innerHTML = arr.map(d =>
                  `<div class="px-4 py-2 cursor-pointer hover:bg-gray-100"
                        data-city="${d.city}" data-country="${d.country}">
                      <span class="font-medium">${d.city}</span>,
                      <span class="text-gray-500 text-sm">${d.country}</span>
                   </div>`).join("");
              box.classList.remove("hidden");
        
              // Click sur un item ⇒ remplit le champ + ferme
              [...box.children].forEach(div =>
                  div.addEventListener("click", () => {
                      input.value = div.dataset.city + ", " + div.dataset.country;
                      box.classList.add("hidden");
                  }));
          }
        })();
        </script>
        
</body>
</html>