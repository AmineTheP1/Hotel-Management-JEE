package com.mycompany.hotels.servlet;

import com.mycompany.hotels.entity.User;
import java.io.IOException;
import javax.persistence.EntityManager;
import javax.persistence.NoResultException;
import javax.persistence.PersistenceContext;
import javax.persistence.TypedQuery;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.transaction.Transactional;

@WebServlet(name = "RegisterServlet", urlPatterns = {"/register"})
public class RegisterServlet extends HttpServlet {
    
    @PersistenceContext(unitName = "hotelPU")
    private EntityManager em;
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Check if user is already logged in
        HttpSession session = request.getSession(false);
        if (session != null && session.getAttribute("user") != null) {
            // User is already logged in, redirect to home page
            response.sendRedirect(request.getContextPath() + "/");
            return;
        }
        
        // Forward to registration page
        request.getRequestDispatcher("/register.jsp").forward(request, response);
    }
    
    @Override
    @Transactional
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String firstName = request.getParameter("firstName");
        String lastName = request.getParameter("lastName");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String role = request.getParameter("role");
        // For manager:
        String hotelName = request.getParameter("hotelName");
        String hotelLocation = request.getParameter("hotelLocation");
    
        // Hash the password (use a proper hashing library in production)
        String passwordHash = password; // Replace with real hash
    
        Connection conn = null;
        PreparedStatement pstmt = null;
        try {
            Class.forName("com.mysql.jdbc.Driver");
            conn = DriverManager.getConnection("jdbc:mysql://localhost:4200/hotel", "root", "Hamza_13579");
    
            // Get role_id from roles table
            String roleQuery = "SELECT role_id FROM roles WHERE name = ?";
            pstmt = conn.prepareStatement(roleQuery);
            pstmt.setString(1, role);
            ResultSet rs = pstmt.executeQuery();
            int roleId = 1; // default to client
            if (rs.next()) {
                roleId = rs.getInt("role_id");
            }
            rs.close();
            pstmt.close();
    
            // Insert user
            String insertUser = "INSERT INTO users (role_id, first_name, last_name, email, password_hash, is_active) VALUES (?, ?, ?, ?, ?, 1)";
            pstmt = conn.prepareStatement(insertUser, Statement.RETURN_GENERATED_KEYS);
            pstmt.setInt(1, roleId);
            pstmt.setString(2, firstName);
            pstmt.setString(3, lastName);
            pstmt.setString(4, email);
            pstmt.setString(5, passwordHash);
            pstmt.executeUpdate();
    
            ResultSet generatedKeys = pstmt.getGeneratedKeys();
            long userId = 0;
            if (generatedKeys.next()) {
                userId = generatedKeys.getLong(1);
            }
            pstmt.close();
    
            // If manager, insert hotel
            if ("manager".equals(role) && hotelName != null && !hotelName.isEmpty()) {
                String insertHotel = "INSERT INTO hotels (manager_id, name, address_line1, city, country, status) VALUES (?, ?, ?, ?, ?, 'pending')";
                pstmt = conn.prepareStatement(insertHotel);
                pstmt.setLong(1, userId);
                pstmt.setString(2, hotelName);
                pstmt.setString(3, hotelLocation);
                pstmt.setString(4, hotelLocation); // Simplified: split city/country as needed
                pstmt.setString(5, ""); // country
                pstmt.executeUpdate();
                pstmt.close();
            }
    
            // Redirect to login page
            response.sendRedirect("login.jsp");
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Registration failed: " + e.getMessage());
            request.getRequestDispatcher("register.jsp").forward(request, response);
        } finally {
            try { if (pstmt != null) pstmt.close(); } catch (Exception ignored) {}
            try { if (conn != null) conn.close(); } catch (Exception ignored) {}
        }
    }
}