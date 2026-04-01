package com.testsphere.recruiter;

import com.testsphere.util.DBConnection;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/markRoundResult")
public class MarkRoundResultServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session==null||!"RECRUITER".equals(session.getAttribute("role"))) {
            res.sendRedirect("login.jsp"); return;
        }
        int recruiterId = Integer.parseInt((String) session.getAttribute("userId"));

        String roundIdStr  = req.getParameter("roundId");
        String driveIdStr  = req.getParameter("driveId");
        String appIdStr    = req.getParameter("applicationId");
        String result      = req.getParameter("result"); // PASS or FAIL
        String notes       = req.getParameter("notes");

        if (!"PASS".equals(result) && !"FAIL".equals(result)) {
            res.sendRedirect("round_results.jsp?roundId="+roundIdStr+"&driveId="+driveIdStr); return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            // Verify ownership
            try (PreparedStatement vp = conn.prepareStatement(
                    "SELECT dr.id FROM drive_rounds dr JOIN drives d ON dr.drive_id=d.id " +
                    "WHERE dr.id=? AND d.recruiter_id=?")) {
                vp.setInt(1, Integer.parseInt(roundIdStr)); vp.setInt(2, recruiterId);
                if (!vp.executeQuery().next()) { res.sendRedirect("manage_drives.jsp"); return; }
            }

            // Upsert round result
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO round_results (application_id,round_id,pass_fail,recruiter_notes,submitted_at) " +
                    "VALUES (?,?,?,?,NOW()) ON DUPLICATE KEY UPDATE pass_fail=?,recruiter_notes=?,submitted_at=NOW()")) {
                ps.setInt(1, Integer.parseInt(appIdStr));
                ps.setInt(2, Integer.parseInt(roundIdStr));
                ps.setString(3, result);
                ps.setString(4, notes!=null?notes.trim():"");
                ps.setString(5, result);
                ps.setString(6, notes!=null?notes.trim():"");
                ps.executeUpdate();
            }

            // If FAIL, eliminate from drive
            if ("FAIL".equals(result)) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE drive_applications SET status='ELIMINATED' WHERE id=?")) {
                    ps.setInt(1, Integer.parseInt(appIdStr));
                    ps.executeUpdate();
                }
            }

            // Release result for THIS student immediately so they can see their status
            // Don't mark the whole round complete yet — recruiter may still mark others
            // The round will be marked COMPLETED when recruiter explicitly releases all results
            // For now just notify — student sees their result via result_released on their row
            // (We set result_released on the individual round_result, not the round itself)

            // Notify student
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO notifications (user_id,title,message) " +
                    "SELECT da.student_id, ?, ? FROM drive_applications da WHERE da.id=?")) {
                String driveTitle = "";
                try (PreparedStatement tp = conn.prepareStatement(
                        "SELECT d.title FROM drives d JOIN drive_rounds dr ON dr.drive_id=d.id WHERE dr.id=?")) {
                    tp.setInt(1, Integer.parseInt(roundIdStr));
                    ResultSet tr = tp.executeQuery();
                    if (tr.next()) driveTitle = tr.getString(1);
                }
                String msg = "PASS".equals(result)
                    ? "Congratulations! You have cleared this round for "+driveTitle+"."
                    : "Thank you for participating in "+driveTitle+". You have not qualified this round.";
                ps.setString(1, "Round Result: "+driveTitle);
                ps.setString(2, msg);
                ps.setInt(3, Integer.parseInt(appIdStr));
                ps.executeUpdate();
            }

        } catch (Exception e) { e.printStackTrace(); }

        res.sendRedirect("round_results.jsp?roundId="+roundIdStr+"&driveId="+driveIdStr+"&saved=1");
    }
}
