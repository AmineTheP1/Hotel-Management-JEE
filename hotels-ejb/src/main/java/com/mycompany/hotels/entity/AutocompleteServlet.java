package com.mycompany.hotels.entity;

import com.google.gson.Gson;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import javax.sql.DataSource;
import javax.naming.InitialContext;
import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/autocomplete")
public class AutocompleteServlet extends HttpServlet {

    private DataSource ds;
    private final Gson gson = new Gson();

    @Override
    public void init() {
        try {
            //   Configurez votre ressource JNDI dans GlassFish (ex. jdbc/zairtam)
            ds = (DataSource) new InitialContext().lookup("java:comp/env/jdbc/zairtam");
        } catch (Exception e) { throw new RuntimeException(e); }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String q = req.getParameter("query");
        List<Dest> list = search(q == null ? "" : q);
        resp.setContentType("application/json; charset=UTF-8");
        gson.toJson(list, resp.getWriter());
    }

    /* Requête SQL très simple : ajuste selon ta table */
    private List<Dest> search(String keyword) {
        List<Dest> res = new ArrayList<>();
        String sql = "SELECT city, country FROM destinations "
                   + "WHERE LOWER(city) LIKE ? OR LOWER(country) LIKE ? "
                   + "ORDER BY popularity DESC LIMIT 10";
        try (Connection c = ds.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            String kw = "%" + keyword.toLowerCase() + "%";
            ps.setString(1, kw);
            ps.setString(2, kw);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    res.add(new Dest(rs.getString("city"), rs.getString("country")));
                }
            }
        } catch (SQLException ignored) {}
        return res;
    }

    /* Petit POJO qui sera sérialisé en JSON */
    private record Dest(String city, String country) {}
}
