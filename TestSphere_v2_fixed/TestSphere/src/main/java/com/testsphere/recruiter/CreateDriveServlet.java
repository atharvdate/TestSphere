package com.testsphere.recruiter;

import com.testsphere.util.DBConnection;
import com.testsphere.util.TokenGenerator;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/createDrive")
public class CreateDriveServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || !"RECRUITER".equals(session.getAttribute("role"))) {
            res.sendRedirect("login.jsp"); return;
        }

        int    recruiterId   = Integer.parseInt((String) session.getAttribute("userId"));
        String title         = req.getParameter("title");
        String jobRole       = req.getParameter("jobRole");
        String description   = req.getParameter("description");
        String packageLpa    = req.getParameter("packageLpa");
        String collegeIdStr  = req.getParameter("collegeId");
        String regDeadline   = req.getParameter("regDeadline");
        // eligibility
        String elYear        = req.getParameter("eligibilityYear");
        String elMinCgpa     = req.getParameter("eligibilityMinCgpa");
        String elMaxBacklogs = req.getParameter("eligibilityMaxBacklogs");
        String elBranches    = req.getParameter("eligibilityBranches"); // comma-separated

        if (title==null||title.trim().isEmpty()||jobRole==null||collegeIdStr==null||regDeadline==null) {
            req.setAttribute("errorMessage","Title, job role, college and registration deadline are required.");
            req.getRequestDispatcher("create_drive.jsp").forward(req, res); return;
        }

        String token = TokenGenerator.generate();

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "INSERT INTO drives (title,job_role,description,package_lpa,recruiter_id,college_id," +
                 "eligibility_year,eligibility_min_cgpa,eligibility_max_backlogs,eligibility_branches," +
                 "invite_token,registration_deadline,status) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)",
                 Statement.RETURN_GENERATED_KEYS)) {

            ps.setString(1, title.trim());
            ps.setString(2, jobRole.trim());
            ps.setString(3, description!=null ? description.trim() : "");
            ps.setString(4, packageLpa!=null  ? packageLpa.trim()  : "");
            ps.setInt(5, recruiterId);
            ps.setInt(6, Integer.parseInt(collegeIdStr));
            ps.setString(7, elYear!=null        ? elYear        : "Final Year");
            ps.setDouble(8, elMinCgpa!=null && !elMinCgpa.isEmpty() ? Double.parseDouble(elMinCgpa) : 0.0);
            ps.setInt(9,    elMaxBacklogs!=null && !elMaxBacklogs.isEmpty() ? Integer.parseInt(elMaxBacklogs) : 99);
            ps.setString(10, elBranches!=null   ? elBranches    : "ALL");
            ps.setString(11, token);
            ps.setString(12, regDeadline.replace("T"," ")+":00");
            ps.setString(13, "DRAFT");

            ps.executeUpdate();
            ResultSet gk = ps.getGeneratedKeys();
            gk.next();
            int driveId = gk.getInt(1);

            res.sendRedirect("drive_detail.jsp?driveId="+driveId+"&created=1");

        } catch (Exception e) {
            e.printStackTrace();
            req.setAttribute("errorMessage","Failed to create drive. Please try again.");
            req.getRequestDispatcher("create_drive.jsp").forward(req, res);
        }
    }
}
