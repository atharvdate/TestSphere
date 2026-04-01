package com.testsphere.recruiter;

import com.testsphere.util.DBConnection;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.util.Set;

@WebServlet("/addRound")
public class AddRoundServlet extends HttpServlet {
    private static final Set<String> VALID_TYPES = Set.of("APTITUDE","GD","TECHNICAL","HR");

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || !"RECRUITER".equals(session.getAttribute("role"))) {
            res.sendRedirect("login.jsp"); return;
        }
        int recruiterId = Integer.parseInt((String) session.getAttribute("userId"));

        String driveIdStr  = req.getParameter("driveId");
        String roundType   = req.getParameter("roundType");
        String title       = req.getParameter("title");
        String instructions= req.getParameter("instructions");
        String startTime   = req.getParameter("startTime");
        String endTime     = req.getParameter("endTime");
        String cutoffType  = req.getParameter("cutoffType");
        String cutoffValue = req.getParameter("cutoffValue");

        if (driveIdStr==null || !VALID_TYPES.contains(roundType)) {
            res.sendRedirect("drive_detail.jsp?driveId="+driveIdStr+"&error=invalid_round"); return;
        }

        int driveId = Integer.parseInt(driveIdStr);

        try (Connection conn = DBConnection.getConnection()) {
            // Verify recruiter owns this drive
            try (PreparedStatement vp = conn.prepareStatement(
                    "SELECT id FROM drives WHERE id=? AND recruiter_id=?")) {
                vp.setInt(1, driveId); vp.setInt(2, recruiterId);
                if (!vp.executeQuery().next()) { res.sendRedirect("manage_drives.jsp"); return; }
            }

            // Get next round number
            int roundNum = 1;
            try (PreparedStatement np = conn.prepareStatement(
                    "SELECT COALESCE(MAX(round_number),0)+1 FROM drive_rounds WHERE drive_id=?")) {
                np.setInt(1, driveId);
                ResultSet rs = np.executeQuery();
                if (rs.next()) roundNum = rs.getInt(1);
            }

            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO drive_rounds (drive_id,round_number,round_type,title,instructions,start_time,end_time,cutoff_type,cutoff_value,status) " +
                    "VALUES (?,?,?,?,?,?,?,?,?,?)")) {
                ps.setInt(1, driveId);
                ps.setInt(2, roundNum);
                ps.setString(3, roundType);
                ps.setString(4, title!=null ? title.trim() : roundType+" Round");
                ps.setString(5, instructions!=null ? instructions.trim() : "");
                ps.setString(6, "APTITUDE".equals(roundType) && startTime!=null && !startTime.isEmpty() ? startTime.replace("T"," ")+":00" : null);
                ps.setString(7, "APTITUDE".equals(roundType) && endTime!=null   && !endTime.isEmpty()   ? endTime.replace("T"," ")+":00"   : null);
                ps.setString(8, "APTITUDE".equals(roundType) && cutoffType!=null && !cutoffType.isEmpty() ? cutoffType : null);
                ps.setString(9, "APTITUDE".equals(roundType) && cutoffValue!=null && !cutoffValue.isEmpty() ? cutoffValue : null);
                ps.setString(10, "PENDING");
                ps.executeUpdate();
            }
        } catch (Exception e) { e.printStackTrace(); }

        res.sendRedirect("drive_detail.jsp?driveId="+driveId+"&roundAdded=1");
    }
}
