<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page session="true" %>
<%@ page import="com.testsphere.util.HtmlUtils" %>
<!DOCTYPE html><html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>TestSphere — Sign In</title>
<link rel="stylesheet" href="css/main.css"></head>
<body class="auth-page">
<%
  response.setHeader("Cache-Control","no-cache,no-store,must-revalidate");
  response.setHeader("Pragma","no-cache"); response.setDateHeader("Expires",0);
  if(session.getAttribute("userId")!=null){
    String r=(String)session.getAttribute("role");
    response.sendRedirect("ADMIN".equals(r)?"admin_dashboard.jsp":"RECRUITER".equals(r)?"recruiter_dashboard.jsp":"STUDENT".equals(r)?"student_dashboard.jsp":"college_dashboard.jsp");
    return;
  }
  String err=(String)request.getAttribute("errorMessage");
  String reg=request.getParameter("registered");
%>
<div class="auth-wrap">
  <div class="brand">Test<span>Sphere</span></div>
  <div class="brand-sub">College Placement Platform</div>
  <div class="card">
    <% if(err!=null){%><div class="alert alert-error"><%= HtmlUtils.escape(err) %></div><%}%>
    <% if("1".equals(reg)){%><div class="alert alert-success">Account created! Students must wait for college admin approval before logging in. Recruiters/colleges await admin approval.</div><%}%>
    <form method="POST" action="login">
      <div class="field"><label>Username</label>
        <input type="text" name="username" placeholder="Enter username" autocomplete="username" required autofocus></div>
      <div class="field"><label>Password</label>
        <input type="password" name="password" placeholder="Enter password" autocomplete="current-password" required></div>
      <button type="submit" class="auth-btn">Sign In</button>
    </form>
    <div class="card-foot" style="margin-top:16px">
      New here? <a href="register.jsp">Create an account</a>
    </div>
  </div>
</div>
</body></html>
