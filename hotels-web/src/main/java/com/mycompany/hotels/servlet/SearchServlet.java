package com.mycompany.hotels.servlet;

import com.mycompany.hotels.entity.Hotel;
import java.io.IOException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.TypedQuery;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet(name = "SearchServlet", urlPatterns = {"/search"})
public class SearchServlet extends HttpServlet {
    
    @PersistenceContext(unitName = "hotelPU")
    private EntityManager em;
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Get search parameters
        String destination = request.getParameter("destination");
        String checkInStr = request.getParameter("checkIn");
        String checkOutStr = request.getParameter("checkOut");
        String guestsStr = request.getParameter("guests");
        
        // Validate and parse dates
        Date checkIn = null;
        Date checkOut = null;
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
        
        try {
            if (checkInStr != null && !checkInStr.isEmpty()) {
                checkIn = dateFormat.parse(checkInStr);
            }
            
            if (checkOutStr != null && !checkOutStr.isEmpty()) {
                checkOut = dateFormat.parse(checkOutStr);
            }
        } catch (ParseException e) {
            getServletContext().log("Error parsing dates", e);
        }
        
        // Parse guests
        int guests = 1;
        if (guestsStr != null && !guestsStr.isEmpty()) {
            try {
                guests = Integer.parseInt(guestsStr);
            } catch (NumberFormatException e) {
                // If it's "5+" or other non-numeric format, set to 5
                if (guestsStr.contains("5+")) {
                    guests = 5;
                }
            }
        }
        
        // Build search query
        StringBuilder queryBuilder = new StringBuilder("SELECT h FROM Hotel h WHERE h.status = 'active'");
        
        if (destination != null && !destination.isEmpty()) {
            queryBuilder.append(" AND (LOWER(h.name) LIKE LOWER(:destination) OR LOWER(h.city) LIKE LOWER(:destination) OR LOWER(h.country) LIKE LOWER(:destination))");
        }
        
        // Add order by clause
        queryBuilder.append(" ORDER BY h.rating DESC");
        
        // Create and execute query
        TypedQuery<Hotel> query = em.createQuery(queryBuilder.toString(), Hotel.class);
        
        if (destination != null && !destination.isEmpty()) {
            query.setParameter("destination", "%" + destination + "%");
        }
        
        List<Hotel> hotels = query.getResultList();
        
        // Create a list to hold hotel data with pricing info
        List<Map<String, Object>> searchResults = new ArrayList<>();
        
        for (Hotel hotel : hotels) {
            Map<String, Object> hotelData = new HashMap<>();
            hotelData.put("id", hotel.getId());
            hotelData.put("name", hotel.getName());
            hotelData.put("city", hotel.getCity());
            hotelData.put("country", hotel.getCountry());
            hotelData.put("rating", hotel.getRating());
            
            // You would normally get this from your room types
            // This is a placeholder - in a real app, calculate the minimum price from room types
            double minPrice = 100.0; // Default placeholder price
            
            if (!hotel.getRoomTypes().isEmpty()) {
                // Get minimum price from room types if available
                // This assumes you have a getBasePrice() method in your RoomType entity
                // minPrice = hotel.getRoomTypes().stream()
                //    .mapToDouble(rt -> rt.getBasePrice())
                //    .min()
                //    .orElse(100.0);
            }
            
            hotelData.put("minPrice", minPrice);
            
            // Add image URL if available (placeholder for now)
            hotelData.put("imageUrl", null); // You would set this from your database
            
            searchResults.add(hotelData);
        }
        
        // Set attributes for the JSP
        request.setAttribute("searchResults", searchResults);
        request.setAttribute("destination", destination);
        request.setAttribute("checkIn", checkInStr);
        request.setAttribute("checkOut", checkOutStr);
        request.setAttribute("guests", guestsStr);
        
        // Forward to the search results page
        request.getRequestDispatcher("/search-results.jsp").forward(request, response);
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Handle POST the same as GET
        doGet(request, response);
    }
}