package com.testsphere.recruiter;

import com.testsphere.util.DBConnection;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.util.Set;

@WebServlet("/addQuestion")
public class AddQuestionServlet extends HttpServlet {
    private static final Set<String> VALID_OPT = Set.of("A","B","C","D");

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
        String questionText = req.getParameter("question");
        String optA = req.getParameter("optionA"), optB = req.getParameter("optionB");
        String optC = req.getParameter("optionC"), optD = req.getParameter("optionD");
        String correct = req.getParameter("correctOption");

        if (correct != null) correct = correct.trim().toUpperCase();

        if (roundIdStr==null||questionText==null||questionText.trim().isEmpty()
                ||optA==null||optB==null||optC==null||optD==null
                ||!VALID_OPT.contains(correct)) {
            res.sendRedirect("add_question.jsp?roundId="+roundIdStr+"&driveId="+driveIdStr+"&error=missing"); return;
        }

        try (Connection conn = DBConnection.getConnection()) {
            // Verify ownership through drive
            try (PreparedStatement vp = conn.prepareStatement(
                    "SELECT dr.id FROM drive_rounds dr JOIN drives d ON dr.drive_id=d.id " +
                    "WHERE dr.id=? AND d.recruiter_id=?")) {
                vp.setInt(1, Integer.parseInt(roundIdStr)); vp.setInt(2, recruiterId);
                if (!vp.executeQuery().next()) { res.sendRedirect("manage_drives.jsp"); return; }
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO questions (round_id,question_text,option_a,option_b,option_c,option_d,correct_option) " +
                    "VALUES (?,?,?,?,?,?,?)")) {
                ps.setInt(1, Integer.parseInt(roundIdStr));
                ps.setString(2, questionText.trim());
                ps.setString(3, optA.trim()); ps.setString(4, optB.trim());
                ps.setString(5, optC.trim()); ps.setString(6, optD.trim());
                ps.setString(7, correct);
                ps.executeUpdate();
            }
        } catch (Exception e) { e.printStackTrace(); }

        res.sendRedirect("add_question.jsp?roundId="+roundIdStr+"&driveId="+driveIdStr+"&added=1");
    }
}
