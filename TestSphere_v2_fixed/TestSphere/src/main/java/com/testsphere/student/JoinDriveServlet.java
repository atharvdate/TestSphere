package com.testsphere.student;

import com.testsphere.util.DBConnection;
import com.testsphere.util.ResumeUploadConfig;
import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.*;
import java.sql.*;
import java.util.List;
import java.util.UUID;

@WebServlet("/joinDrive")
public class JoinDriveServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        String token = req.getParameter("token");
        if (token == null) { res.sendRedirect("student_dashboard.jsp"); return; }
        req.setAttribute("inviteToken", token);
        req.getRequestDispatcher("drive_info.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || !"STUDENT".equals(session.getAttribute("role"))) {
            res.sendRedirect("login.jsp"); return;
        }
        int studentId = Integer.parseInt((String) session.getAttribute("userId"));

        // Parse multipart form
        String token = null;
        String resumePath = null;

        if (ServletFileUpload.isMultipartContent(req)) {
            try {
                DiskFileItemFactory factory = new DiskFileItemFactory();
                ServletFileUpload upload = new ServletFileUpload(factory);
                upload.setFileSizeMax(ResumeUploadConfig.MAX_FILE_SIZE);
                List<FileItem> items = upload.parseRequest(req);

                for (FileItem item : items) {
                    if (item.isFormField() && "token".equals(item.getFieldName())) {
                        token = item.getString();
                    } else if (!item.isFormField() && "resume".equals(item.getFieldName())) {
                        String originalName = item.getName();
                        if (originalName != null && !originalName.isEmpty()) {
                            // Validate PDF
                            String lower = originalName.toLowerCase();
                            if (!lower.endsWith(".pdf")) {
                                res.sendRedirect("student_dashboard.jsp?error=resume_not_pdf");
                                return;
                            }
                            // Save with unique name: studentId_uuid.pdf
                            File uploadDir = new File(ResumeUploadConfig.RESUME_UPLOAD_DIR);
                            uploadDir.mkdirs();
                            String fileName = studentId + "_" + UUID.randomUUID() + ".pdf";
                            File dest = new File(uploadDir, fileName);
                            item.write(dest);
                            resumePath = fileName;
                        }
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
                res.sendRedirect("student_dashboard.jsp?error=upload_failed");
                return;
            }
        } else {
            // Non-multipart fallback (shouldn't happen but guard anyway)
            token = req.getParameter("token");
        }

        if (token == null) { res.sendRedirect("student_dashboard.jsp"); return; }
        if (resumePath == null) {
            res.sendRedirect("joinDrive?token=" + token + "&error=resume_required");
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {

            // Load drive by token
            int driveId; String elYear; double elMinCgpa;
            int elMaxBacklogs; String elBranches; String regDeadline;

            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT id,eligibility_year,eligibility_min_cgpa,eligibility_max_backlogs," +
                    "eligibility_branches,registration_deadline,status FROM drives WHERE invite_token=?")) {
                ps.setString(1, token);
                ResultSet rs = ps.executeQuery();
                if (!rs.next()) { res.sendRedirect("student_dashboard.jsp?error=invalid_link"); return; }
                driveId       = rs.getInt("id");
                elYear        = rs.getString("eligibility_year");
                elMinCgpa     = rs.getDouble("eligibility_min_cgpa");
                elMaxBacklogs = rs.getInt("eligibility_max_backlogs");
                elBranches    = rs.getString("eligibility_branches");
                regDeadline   = rs.getString("registration_deadline");
                if ("CLOSED".equals(rs.getString("status"))) {
                    res.sendRedirect("student_dashboard.jsp?error=drive_closed"); return;
                }
            }

            // Check registration deadline
            try (PreparedStatement ps = conn.prepareStatement("SELECT NOW() > ? AS expired")) {
                ps.setString(1, regDeadline);
                ResultSet rs = ps.executeQuery();
                if (rs.next() && rs.getInt("expired") == 1) {
                    res.sendRedirect("student_dashboard.jsp?error=deadline_passed"); return;
                }
            }

            // Get student profile
            String stdYear, stdBranch; double stdCgpa; int stdBacklogs, stdCollegeId;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT year_of_study,branch,cgpa,backlogs,college_id FROM users WHERE id=?")) {
                ps.setInt(1, studentId);
                ResultSet rs = ps.executeQuery(); rs.next();
                stdYear      = rs.getString("year_of_study");
                stdBranch    = rs.getString("branch");
                stdCgpa      = rs.getDouble("cgpa");
                stdBacklogs  = rs.getInt("backlogs");
                stdCollegeId = rs.getInt("college_id");
            }

            // College match
            int driveCollegeId;
            try (PreparedStatement ps = conn.prepareStatement("SELECT college_id FROM drives WHERE id=?")) {
                ps.setInt(1, driveId);
                ResultSet rs = ps.executeQuery(); rs.next();
                driveCollegeId = rs.getInt("college_id");
            }
            if (stdCollegeId != driveCollegeId) {
                res.sendRedirect("student_dashboard.jsp?error=wrong_college"); return;
            }

            // Eligibility checks
            if (!"ALL".equals(elYear) && !elYear.equals(stdYear)) {
                res.sendRedirect("student_dashboard.jsp?error=not_eligible_year"); return;
            }
            if (stdCgpa < elMinCgpa) {
                res.sendRedirect("student_dashboard.jsp?error=not_eligible_cgpa"); return;
            }
            if (stdBacklogs > elMaxBacklogs) {
                res.sendRedirect("student_dashboard.jsp?error=not_eligible_backlogs"); return;
            }
            if (!"ALL".equals(elBranches) && !elBranches.contains(stdBranch)) {
                res.sendRedirect("student_dashboard.jsp?error=not_eligible_branch"); return;
            }

            // Already applied?
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT id FROM drive_applications WHERE drive_id=? AND student_id=?")) {
                ps.setInt(1, driveId); ps.setInt(2, studentId);
                if (ps.executeQuery().next()) {
                    res.sendRedirect("student_dashboard.jsp?error=already_applied"); return;
                }
            }

            // Insert application with resume
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO drive_applications (drive_id,student_id,status,recruiter_status,current_round,resume_path) " +
                    "VALUES (?,?,'ACTIVE','PENDING',0,?)")) {
                ps.setInt(1, driveId);
                ps.setInt(2, studentId);
                ps.setString(3, resumePath);
                ps.executeUpdate();
            }

            // Notify student
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO notifications (user_id,title,message) " +
                    "SELECT ?, CONCAT('Registered: ', title), 'You have successfully registered. Your resume is under review.' " +
                    "FROM drives WHERE id=?")) {
                ps.setInt(1, studentId); ps.setInt(2, driveId);
                ps.executeUpdate();
            }

            // Trigger async AI scoring (fire and forget)
            final int fDriveId = driveId;
            final int fStudentId = studentId;
            final String fResumePath = resumePath;
            new Thread(() -> {
                try { com.testsphere.util.GeminiScorer.scoreAsync(fDriveId, fStudentId, fResumePath); }
                catch (Exception e) { e.printStackTrace(); }
            }).start();

        } catch (Exception e) { e.printStackTrace(); }

        res.sendRedirect("student_dashboard.jsp?joined=1");
    }
}
