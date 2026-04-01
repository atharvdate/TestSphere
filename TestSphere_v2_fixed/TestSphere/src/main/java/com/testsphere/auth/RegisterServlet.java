package com.testsphere.auth;

import com.testsphere.util.DBConnection;
import org.mindrot.jbcrypt.BCrypt;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.util.Set;

@WebServlet("/register")
public class RegisterServlet extends HttpServlet {

    private static final Set<String> VALID_ROLES   = Set.of("STUDENT","RECRUITER","COLLEGE_ADMIN");
    private static final Set<String> VALID_YEARS   = Set.of("1st Year","2nd Year","3rd Year","Final Year");
    private static final Set<String> VALID_BRANCHES= Set.of("CSE","IT","ECE","EEE","MECH","CIVIL","MBA","MCA","OTHER");

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String role       = req.getParameter("role");
        String username   = req.getParameter("username");
        String email      = req.getParameter("email");
        String password   = req.getParameter("password");
        String fullName   = req.getParameter("fullName");
        String phone      = req.getParameter("phone");

        // Basic validation
        if (!VALID_ROLES.contains(role)
                || username == null || username.trim().length() < 3
                || email    == null || !email.contains("@")
                || password == null || password.length() < 6
                || fullName == null || fullName.trim().isEmpty()) {
            req.setAttribute("errorMessage","All fields are required. Username min 3 chars, password min 6.");
            req.getRequestDispatcher("register.jsp").forward(req, res); return;
        }

        String hash = BCrypt.hashpw(password, BCrypt.gensalt(12));
        // All roles start as PENDING: STUDENT needs college admin approval, others need super admin
        String status = "PENDING";

        try (Connection conn = DBConnection.getConnection()) {

            // Check duplicate username or email
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT id FROM users WHERE BINARY username=? OR BINARY email=?")) {
                ps.setString(1, username.trim());
                ps.setString(2, email.trim());
                if (ps.executeQuery().next()) {
                    req.setAttribute("errorMessage","Username or email already taken.");
                    req.getRequestDispatcher("register.jsp").forward(req, res); return;
                }
            }

            if ("STUDENT".equals(role)) {
                String collegeIdStr = req.getParameter("collegeId");
                String year         = req.getParameter("year");
                String branch       = req.getParameter("branch");
                String cgpaStr      = req.getParameter("cgpa");
                String backlogsStr  = req.getParameter("backlogs");

                if (collegeIdStr == null || !VALID_YEARS.contains(year) || !VALID_BRANCHES.contains(branch)
                        || cgpaStr == null || backlogsStr == null) {
                    req.setAttribute("errorMessage","Please fill all student details correctly.");
                    req.getRequestDispatcher("register.jsp").forward(req, res); return;
                }
                double cgpa     = Double.parseDouble(cgpaStr);
                int    backlogs = Integer.parseInt(backlogsStr);
                int    colId    = Integer.parseInt(collegeIdStr);

                // Verify college is approved
                try (PreparedStatement cp = conn.prepareStatement(
                        "SELECT id FROM colleges WHERE id=? AND status='APPROVED'")) {
                    cp.setInt(1, colId);
                    if (!cp.executeQuery().next()) {
                        req.setAttribute("errorMessage","Selected college is not verified yet.");
                        req.getRequestDispatcher("register.jsp").forward(req, res); return;
                    }
                }

                // Check college domain if email domain matches — soft check (warn not block)
                try (PreparedStatement ins = conn.prepareStatement(
                        "INSERT INTO users (username,email,password_hash,role,status,full_name,phone,college_id,year_of_study,branch,cgpa,backlogs) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)")) {
                    ins.setString(1, username.trim());
                    ins.setString(2, email.trim());
                    ins.setString(3, hash);
                    ins.setString(4, role);
                    ins.setString(5, status);
                    ins.setString(6, fullName.trim());
                    ins.setString(7, phone != null ? phone.trim() : "");
                    ins.setInt(8, colId);
                    ins.setString(9, year);
                    ins.setString(10, branch);
                    ins.setDouble(11, cgpa);
                    ins.setInt(12, backlogs);
                    ins.executeUpdate();
                }

            } else if ("RECRUITER".equals(role)) {
                String companyName    = req.getParameter("companyName");
                String companyWebsite = req.getParameter("companyWebsite");
                String officialEmail  = req.getParameter("officialEmail");

                if (companyName == null || companyName.trim().isEmpty()
                        || companyWebsite == null || companyWebsite.trim().isEmpty()
                        || officialEmail  == null || !officialEmail.contains("@")) {
                    req.setAttribute("errorMessage","Company name, website and official email are required.");
                    req.getRequestDispatcher("register.jsp").forward(req, res); return;
                }

                // Official email must NOT be gmail/yahoo/hotmail
                String domain = officialEmail.substring(officialEmail.indexOf("@")+1).toLowerCase();
                if (domain.contains("gmail") || domain.contains("yahoo") || domain.contains("hotmail")
                        || domain.contains("outlook") || domain.contains("rediffmail")) {
                    req.setAttribute("errorMessage","Please use your official company email, not a personal email.");
                    req.getRequestDispatcher("register.jsp").forward(req, res); return;
                }

                try (PreparedStatement ins = conn.prepareStatement(
                        "INSERT INTO users (username,email,password_hash,role,status,full_name,phone,company_name,company_website,official_email) VALUES (?,?,?,?,?,?,?,?,?,?)")) {
                    ins.setString(1, username.trim());
                    ins.setString(2, email.trim());
                    ins.setString(3, hash);
                    ins.setString(4, role);
                    ins.setString(5, status);
                    ins.setString(6, fullName.trim());
                    ins.setString(7, phone != null ? phone.trim() : "");
                    ins.setString(8, companyName.trim());
                    ins.setString(9, companyWebsite.trim());
                    ins.setString(10, officialEmail.trim());
                    ins.executeUpdate();
                }

            } else { // COLLEGE_ADMIN
                String collegeName   = req.getParameter("collegeName");
                String collegeCity   = req.getParameter("collegeCity");
                String collegeCode   = req.getParameter("collegeCode");

                if (collegeName == null || collegeName.trim().isEmpty()
                        || collegeCity == null || collegeCity.trim().isEmpty()
                        || collegeCode == null || collegeCode.trim().isEmpty()) {
                    req.setAttribute("errorMessage","College name, city and code are required.");
                    req.getRequestDispatcher("register.jsp").forward(req, res); return;
                }

                // Check duplicate college code
                try (PreparedStatement cp = conn.prepareStatement(
                        "SELECT id FROM colleges WHERE college_code=?")) {
                    cp.setString(1, collegeCode.trim().toUpperCase());
                    if (cp.executeQuery().next()) {
                        req.setAttribute("errorMessage","A college with this code already exists.");
                        req.getRequestDispatcher("register.jsp").forward(req, res); return;
                    }
                }

                // Insert college first
                int collegeId;
                try (PreparedStatement ci = conn.prepareStatement(
                        "INSERT INTO colleges (name,city,college_code,status) VALUES (?,?,?,?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    ci.setString(1, collegeName.trim());
                    ci.setString(2, collegeCity.trim());
                    ci.setString(3, collegeCode.trim().toUpperCase());
                    ci.setString(4, "PENDING");
                    ci.executeUpdate();
                    ResultSet gk = ci.getGeneratedKeys();
                    gk.next(); collegeId = gk.getInt(1);
                }

                try (PreparedStatement ins = conn.prepareStatement(
                        "INSERT INTO users (username,email,password_hash,role,status,full_name,phone,college_id) VALUES (?,?,?,?,?,?,?,?)")) {
                    ins.setString(1, username.trim());
                    ins.setString(2, email.trim());
                    ins.setString(3, hash);
                    ins.setString(4, "COLLEGE_ADMIN");
                    ins.setString(5, "PENDING");
                    ins.setString(6, fullName.trim());
                    ins.setString(7, phone != null ? phone.trim() : "");
                    ins.setInt(8, collegeId);
                    ins.executeUpdate();
                }
            }

            res.sendRedirect("login.jsp?registered=1");

        } catch (Exception e) {
            e.printStackTrace();
            req.setAttribute("errorMessage","Registration failed. Please try again.");
            req.getRequestDispatcher("register.jsp").forward(req, res);
        }
    }
}
