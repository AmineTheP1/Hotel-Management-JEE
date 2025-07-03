package com.mycompany.hotels.servlet;

import com.mycompany.hotels.entity.Hotel;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.ejb.EJB;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet(name = "HomeServlet", urlPatterns = {"/home", ""})
public class HomeServlet extends HttpServlet {
    
    @PersistenceContext(unitName = "hotelPU")
    private EntityManager em;
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            // Get popular hotels from database
            List<Hotel> hotels = em.createQuery(
                "SELECT h FROM Hotel h WHERE h.status = 'active' ORDER BY h.rating DESC", 
                Hotel.class)
                .setMaxResults(4)
                .getResultList();
            
            // Create a list to hold hotel data with pricing info
            List<Map<String, Object>> popularHotels = new ArrayList<>();
            
            for (Hotel hotel : hotels) {
                Map<String, Object> hotelData = new HashMap<>();
                hotelData.put("id", hotel.getId());
                hotelData.put("name", hotel.getName());
                hotelData.put("country", hotel.getCountry());
                
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
                
                popularHotels.add(hotelData);
            }
            
            request.setAttribute("popularHotels", popularHotels);
            
        } catch (Exception e) {
            // Log the exception
            getServletContext().log("Error retrieving hotels", e);
            // Don't set popularHotels attribute - the JSP will use fallback static content
        }
        
        // Forward to the JSP page
        request.getRequestDispatcher("/index.jsp").forward(request, response);
    }
}