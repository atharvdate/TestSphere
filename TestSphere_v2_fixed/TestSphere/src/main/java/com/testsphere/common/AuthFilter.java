package com.testsphere.common;

import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.*;
import java.io.IOException;
import java.util.Set;

@WebFilter("/*")
public class AuthFilter implements Filter {

    private static final Set<String> PUBLIC = Set.of(
        "/login.jsp", "/register.jsp", "/drive_info.jsp", "/login", "/register", "/join", "/joinDrive"
    );
    private static final Set<String> STATIC_EXT = Set.of(
        ".css",".js",".png",".jpg",".jpeg",".ico",".gif",".svg",".woff",".woff2"
    );
    private static final Set<String> ADMIN_PATHS = Set.of(
        "/admin_dashboard.jsp","/admin/approve_recruiter","/admin/approve_college",
        "/admin/reject_recruiter","/admin/reject_college","/admin/deactivate"
    );
    private static final Set<String> RECRUITER_PATHS = Set.of(
        "/recruiter_dashboard.jsp","/manage_drives.jsp","/create_drive.jsp",
        "/drive_detail.jsp","/add_round.jsp","/add_question.jsp",
        "/round_results.jsp","/drive_analytics.jsp",
        "/createDrive","/updateDrive","/updateDriveStatus","/deleteDrive",
        "/addRound","/addQuestion","/deleteQuestion",
        "/releaseResults","/markRoundResult",
        "/shortlistApplicant","/serveResume"
    );
    private static final Set<String> STUDENT_PATHS = Set.of(
        "/student_dashboard.jsp","/student_notifications.jsp",
        "/attempt_round.jsp","/my_applications.jsp",
        "/submitTest"
    );
    private static final Set<String> COLLEGE_PATHS = Set.of(
        "/college_dashboard.jsp","/college_students.jsp","/college_drives.jsp",
        "/college/approveStudent","/college/broadcastDrive"
    );

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  request  = (HttpServletRequest)  req;
        HttpServletResponse response = (HttpServletResponse) res;

        response.setHeader("Cache-Control","no-cache, no-store, must-revalidate");
        response.setHeader("Pragma","no-cache");
        response.setDateHeader("Expires",0);

        String ctx  = request.getContextPath();
        String uri  = request.getRequestURI();
        String path = uri.substring(ctx.length());

        for (String ext : STATIC_EXT) {
            if (path.endsWith(ext)) { chain.doFilter(req, res); return; }
        }
        if (PUBLIC.contains(path)) { chain.doFilter(req, res); return; }

        HttpSession session = request.getSession(false);
        String userId = session != null ? (String) session.getAttribute("userId") : null;
        String role   = session != null ? (String) session.getAttribute("role")   : null;

        if (userId == null) { response.sendRedirect(ctx + "/login.jsp"); return; }

        if (ADMIN_PATHS.contains(path)    && !"ADMIN".equals(role))          { response.sendRedirect(ctx + "/login.jsp"); return; }
        if (RECRUITER_PATHS.contains(path)&& !"RECRUITER".equals(role))      { response.sendRedirect(ctx + "/login.jsp"); return; }
        if (STUDENT_PATHS.contains(path)  && !"STUDENT".equals(role))        { response.sendRedirect(ctx + "/login.jsp"); return; }
        if (COLLEGE_PATHS.contains(path)  && !"COLLEGE_ADMIN".equals(role))  { response.sendRedirect(ctx + "/login.jsp"); return; }

        chain.doFilter(req, res);
    }
}
