package com.testsphere.admin;

import com.testsphere.util.DBConnection;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.*;

@WebServlet("/admin/approve_recruiter")
public class AdminApproveServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession _s = req.getSession(false);
        if (_s == null) { res.sendRedirect("../login.jsp"); return; }
        String session_role = (String) _s.getAttribute("role");
        if (!"ADMIN".equals(session_role)) { res.sendRedirect("../login.jsp"); return; }

        String targetId = req.getParameter("userId");
        String action   = req.getParameter("action"); // approve or reject
        String type     = req.getParameter("type");   // recruiter or college

        if (targetId == null) { res.sendRedirect("../admin_dashboard.jsp"); return; }

        String newStatus = "approve".equals(action) ? "ACTIVE" : "REJECTED";

        try (Connection conn = DBConnection.getConnection()) {
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE users SET status=? WHERE id=?")) {
                ps.setString(1, newStatus);
                ps.setInt(2, Integer.parseInt(targetId));
                ps.executeUpdate();
            }
            // If approving college admin, also approve the college
            if ("approve".equals(action) && "college".equals(type)) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE colleges SET status='APPROVED' WHERE id=(SELECT college_id FROM users WHERE id=?)")) {
                    ps.setInt(1, Integer.parseInt(targetId));
                    ps.executeUpdate();
                }
            }
        } catch (Exception e) { e.printStackTrace(); }

        res.sendRedirect("../admin_dashboard.jsp?action=" + action);
    }
}
