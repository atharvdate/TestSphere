package com.testsphere.admin;

import com.testsphere.util.DBConnection;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.*;

@WebServlet("/admin/deactivate")
public class AdminDeactivateServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        HttpSession _s = req.getSession(false);
        if (_s == null) { res.sendRedirect("../login.jsp"); return; }
        String role = (String) _s.getAttribute("role");
        if (!"ADMIN".equals(role)) { res.sendRedirect("../login.jsp"); return; }

        String targetId = req.getParameter("userId");
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "UPDATE users SET status='INACTIVE' WHERE id=? AND role != 'ADMIN'")) {
            ps.setInt(1, Integer.parseInt(targetId));
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }

        res.sendRedirect("../admin_dashboard.jsp?action=deactivated");
    }
}
