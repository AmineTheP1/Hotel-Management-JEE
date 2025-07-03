<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ZAIRTAM - Register</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
        
        body {
            font-family: 'Poppins', sans-serif;
            background-color: #F9FAFB;
        }
        
        .form-container {
            animation: fadeIn 0.5s ease-in-out;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(-10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        .input-field:focus {
            border-color: #3B82F6;
            box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
        }
        
        .role-option {
            transition: all 0.3s ease;
        }
        
        .role-option.selected {
            border-color: #3B82F6;
            background-color: rgba(59, 130, 246, 0.1);
        }
    </style>
</head>
<body class="bg-gray-50 min-h-screen flex flex-col">
    <div class="flex-1 flex items-center justify-center px-4 sm:px-6 lg:px-8 py-12">
        <div class="max-w-md w-full form-container">
            <!-- Logo -->
            <div class="text-center mb-10">
                <div class="flex items-center justify-center">
                    <i class="fas fa-hotel text-blue-600 text-4xl mr-2"></i>
                    <h1 class="text-3xl font-bold text-gray-800">ZAIRTAM</h1>
                </div>
                <p class="mt-2 text-gray-600">Create your account</p>
            </div>
            
            <!-- Error message if email exists -->
            <c:if test="${not empty errorMessage}">
                <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
                    <p>${errorMessage}</p>
                </div>
            </c:if>
            
            <!-- Register Form -->
            <div class="bg-white rounded-lg shadow-sm p-8">
                <form id="registerForm" class="space-y-6" action="RegisterServlet" method="post">
                    <!-- Role Selection -->
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-3">Select your role</label>
                        <div class="grid grid-cols-2 gap-4">
                            <div id="clientRole" class="role-option cursor-pointer border rounded-lg p-4 text-center selected">
                                <i class="fas fa-user text-2xl mb-2 text-blue-600"></i>
                                <p class="font-medium">Client</p>
                                <p class="text-xs text-gray-500 mt-1">Book hotels and manage reservations</p>
                            </div>
                            <div id="managerRole" class="role-option cursor-pointer border rounded-lg p-4 text-center">
                                <i class="fas fa-hotel text-2xl mb-2 text-gray-600"></i>
                                <p class="font-medium">Hotel Manager</p>
                                <p class="text-xs text-gray-500 mt-1">List and manage your properties</p>
                            </div>
                        </div>
                        <input type="hidden" id="role" name="role" value="client">
                    </div>
                    
                    <!-- Name Fields -->
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label for="firstName" class="block text-sm font-medium text-gray-700 mb-1">First Name</label>
                            <input id="firstName" name="firstName" type="text" required 
                                class="input-field w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none transition duration-200"
                                placeholder="John">
                            <p id="firstNameError" class="mt-1 text-sm text-red-600 hidden">First name is required</p>
                        </div>
                        <div>
                            <label for="lastName" class="block text-sm font-medium text-gray-700 mb-1">Last Name</label>
                            <input id="lastName" name="lastName" type="text" required 
                                class="input-field w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none transition duration-200"
                                placeholder="Doe">
                            <p id="lastNameError" class="mt-1 text-sm text-red-600 hidden">Last name is required</p>
                        </div>
                    </div>
                    
                    <!-- Email -->
                    <div>
                        <label for="email" class="block text-sm font-medium text-gray-700 mb-1">Email Address</label>
                        <div class="relative">
                            <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                <i class="fas fa-envelope text-gray-400"></i>
                            </div>
                            <input id="email" name="email" type="email" required 
                                class="input-field pl-10 w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none transition duration-200"
                                placeholder="your@email.com">
                        </div>
                        <p id="emailError" class="mt-1 text-sm text-red-600 hidden">Please enter a valid email address</p>
                    </div>
                    
                    <!-- Password -->
                    <div>
                        <label for="password" class="block text-sm font-medium text-gray-700 mb-1">Password</label>
                        <div class="relative">
                            <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                <i class="fas fa-lock text-gray-400"></i>
                            </div>
                            <input id="password" name="password" type="password" required 
                                class="input-field pl-10 w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none transition duration-200"
                                placeholder="••••••••">
                            <button type="button" id="togglePassword" class="absolute inset-y-0 right-0 pr-3 flex items-center">
                                <i class="fas fa-eye text-gray-400 hover:text-gray-600"></i>
                            </button>
                        </div>
                        <p id="passwordError" class="mt-1 text-sm text-red-600 hidden">Password must be at least 8 characters</p>
                    </div>
                    
                    <!-- Confirm Password -->
                    <div>
                        <label for="confirmPassword" class="block text-sm font-medium text-gray-700 mb-1">Confirm Password</label>
                        <div class="relative">
                            <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                <i class="fas fa-lock text-gray-400"></i>
                            </div>
                            <input id="confirmPassword" name="confirmPassword" type="password" required 
                                class="input-field pl-10 w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none transition duration-200"
                                placeholder="••••••••">
                        </div>
                        <p id="confirmPasswordError" class="mt-1 text-sm text-red-600 hidden">Passwords do not match</p>
                    </div>
                    
                    <!-- Hotel Manager Fields (Hidden by default) -->
                    <div id="managerFields" class="space-y-6 hidden">
                        <div>
                            <label for="hotelName" class="block text-sm font-medium text-gray-700 mb-1">Hotel/Property Name</label>
                            <input id="hotelName" name="hotelName" type="text" 
                                class="input-field w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none transition duration-200"
                                placeholder="Grand Hotel">
                        </div>
                        
                        <div>
                            <label for="hotelLocation" class="block text-sm font-medium text-gray-700 mb-1">Location</label>
                            <input id="hotelLocation" name="hotelLocation" type="text" 
                                class="input-field w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none transition duration-200"
                                placeholder="Paris, France">
                        </div>
                    </div>
                    
                    <!-- Terms and Conditions -->
                    <div class="flex items-start">
                        <input id="terms" name="terms" type="checkbox" required class="h-4 w-4 mt-1 text-blue-600 border-gray-300 rounded focus:ring-blue-500">
                        <label for="terms" class="ml-2 block text-sm text-gray-700">
                            I agree to the <a href="#" class="text-blue-600 hover:text-blue-800">Terms of Service</a> and <a href="#" class="text-blue-600 hover:text-blue-800">Privacy Policy</a>
                        </label>
                    </div>
                    <p id="termsError" class="mt-1 text-sm text-red-600 hidden">You must agree to the terms and conditions</p>
                    
                    <div>
                        <button type="submit" class="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 rounded-lg font-medium transition duration-200">
                            Create Account
                        </button>
                    </div>
                </form>
                
                <div class="mt-6">
                    <div class="relative">
                        <div class="absolute inset-0 flex items-center">
                            <div class="w-full border-t border-gray-300"></div>
                        </div>
                        <div class="relative flex justify-center text-sm">
                            <span class="px-2 bg-white text-gray-500">Or sign up with</span>
                        </div>
                    </div>
                    
                    <div class="mt-6 grid grid-cols-2 gap-3">
                        <button type="button" class="flex justify-center items-center py-2.5 border border-gray-300 rounded-lg hover:bg-gray-50 transition duration-200">
                            <i class="fab fa-google text-red-500 mr-2"></i>
                            <span class="text-sm font-medium text-gray-700">Google</span>
                        </button>
                        <button type="button" class="flex justify-center items-center py-2.5 border border-gray-300 rounded-lg hover:bg-gray-50 transition duration-200">
                            <i class="fab fa-facebook-f text-blue-600 mr-2"></i>
                            <span class="text-sm font-medium text-gray-700">Facebook</span>
                        </button>
                    </div>
                </div>
            </div>
            
            <p class="mt-6 text-center text-sm text-gray-600">
                Already have an account?
                <a href="login.jsp" class="font-medium text-blue-600 hover:text-blue-800">Sign in</a>
            </p>
        </div>
    </div>
    
    <!-- Footer -->
    <footer class="bg-white py-6 border-t">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex flex-col md:flex-row justify-between items-center">
                <div class="flex items-center mb-4 md:mb-0">
                    <i class="fas fa-hotel text-blue-600 text-xl mr-2"></i>
                    <span class="text-lg font-bold text-gray-800">ZAIRTAM</span>
                </div>
                
                <div class="flex space-x-6">
                    <a href="#" class="text-gray-500 hover:text-gray-700">
                        <i class="fab fa-facebook-f"></i>
                    </a>
                    <a href="#" class="text-gray-500 hover:text-gray-700">
                        <i class="fab fa-twitter"></i>
                    </a>
                    <a href="#" class="text-gray-500 hover:text-gray-700">
                        <i class="fab fa-instagram"></i>
                    </a>
                    <a href="#" class="text-gray-500 hover:text-gray-700">
                        <i class="fab fa-linkedin-in"></i>
                    </a>
                </div>
                
                <div class="mt-4 md:mt-0 text-sm text-gray-500">
                    &copy; 2023 ZAIRTAM. All rights reserved.
                </div>
            </div>
        </div>
    </footer>
    
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const registerForm = document.getElementById('registerForm');
            const emailInput = document.getElementById('email');
            const passwordInput = document.getElementById('password');
            const confirmPasswordInput = document.getElementById('confirmPassword');
            const firstNameInput = document.getElementById('firstName');
            const lastNameInput = document.getElementById('lastName');
            const termsCheckbox = document.getElementById('terms');
            const roleInput = document.getElementById('role');
            const clientRole = document.getElementById('clientRole');
            const managerRole = document.getElementById('managerRole');
            const managerFields = document.getElementById('managerFields');
            const togglePassword = document.getElementById('togglePassword');
            
            // Toggle password visibility
            togglePassword.addEventListener('click', function() {
                const type = passwordInput.getAttribute('type') === 'password' ? 'text' : 'password';
                passwordInput.setAttribute('type', type);
                confirmPasswordInput.setAttribute('type', type);
                
                // Toggle eye icon
                const eyeIcon = togglePassword.querySelector('i');
                eyeIcon.classList.toggle('fa-eye');
                eyeIcon.classList.toggle('fa-eye-slash');
            });
            
            // Role selection
            clientRole.addEventListener('click', function() {
                clientRole.classList.add('selected');
                managerRole.classList.remove('selected');
                roleInput.value = 'client';
                managerFields.classList.add('hidden');
                
                // Update icons
                clientRole.querySelector('i').classList.add('text-blue-600');
                clientRole.querySelector('i').classList.remove('text-gray-600');
                managerRole.querySelector('i').classList.add('text-gray-600');
                managerRole.querySelector('i').classList.remove('text-blue-600');
            });
            
            managerRole.addEventListener('click', function() {
                managerRole.classList.add('selected');
                clientRole.classList.remove('selected');
                roleInput.value = 'manager';
                managerFields.classList.remove('hidden');
                
                // Update icons
                managerRole.querySelector('i').classList.add('text-blue-600');
                managerRole.querySelector('i').classList.remove('text-gray-600');
                clientRole.querySelector('i').classList.add('text-gray-600');
                clientRole.querySelector('i').classList.remove('text-blue-600');
            });
            
            // Form validation
            registerForm.addEventListener('submit', function(e) {
                let isValid = true;
                
                // First Name validation
                if (firstNameInput.value.trim() === '') {
                    document.getElementById('firstNameError').classList.remove('hidden');
                    firstNameInput.classList.add('border-red-500');
                    isValid = false;
                } else {
                    document.getElementById('firstNameError').classList.add('hidden');
                    firstNameInput.classList.remove('border-red-500');
                }
                
                // Last Name validation
                if (lastNameInput.value.trim() === '') {
                    document.getElementById('lastNameError').classList.remove('hidden');
                    lastNameInput.classList.add('border-red-500');
                    isValid = false;
                } else {
                    document.getElementById('lastNameError').classList.add('hidden');
                    lastNameInput.classList.remove('border-red-500');
                }
                
                // Email validation
                const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                if (!emailRegex.test(emailInput.value)) {
                    document.getElementById('emailError').classList.remove('hidden');
                    emailInput.classList.add('border-red-500');
                    isValid = false;
                } else {
                    document.getElementById('emailError').classList.add('hidden');
                    emailInput.classList.remove('border-red-500');
                }
                
                // Password validation
                if (passwordInput.value.length < 8) {
                    document.getElementById('passwordError').classList.remove('hidden');
                    passwordInput.classList.add('border-red-500');
                    isValid = false;
                } else {
                    document.getElementById('passwordError').classList.add('hidden');
                    passwordInput.classList.remove('border-red-500');
                }
                
                // Confirm Password validation
                if (passwordInput.value !== confirmPasswordInput.value) {
                    document.getElementById('confirmPasswordError').classList.remove('hidden');
                    confirmPasswordInput.classList.add('border-red-500');
                    isValid = false;
                } else {
                    document.getElementById('confirmPasswordError').classList.add('hidden');
                    confirmPasswordInput.classList.remove('border-red-500');
                }
                
                // Terms validation
                if (!termsCheckbox.checked) {
                    document.getElementById('termsError').classList.remove('hidden');
                    isValid = false;
                } else {
                    document.getElementById('termsError').classList.add('hidden');
                }
                
                // If validation fails, prevent form submission
                if (!isValid) {
                    e.preventDefault();
                }
            });
        });
    </script>
</body>
</html>