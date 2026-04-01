package com.testsphere.college;

import com.testsphere.util.DBConnection;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/college/approveStudent")
public class CollegeApproveStudentServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || !"COLLEGE_ADMIN".equals(session.getAttribute("role"))) {
            res.sendRedirect("../login.jsp"); return;
        }
        int adminId = Integer.parseInt((String) session.getAttribute("userId"));

        String studentIdStr = req.getParameter("studentId");
        String action       = req.getParameter("action"); // approve or reject

        if (studentIdStr == null || (!  "approve".equals(action) && !"reject".equals(action))) {
            res.sendRedirect("../college_students.jsp"); return;
        }

        String newStatus = "approve".equals(action) ? "ACTIVE" : "REJECTED";

        try (Connection conn = DBConnection.getConnection()) {
            // Get the college_id of this admin
            int collegeId = 0;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT college_id FROM users WHERE id=?")) {
                ps.setInt(1, adminId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) collegeId = rs.getInt("college_id");
            }

            // Only approve students who belong to this college and are PENDING
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE users SET status=? WHERE id=? AND college_id=? AND role='STUDENT' AND status='PENDING'")) {
                ps.setString(1, newStatus);
                ps.setInt(2, Integer.parseInt(studentIdStr));
                ps.setInt(3, collegeId);
                ps.executeUpdate();
            }
        } catch (Exception e) { e.printStackTrace(); }

        res.sendRedirect("../college_students.jsp?action=" + action + "d");
    }
}
