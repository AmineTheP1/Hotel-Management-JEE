package com.zairtam.servlet;

import com.zairtam.dao.HotelDAO;
import com.zairtam.dao.UserDAO;
import com.zairtam.model.Hotel;
import com.zairtam.model.User;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

@WebServlet("/RegisterServlet")
public class RegisterServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    private UserDAO userDAO;
    private HotelDAO hotelDAO;
    
    @Override
    public void init() {
        userDAO = new UserDAO();
        hotelDAO = new HotelDAO();
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // Get form parameters
        String firstName = request.getParameter("firstName");
        String lastName = request.getParameter("lastName");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String role = request.getParameter("role");
        
        // Check if email already exists
        if (userDAO.isEmailExists(email)) {
            request.setAttribute("errorMessage", "Email already exists. Please use a different email or login.");
            request.setAttribute("firstName", firstName);
            request.setAttribute("lastName", lastName);
            request.setAttribute("email", email);
            request.setAttribute("role", role);
            
            // If hotel manager, preserve hotel details
            if ("manager".equals(role)) {
                String hotelName = request.getParameter("hotelName");
                String hotelLocation = request.getParameter("hotelLocation");
                request.setAttribute("hotelName", hotelName);
                request.setAttribute("hotelLocation", hotelLocation);
            }
            
            request.getRequestDispatcher("register.jsp").forward(request, response);
            return;
        }
        
        // Create user object
        User user = new User();
        user.setFirstName(firstName);
        user.setLastName(lastName);
        user.setEmail(email);
        user.setPassword(password); // In production, you should hash this password
        user.setRole(role);
        
        // Register the user
        boolean userRegistered = userDAO.registerUser(user);
        
        if (!userRegistered) {
            request.setAttribute("errorMessage", "Registration failed. Please try again.");
            request.getRequestDispatcher("register.jsp").forward(request, response);
            return;
        }
        
        // If user is a hotel manager, register the hotel
        if ("manager".equals(role)) {
            String hotelName = request.getParameter("hotelName");
            String hotelLocation = request.getParameter("hotelLocation");
            
            // Get the user ID of the newly registered user
            int userId = userDAO.getUserIdByEmail(email);
            
            if (userId > 0) {
                // Create hotel object
                Hotel hotel = new Hotel();
                hotel.setName(hotelName);
                hotel.setLocation(hotelLocation);
                hotel.setManagerId(userId);
                
                // Register the hotel
                boolean hotelRegistered = hotelDAO.registerHotel(hotel);
                
                if (!hotelRegistered) {
                    // If hotel registration fails, we should ideally roll back the user registration
                    // For simplicity, we'll just show an error message
                    request.setAttribute("errorMessage", "Hotel registration failed. Please contact support.");
                    request.getRequestDispatcher("register.jsp").forward(request, response);
                    return;
                }
            }
        }
        
        // Registration successful, create session
        HttpSession session = request.getSession();
        session.setAttribute("user", user);
        
        // Redirect to appropriate page based on role
        if ("manager".equals(role)) {
            response.sendRedirect("hotel-dashboard.jsp");
        } else {
            response.sendRedirect("index.jsp");
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        // Forward to registration page
        request.getRequestDispatcher("register.jsp").forward(request, response);
    }
}