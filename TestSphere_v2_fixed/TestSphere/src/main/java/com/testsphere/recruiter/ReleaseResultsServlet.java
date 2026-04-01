package com.testsphere.recruiter;

import com.testsphere.util.DBConnection;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/releaseResults")
public class ReleaseResultsServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session==null||!"RECRUITER".equals(session.getAttribute("role"))) {
            res.sendRedirect("login.jsp"); return;
        }
        int recruiterId = Integer.parseInt((String) session.getAttribute("userId"));

        String roundIdStr   = req.getParameter("roundId");
        String driveIdStr   = req.getParameter("driveId");
        String cutoffType   = req.getParameter("cutoffType");   // TOP_N or MIN_PERCENT
        String cutoffValue  = req.getParameter("cutoffValue");

        if (roundIdStr==null||cutoffType==null||cutoffValue==null) {
            res.sendRedirect("drive_detail.jsp?driveId="+driveIdStr+"&error=missing"); return;
        }

        int roundId = Integer.parseInt(roundIdStr);
        int driveId = Integer.parseInt(driveIdStr);

        try (Connection conn = DBConnection.getConnection()) {
            // Verify ownership
            try (PreparedStatement vp = conn.prepareStatement(
                    "SELECT dr.id FROM drive_rounds dr JOIN drives d ON dr.drive_id=d.id " +
                    "WHERE dr.id=? AND d.recruiter_id=?")) {
                vp.setInt(1, roundId); vp.setInt(2, recruiterId);
                if (!vp.executeQuery().next()) { res.sendRedirect("manage_drives.jsp"); return; }
            }

            // Mark qualified based on cutoff — aptitude only (scored automatically)
            if ("TOP_N".equals(cutoffType)) {
                int n = Integer.parseInt(cutoffValue);
                // Mark top N as QUALIFIED, rest as ELIMINATED
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE round_results rr " +
                        "JOIN (SELECT id, RANK() OVER (ORDER BY (score*100.0/NULLIF(total_questions,0)) DESC) AS rnk " +
                        "      FROM round_results WHERE round_id=? AND submitted_at IS NOT NULL) ranked ON rr.id=ranked.id " +
                        "SET rr.pass_fail = CASE WHEN ranked.rnk <= ? THEN 'PASS' ELSE 'FAIL' END " +
                        "WHERE rr.round_id=?")) {
                    ps.setInt(1, roundId); ps.setInt(2, n); ps.setInt(3, roundId);
                    ps.executeUpdate();
                }
            } else { // MIN_PERCENT
                double minPct = Double.parseDouble(cutoffValue);
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE round_results SET pass_fail = " +
                        "CASE WHEN total_questions>0 AND (score*100.0/total_questions)>=? THEN 'PASS' ELSE 'FAIL' END " +
                        "WHERE round_id=? AND submitted_at IS NOT NULL")) {
                    ps.setDouble(1, minPct); ps.setInt(2, roundId);
                    ps.executeUpdate();
                }
            }

            // Save cutoff and mark released
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE drive_rounds SET cutoff_type=?,cutoff_value=?,result_released=1,status='COMPLETED' WHERE id=?")) {
                ps.setString(1, cutoffType);
                ps.setString(2, cutoffValue);
                ps.setInt(3, roundId);
                ps.executeUpdate();
            }

            // Update drive_applications — eliminate those who failed
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE drive_applications da " +
                    "JOIN round_results rr ON rr.application_id=da.id " +
                    "SET da.status='ELIMINATED', da.current_round=? " +
                    "WHERE rr.round_id=? AND rr.pass_fail='FAIL' AND da.status='ACTIVE'")) {
                ps.setInt(1, roundId); ps.setInt(2, roundId);
                ps.executeUpdate();
            }

            // Send notifications
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO notifications (user_id, title, message) " +
                    "SELECT u.id, ?, " +
                    "CASE rr.pass_fail WHEN 'PASS' THEN ? ELSE ? END " +
                    "FROM round_results rr " +
                    "JOIN drive_applications da ON rr.application_id=da.id " +
                    "JOIN users u ON da.student_id=u.id " +
                    "JOIN drive_rounds dr ON rr.round_id=dr.id " +
                    "JOIN drives d ON dr.drive_id=d.id " +
                    "WHERE rr.round_id=?")) {
                String driveTitle = "";
                try (PreparedStatement tp = conn.prepareStatement(
                        "SELECT d.title FROM drives d JOIN drive_rounds dr ON dr.drive_id=d.id WHERE dr.id=?")) {
                    tp.setInt(1, roundId);
                    ResultSet tr = tp.executeQuery();
                    if (tr.next()) driveTitle = tr.getString(1);
                }
                ps.setString(1, "Result: " + driveTitle);
                ps.setString(2, "Congratulations! You have qualified this round and are moving forward.");
                ps.setString(3, "Thank you for participating. Unfortunately you have not qualified this round.");
                ps.setInt(4, roundId);
                ps.executeUpdate();
            }

        } catch (Exception e) { e.printStackTrace(); }

        res.sendRedirect("drive_detail.jsp?driveId="+driveId+"&released=1");
    }
}
