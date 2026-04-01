package com.testsphere.recruiter;

import com.testsphere.util.DBConnection;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.util.Set;

@WebServlet("/updateDriveStatus")
public class UpdateDriveStatusServlet extends HttpServlet {
    private static final Set<String> VALID = Set.of("ACTIVE","CLOSED","DRAFT");
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session==null||!"RECRUITER".equals(session.getAttribute("role"))) { res.sendRedirect("login.jsp"); return; }
        int uid = Integer.parseInt((String) session.getAttribute("userId"));
        String driveIdStr = req.getParameter("driveId");
        String status     = req.getParameter("status");
        if (driveIdStr==null||!VALID.contains(status)) { res.sendRedirect("manage_drives.jsp"); return; }
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement("UPDATE drives SET status=? WHERE id=? AND recruiter_id=?")) {
            ps.setString(1, status); ps.setInt(2, Integer.parseInt(driveIdStr)); ps.setInt(3, uid);
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
        res.sendRedirect("drive_detail.jsp?driveId="+driveIdStr);
    }
}
