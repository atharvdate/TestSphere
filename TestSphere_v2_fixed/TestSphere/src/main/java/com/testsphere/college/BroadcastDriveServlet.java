package com.testsphere.college;

import com.testsphere.util.DBConnection;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;

/**
 * College admin broadcasts a drive to all approved students at their college.
 * Inserts a notification for each student with the invite link.
 */
@WebServlet("/college/broadcastDrive")
public class BroadcastDriveServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || !"COLLEGE_ADMIN".equals(session.getAttribute("role"))) {
            res.sendRedirect("../login.jsp"); return;
        }
        int adminId = Integer.parseInt((String) session.getAttribute("userId"));
        String driveIdStr = req.getParameter("driveId");
        if (driveIdStr == null) { res.sendRedirect("../college_dashboard.jsp"); return; }

        try (Connection conn = DBConnection.getConnection()) {

            // Get college of this admin
            int collegeId = 0;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT college_id FROM users WHERE id=?")) {
                ps.setInt(1, adminId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) collegeId = rs.getInt("college_id");
            }

            // Verify drive belongs to this college
            String driveTitle = "", inviteToken = "";
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT title, invite_token FROM drives WHERE id=? AND college_id=?")) {
                ps.setInt(1, Integer.parseInt(driveIdStr)); ps.setInt(2, collegeId);
                ResultSet rs = ps.executeQuery();
                if (!rs.next()) { res.sendRedirect("../college_dashboard.jsp"); return; }
                driveTitle   = rs.getString("title");
                inviteToken  = rs.getString("invite_token");
            }

            // Build the invite URL
            String baseUrl = req.getScheme() + "://" + req.getServerName() +
                             ":" + req.getServerPort() + req.getContextPath();
            String inviteUrl = baseUrl + "/joinDrive?token=" + inviteToken;

            // Insert notification for every ACTIVE student at this college
            // Avoid duplicate notifications using INSERT IGNORE on a unique-ish check
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO notifications (user_id, title, message) " +
                    "SELECT u.id, ?, ? FROM users u " +
                    "WHERE u.college_id=? AND u.role='STUDENT' AND u.status='ACTIVE' " +
                    "AND NOT EXISTS (" +
                    "  SELECT 1 FROM notifications n WHERE n.user_id=u.id AND n.title=?" +
                    ")")) {
                String title = "New Drive: " + driveTitle;
                String msg   = "A new placement drive is available for your college: " +
                               driveTitle + ". Apply here: " + inviteUrl;
                ps.setString(1, title);
                ps.setString(2, msg);
                ps.setInt(3, collegeId);
                ps.setString(4, title);
                ps.executeUpdate();
            }

        } catch (Exception e) { e.printStackTrace(); }

        res.sendRedirect("../college_dashboard.jsp?broadcasted=1");
    }
}
