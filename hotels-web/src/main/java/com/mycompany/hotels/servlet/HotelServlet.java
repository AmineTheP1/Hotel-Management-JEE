package com.mycompany.hotels.servlet;

import com.mycompany.hotels.entity.Hotel;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet(name = "HotelServlet", urlPatterns = {"/hotel"})
public class HotelServlet extends HttpServlet {
    
    @PersistenceContext(unitName = "hotelPU")
    private EntityManager em;
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Get hotel ID from request parameter
        String hotelIdStr = request.getParameter("id");
        
        if (hotelIdStr == null || hotelIdStr.isEmpty()) {
            // Redirect to home page if no hotel ID provided
            response.sendRedirect(request.getContextPath() + "/");
            return;
        }
        
        try {
            Long hotelId = Long.parseLong(hotelIdStr);
            
            // Fetch hotel from database
            Hotel hotel = em.find(Hotel.class, hotelId);
            
            if (hotel == null) {
                // Hotel not found, redirect to home page
                response.sendRedirect(request.getContextPath() + "/");
                return;
            }
            
            // Create a map to hold hotel data
            Map<String, Object> hotelData = new HashMap<>();
            hotelData.put("id", hotel.getId());
            hotelData.put("name", hotel.getName());
            hotelData.put("description", hotel.getDescription());
            hotelData.put("address", hotel.getAddress());
            hotelData.put("city", hotel.getCity());
            hotelData.put("country", hotel.getCountry());
            hotelData.put("rating", hotel.getRating());
            
            // Add image URL if available (placeholder for now)
            hotelData.put("imageUrl", null); // You would set this from your database
            
            // Set hotel data as request attribute
            request.setAttribute("hotel", hotelData);
            
            // Set room types as request attribute (if needed)
            // request.setAttribute("roomTypes", hotel.getRoomTypes());
            
            // Forward to the hotel details page
            request.getRequestDispatcher("/hotel-details.jsp").forward(request, response);
            
        } catch (NumberFormatException e) {
            // Invalid hotel ID format, redirect to home page
            response.sendRedirect(request.getContextPath() + "/");
        }
    }
}