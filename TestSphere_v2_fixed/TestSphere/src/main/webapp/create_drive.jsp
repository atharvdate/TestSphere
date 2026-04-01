<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.testsphere.util.DBConnection,com.testsphere.util.HtmlUtils" %>
<%@ page session="true" %>
<!DOCTYPE html><html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Create Drive — TestSphere</title>
<link rel="stylesheet" href="<%= request.getContextPath() %>/css/main.css"></head>
<body>
<%
  String user=(String)session.getAttribute("username");
  String name=(String)session.getAttribute("fullName");
  if(user==null||!"RECRUITER".equals(session.getAttribute("role"))){response.sendRedirect("login.jsp");return;}
  String ini=name!=null&&name.length()>=2?name.substring(0,2).toUpperCase():user.substring(0,Math.min(2,user.length())).toUpperCase();
  String err=(String)request.getAttribute("errorMessage");
%>
<div class="sidebar">
  <div class="sb-brand">Test<span>Sphere</span></div>
  <ul class="menu">
    <li><a href="recruiter_dashboard.jsp"><span class="ico">⊞</span>Dashboard</a></li>
    <li><a href="manage_drives.jsp"><span class="ico">📋</span>My Drives</a></li>
    <li class="active"><a href="create_drive.jsp"><span class="ico">＋</span>Create Drive</a></li>
  </ul>
  <div class="sb-foot">
    <div class="sb-user"><div class="avatar"><%= HtmlUtils.escape(ini) %></div>
      <div><div class="user-name"><%= HtmlUtils.escape(name!=null?name:user) %></div><div class="user-role-lbl">Recruiter</div></div>
    </div>
    <a href="logout" class="logout-lnk">↩ Sign Out</a>
  </div>
</div>
<div class="main">
  <div class="topbar">
    <div><h1>Create Placement Drive</h1><p>Set up a new campus recruitment drive</p></div>
    <div class="topbar-actions"><a href="manage_drives.jsp" class="btn-secondary">← Back</a></div>
  </div>
  <div class="content">
    <% if(err!=null){%><div class="alert alert-error"><%= HtmlUtils.escape(err) %></div><%}%>
    <div class="form-card">
      <form action="createDrive" method="post">
        <div class="form-group"><label>Drive Title <span class="req">*</span></label>
          <input type="text" name="title" placeholder="e.g. Campus Recruitment Drive 2025" required></div>
        <div class="form-row">
          <div class="form-group"><label>Job Role <span class="req">*</span></label>
            <input type="text" name="jobRole" placeholder="e.g. Software Engineer" required></div>
          <div class="form-group"><label>Package (LPA)</label>
            <input type="text" name="packageLpa" placeholder="e.g. 6.5 LPA"></div>
        </div>
        <div class="form-group"><label>Description</label>
          <textarea name="description" rows="3" placeholder="Job description, requirements, company info…"></textarea></div>
        <div class="form-group"><label>Target College <span class="req">*</span></label>
          <select name="collegeId" required>
            <option value="" disabled selected hidden>Select a college</option>
<%
  try(Connection conn=DBConnection.getConnection();
      PreparedStatement ps=conn.prepareStatement("SELECT id,name,city FROM colleges WHERE status='APPROVED' ORDER BY name")){
    ResultSet rs=ps.executeQuery();
    while(rs.next()){%>
            <option value="<%= rs.getInt("id") %>"><%= HtmlUtils.escape(rs.getString("name")) %> — <%= HtmlUtils.escape(rs.getString("city")) %></option>
<%  }}catch(Exception e){e.printStackTrace();}%>
          </select></div>
        <div class="form-group"><label>Registration Deadline <span class="req">*</span></label>
          <input type="datetime-local" name="regDeadline" required>
          <span class="form-hint">Students cannot join after this date/time</span></div>
        <div class="divider"></div>
        <div style="font-size:14px;font-weight:600;margin-bottom:14px;color:var(--text)">Eligibility Criteria</div>
        <div class="form-row">
          <div class="form-group"><label>Year of Study</label>
            <select name="eligibilityYear">
              <option value="ALL">All Years</option>
              <option value="Final Year" selected>Final Year Only</option>
              <option value="3rd Year">3rd Year Only</option>
            </select></div>
          <div class="form-group"><label>Minimum CGPA</label>
            <input type="number" name="eligibilityMinCgpa" placeholder="e.g. 6.5" step="0.1" min="0" max="10" value="0"></div>
        </div>
        <div class="form-row">
          <div class="form-group"><label>Max Active Backlogs Allowed</label>
            <input type="number" name="eligibilityMaxBacklogs" placeholder="0 = no backlogs" min="0" value="0"></div>
          <div class="form-group"><label>Eligible Branches</label>
            <input type="text" name="eligibilityBranches" placeholder="e.g. CSE,IT,ECE or ALL" value="ALL">
            <span class="form-hint">Comma-separated branch codes, or ALL</span></div>
        </div>
        <div style="display:flex;gap:10px;margin-top:8px">
          <button type="submit" class="btn-primary">Create Drive</button>
          <a href="manage_drives.jsp" class="btn-secondary">Cancel</a>
        </div>
      </form>
    </div>
  </div>
</div>
</body></html>
