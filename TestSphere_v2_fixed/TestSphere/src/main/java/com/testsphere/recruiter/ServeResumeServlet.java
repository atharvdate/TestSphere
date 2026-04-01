package com.testsphere.recruiter;

import com.testsphere.util.DBConnection;
import com.testsphere.util.ResumeUploadConfig;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.*;
import java.nio.file.Files;
import java.sql.*;

/**
 * Serves resume PDFs only to the recruiter who owns the drive.
 * URL: /serveResume?appId=123
 */
@WebServlet("/serveResume")
public class ServeResumeServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || !"RECRUITER".equals(session.getAttribute("role"))) {
            res.sendError(403); return;
        }
        int recruiterId = Integer.parseInt((String) session.getAttribute("userId"));
        String appIdStr = req.getParameter("appId");
        if (appIdStr == null) { res.sendError(400); return; }

        String resumePath = null;
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "SELECT da.resume_path FROM drive_applications da " +
                 "JOIN drives d ON da.drive_id=d.id " +
                 "WHERE da.id=? AND d.recruiter_id=?")) {
            ps.setInt(1, Integer.parseInt(appIdStr));
            ps.setInt(2, recruiterId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) resumePath = rs.getString("resume_path");
        } catch (Exception e) { e.printStackTrace(); }

        if (resumePath == null) { res.sendError(404); return; }

        File file = new File(ResumeUploadConfig.RESUME_UPLOAD_DIR, resumePath);
        if (!file.exists() || !file.isFile()) { res.sendError(404); return; }

        res.setContentType("application/pdf");
        res.setHeader("Content-Disposition", "inline; filename=\"resume.pdf\"");
        res.setContentLengthLong(file.length());
        Files.copy(file.toPath(), res.getOutputStream());
    }
}
