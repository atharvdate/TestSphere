package com.testsphere.auth;

import com.testsphere.util.DBConnection;
import org.mindrot.jbcrypt.BCrypt;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        HttpSession s = req.getSession(false);
        if (s != null && s.getAttribute("userId") != null) {
            redirectByRole(res, (String) s.getAttribute("role"));
            return;
        }
        req.getRequestDispatcher("login.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String username = req.getParameter("username");
        String password = req.getParameter("password");

        if (username == null || username.trim().isEmpty()
                || password == null || password.isEmpty()) {
            req.setAttribute("errorMessage","Username and password are required.");
            req.getRequestDispatcher("login.jsp").forward(req, res); return;
        }

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "SELECT id, password_hash, role, status, full_name FROM users WHERE BINARY username=?")) {
            ps.setString(1, username.trim());
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                String hash   = rs.getString("password_hash");
                String role   = rs.getString("role");
                String status = rs.getString("status");
                String name   = rs.getString("full_name");
                int    uid    = rs.getInt("id");

                if (!BCrypt.checkpw(password, hash)) {
                    req.setAttribute("errorMessage","Invalid username or password.");
                    req.getRequestDispatcher("login.jsp").forward(req, res); return;
                }
                if ("PENDING".equals(status)) {
                    String pendingMsg = "STUDENT".equals(role)
                        ? "Your account is pending approval by your college admin. Please wait."
                        : "Your account is pending admin approval. Please wait.";
                    req.setAttribute("errorMessage", pendingMsg);
                    req.getRequestDispatcher("login.jsp").forward(req, res); return;
                }
                if ("REJECTED".equals(status) || "INACTIVE".equals(status)) {
                    req.setAttribute("errorMessage","Your account has been rejected or deactivated.");
                    req.getRequestDispatcher("login.jsp").forward(req, res); return;
                }

                HttpSession old = req.getSession(false);
                if (old != null) old.invalidate();
                HttpSession session = req.getSession(true);
                session.setAttribute("userId",   String.valueOf(uid));
                session.setAttribute("username", username.trim());
                session.setAttribute("role",     role);
                session.setAttribute("fullName", name);
                session.setMaxInactiveInterval(3600);

                redirectByRole(res, role);
            } else {
                req.setAttribute("errorMessage","Invalid username or password.");
                req.getRequestDispatcher("login.jsp").forward(req, res);
            }
        } catch (Exception e) {
            e.printStackTrace();
            req.setAttribute("errorMessage","Server error. Please try again.");
            req.getRequestDispatcher("login.jsp").forward(req, res);
        }
    }

    private void redirectByRole(HttpServletResponse res, String role) throws IOException {
        switch (role) {
            case "ADMIN":         res.sendRedirect("admin_dashboard.jsp");    break;
            case "RECRUITER":     res.sendRedirect("recruiter_dashboard.jsp");break;
            case "STUDENT":       res.sendRedirect("student_dashboard.jsp");  break;
            case "COLLEGE_ADMIN": res.sendRedirect("college_dashboard.jsp");  break;
            default:              res.sendRedirect("login.jsp");
        }
    }
}
