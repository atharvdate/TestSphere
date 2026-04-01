package com.testsphere.student;

import com.testsphere.util.DBConnection;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/submitTest")
public class SubmitTestServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session==null||!"STUDENT".equals(session.getAttribute("role"))) {
            res.sendRedirect("login.jsp"); return;
        }
        int studentId = Integer.parseInt((String) session.getAttribute("userId"));

        String roundIdStr = req.getParameter("roundId");
        String appIdStr   = req.getParameter("applicationId");

        if (roundIdStr==null||appIdStr==null) { res.sendRedirect("student_dashboard.jsp"); return; }

        int roundId = Integer.parseInt(roundIdStr);
        int appId   = Integer.parseInt(appIdStr);

        try (Connection conn = DBConnection.getConnection()) {
            // Verify student owns this application and has been shortlisted
            try (PreparedStatement vp = conn.prepareStatement(
                    "SELECT id FROM drive_applications WHERE id=? AND student_id=? AND status='ACTIVE' AND recruiter_status='SHORTLISTED'")) {
                vp.setInt(1, appId); vp.setInt(2, studentId);
                if (!vp.executeQuery().next()) { res.sendRedirect("student_dashboard.jsp?error=not_shortlisted"); return; }
            }

            // Prevent re-attempt
            try (PreparedStatement cp = conn.prepareStatement(
                    "SELECT id FROM round_results WHERE application_id=? AND round_id=? AND submitted_at IS NOT NULL")) {
                cp.setInt(1, appId); cp.setInt(2, roundId);
                if (cp.executeQuery().next()) {
                    res.sendRedirect("student_dashboard.jsp?error=already_submitted"); return;
                }
            }

            // Check test window is still open
            try (PreparedStatement tp = conn.prepareStatement(
                    "SELECT NOW() > end_time AS expired FROM drive_rounds WHERE id=?")) {
                tp.setInt(1, roundId);
                ResultSet rs = tp.executeQuery();
                if (rs.next() && rs.getInt("expired")==1) {
                    res.sendRedirect("student_dashboard.jsp?error=window_closed"); return;
                }
            }

            // Count total questions
            int total = 0;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COUNT(*) FROM questions WHERE round_id=?")) {
                ps.setInt(1, roundId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) total = rs.getInt(1);
            }

            // Score answers
            int score = 0;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT id, correct_option FROM questions WHERE round_id=?")) {
                ps.setInt(1, roundId);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    String answer = req.getParameter("q"+rs.getInt("id"));
                    if (answer!=null && answer.equalsIgnoreCase(rs.getString("correct_option"))) score++;
                }
            }

            // Save result — results are HELD until recruiter releases
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO round_results (application_id,round_id,score,total_questions,submitted_at) " +
                    "VALUES (?,?,?,?,NOW()) ON DUPLICATE KEY UPDATE score=?,total_questions=?,submitted_at=NOW()")) {
                ps.setInt(1, appId); ps.setInt(2, roundId);
                ps.setInt(3, score); ps.setInt(4, total);
                ps.setInt(5, score); ps.setInt(6, total);
                ps.executeUpdate();
            }

            // Update current round on application
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE drive_applications SET current_round=? WHERE id=?")) {
                ps.setInt(1, roundId); ps.setInt(2, appId);
                ps.executeUpdate();
            }

        } catch (Exception e) { e.printStackTrace(); }

        res.sendRedirect("student_dashboard.jsp?submitted=1");
    }
}
