package com.testsphere.recruiter;

import com.testsphere.util.DBConnection;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/shortlistApplicant")
public class ShortlistServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || !"RECRUITER".equals(session.getAttribute("role"))) {
            res.sendRedirect("login.jsp"); return;
        }
        int recruiterId = Integer.parseInt((String) session.getAttribute("userId"));

        String appIdStr  = req.getParameter("appId");
        String driveIdStr= req.getParameter("driveId");
        String action    = req.getParameter("action"); // shortlist or reject

        if (appIdStr == null || driveIdStr == null ||
            (!"shortlist".equals(action) && !"reject".equals(action))) {
            res.sendRedirect("manage_drives.jsp"); return;
        }

        String newStatus = "shortlist".equals(action) ? "SHORTLISTED" : "REJECTED";

        try (Connection conn = DBConnection.getConnection()) {
            // Verify recruiter owns this drive
            try (PreparedStatement vp = conn.prepareStatement(
                    "SELECT id FROM drives WHERE id=? AND recruiter_id=?")) {
                vp.setInt(1, Integer.parseInt(driveIdStr)); vp.setInt(2, recruiterId);
                if (!vp.executeQuery().next()) { res.sendRedirect("manage_drives.jsp"); return; }
            }

            // Update recruiter_status on the application
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE drive_applications SET recruiter_status=? WHERE id=? AND drive_id=?")) {
                ps.setString(1, newStatus);
                ps.setInt(2, Integer.parseInt(appIdStr));
                ps.setInt(3, Integer.parseInt(driveIdStr));
                ps.executeUpdate();
            }

            // If rejected, also eliminate from drive and notify
            if ("reject".equals(action)) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE drive_applications SET status='ELIMINATED' WHERE id=?")) {
                    ps.setInt(1, Integer.parseInt(appIdStr));
                    ps.executeUpdate();
                }
                // Notify student
                String driveTitle = "";
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT d.title FROM drives d JOIN drive_applications da ON da.drive_id=d.id WHERE da.id=?")) {
                    ps.setInt(1, Integer.parseInt(appIdStr));
                    ResultSet rs = ps.executeQuery();
                    if (rs.next()) driveTitle = rs.getString(1);
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO notifications (user_id,title,message) " +
                        "SELECT student_id, ?, ? FROM drive_applications WHERE id=?")) {
                    ps.setString(1, "Application Update: " + driveTitle);
                    ps.setString(2, "Thank you for applying to " + driveTitle +
                        ". After reviewing your resume, we will not be moving forward with your application.");
                    ps.setInt(3, Integer.parseInt(appIdStr));
                    ps.executeUpdate();
                }
            }

            // If shortlisted, notify student
            if ("shortlist".equals(action)) {
                String driveTitle = "";
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT d.title FROM drives d JOIN drive_applications da ON da.drive_id=d.id WHERE da.id=?")) {
                    ps.setInt(1, Integer.parseInt(appIdStr));
                    ResultSet rs = ps.executeQuery();
                    if (rs.next()) driveTitle = rs.getString(1);
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO notifications (user_id,title,message) " +
                        "SELECT student_id, ?, ? FROM drive_applications WHERE id=?")) {
                    ps.setString(1, "Shortlisted: " + driveTitle);
                    ps.setString(2, "Congratulations! You have been shortlisted for the aptitude test for " + driveTitle + ". Please check your dashboard for test details.");
                    ps.setInt(3, Integer.parseInt(appIdStr));
                    ps.executeUpdate();
                }
            }

        } catch (Exception e) { e.printStackTrace(); }

        res.sendRedirect("drive_detail.jsp?driveId=" + driveIdStr + "&action=" + action + "d");
    }
}
