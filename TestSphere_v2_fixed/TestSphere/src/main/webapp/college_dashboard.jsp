<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.testsphere.util.DBConnection,com.testsphere.util.HtmlUtils" %>
<%@ page session="true" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>College Dashboard — TestSphere</title><link rel="stylesheet" href="<%= request.getContextPath() %>/css/main.css"></head><body>
<%
  String user=(String)session.getAttribute("username");String name=(String)session.getAttribute("fullName");
  int uid=Integer.parseInt((String)session.getAttribute("userId"));
  if(user==null||!"COLLEGE_ADMIN".equals(session.getAttribute("role"))){response.sendRedirect("login.jsp");return;}
  String ini=name!=null&&name.length()>=2?name.substring(0,2).toUpperCase():user.substring(0,Math.min(2,user.length())).toUpperCase();

  int collegeId=0; String collegeName="",collegeCode="",collegeCity="", collegeStatus="", collegeStatusBadge="";
  int totalStudents=0,finalYearStudents=0,activeDrives=0,placedStudents=0,pendingStudents=0;

  try(Connection conn=DBConnection.getConnection()){
    try(PreparedStatement ps=conn.prepareStatement("SELECT college_id FROM users WHERE id=?")){
      ps.setInt(1,uid);ResultSet rs=ps.executeQuery();if(rs.next())collegeId=rs.getInt("college_id");
    }
    if(collegeId>0){
      try(PreparedStatement ps=conn.prepareStatement("SELECT name,college_code,city,status FROM colleges WHERE id=?")){
        ps.setInt(1,collegeId);ResultSet rs=ps.executeQuery();
        if(rs.next()){collegeName=rs.getString("name");collegeCode=rs.getString("college_code");collegeCity=rs.getString("city");collegeStatus=rs.getString("status");}
      }
      // Compute status badge if college not approved
      if(collegeStatus!=null && !"APPROVED".equals(collegeStatus)){
        String badgeClass = "PENDING".equals(collegeStatus) ? "bg-orange" : "bg-red";
        collegeStatusBadge = "<span class='badge " + badgeClass + "'>" + HtmlUtils.escape(collegeStatus) + "</span>";
      }
      try(PreparedStatement ps=conn.prepareStatement("SELECT COUNT(*) FROM users WHERE college_id=? AND role='STUDENT' AND status='ACTIVE'")){
        ps.setInt(1,collegeId);ResultSet rs=ps.executeQuery();if(rs.next())totalStudents=rs.getInt(1);
      }
      try(PreparedStatement ps=conn.prepareStatement("SELECT COUNT(*) FROM users WHERE college_id=? AND role='STUDENT' AND status='PENDING'")){ps.setInt(1,collegeId);ResultSet rs=ps.executeQuery();if(rs.next())pendingStudents=rs.getInt(1);}
      try(PreparedStatement ps=conn.prepareStatement("SELECT COUNT(*) FROM users WHERE college_id=? AND role='STUDENT' AND status='ACTIVE' AND year_of_study='Final Year'")){
        ps.setInt(1,collegeId);ResultSet rs=ps.executeQuery();if(rs.next())finalYearStudents=rs.getInt(1);
      }
      try(PreparedStatement ps=conn.prepareStatement("SELECT COUNT(*) FROM drives WHERE college_id=? AND status='ACTIVE'")){
        ps.setInt(1,collegeId);ResultSet rs=ps.executeQuery();if(rs.next())activeDrives=rs.getInt(1);
      }
      try(PreparedStatement ps=conn.prepareStatement(
        "SELECT COUNT(DISTINCT da.student_id) FROM drive_applications da JOIN drives d ON da.drive_id=d.id WHERE d.college_id=? AND da.status='SELECTED'")){
        ps.setInt(1,collegeId);ResultSet rs=ps.executeQuery();if(rs.next())placedStudents=rs.getInt(1);
      }
    }
  }catch(Exception e){e.printStackTrace();}
%>
<div class="sidebar"><div class="sb-brand">Test<span>Sphere</span></div>
  <ul class="menu">
    <li class="active"><a href="college_dashboard.jsp"><span class="ico">⊞</span>Dashboard</a></li>
    <li><a href="college_students.jsp"><span class="ico">👥</span>Students<% if(pendingStudents>0){%><span class="notif-dot"></span><%}%></a></li>
    <li><a href="college_drives.jsp"><span class="ico">🏢</span>Drives</a></li>
  </ul>
  <div class="sb-foot"><div class="sb-user"><div class="avatar"><%= HtmlUtils.escape(ini) %></div>
    <div><div class="user-name"><%= HtmlUtils.escape(name!=null?name:user) %></div>
    <div class="user-role-lbl">College Admin</div></div></div>
    <a href="logout" class="logout-lnk">↩ Sign Out</a></div></div>
<div class="main">
  <div class="topbar">
    <div><h1><%= HtmlUtils.escape(collegeName) %> <%= collegeStatusBadge %></h1>
      <p><%= HtmlUtils.escape(collegeCode) %> &nbsp;·&nbsp; <%= HtmlUtils.escape(collegeCity) %></p>
    </div>
  </div>
  <div class="content">
    <% if("1".equals(request.getParameter("broadcasted"))){%>
      <div class="alert alert-success">✓ Drive notification sent to all active students.</div>
    <%}%>
    <% if(pendingStudents>0){%><div class="alert alert-warn">⚠ <strong><%= pendingStudents %></strong> student registration<%= pendingStudents>1?"s are":" is"%> pending your approval. <a href="college_students.jsp" style="color:inherit;font-weight:600">Review now →</a></div><%}%>
    <div class="stats-grid">
      <a href="college_students.jsp" class="stat-card"><div class="stat-lbl">Total Students</div><div class="stat-val"><%= totalStudents %></div><div class="stat-sub">Registered</div></a>
      <a href="college_students.jsp" class="stat-card"><div class="stat-lbl">Final Year</div><div class="stat-val"><%= finalYearStudents %></div><div class="stat-sub">Placement eligible</div></a>
      <a href="college_drives.jsp" class="stat-card"><div class="stat-lbl">Active Drives</div><div class="stat-val"><%= activeDrives %></div><div class="stat-sub">Currently running</div></a>
      <div class="stat-card"><div class="stat-lbl">Students Placed</div><div class="stat-val"><%= placedStudents %></div><div class="stat-sub">Final selections</div></div>
    </div>

    <div class="section" style="margin-bottom:20px">
      <div class="sec-hdr"><span class="sec-title">Active Placement Drives at <%= HtmlUtils.escape(collegeName) %></span></div>
      <table><thead><tr><th>Drive</th><th>Company</th><th>Role</th><th>Applicants</th><th>Deadline</th><th>Status</th><th>Notify Students</th></tr></thead><tbody>
<%
  boolean anyDrive=false;
  try(Connection conn=DBConnection.getConnection();PreparedStatement ps=conn.prepareStatement(
    "SELECT d.title,d.job_role,d.registration_deadline,d.status,u.company_name," +
    "(SELECT COUNT(*) FROM drive_applications da WHERE da.drive_id=d.id) AS apps " +
    "FROM drives d JOIN users u ON d.recruiter_id=u.id " +
    "WHERE d.college_id=? ORDER BY d.id DESC")){
    ps.setInt(1,collegeId);ResultSet rs=ps.executeQuery();
    while(rs.next()){anyDrive=true;String st=rs.getString("status");%>
    <tr><td><strong><%= HtmlUtils.escape(rs.getString("title")) %></strong></td>
      <td><%= HtmlUtils.escape(rs.getString("company_name")) %></td>
      <td><%= HtmlUtils.escape(rs.getString("job_role")) %></td>
      <td><%= rs.getInt("apps") %></td>
      <td class="text-sm text-muted"><%= rs.getString("registration_deadline")!=null?rs.getString("registration_deadline").substring(0,10):"—" %></td>
      <td><span class="badge <%= "ACTIVE".equals(st)?"bg-green":"DRAFT".equals(st)?"bg-orange":"bg-gray" %>"><%= st %></span></td>
      <td>
        <% if("ACTIVE".equals(st)){%>
        <form method="POST" action="college/broadcastDrive" style="margin:0"
          onsubmit="return confirm('Send drive notification to all active students?')">
          <input type="hidden" name="driveId" value="<%= rs.getInt("id") %>">
          <button class="btn-primary btn-sm">📢 Notify All</button>
        </form>
        <%}else{%><span class="text-sm text-muted">—</span><%}%>
      </td>
    </tr>
<%  }}catch(Exception e){e.printStackTrace();}
  if(!anyDrive){%><tr><td colspan="7"><div class="empty-state"><div class="ico">🏢</div><p>No drives targeting your college yet.</p></div></td></tr><%}%>
      </tbody></table></div>

    <div class="section">
      <div class="sec-hdr"><span class="sec-title">Recent Student Registrations</span></div>
      <table><thead><tr><th>Name</th><th>Branch</th><th>Year</th><th>CGPA</th><th>Backlogs</th><th>Joined</th></tr></thead><tbody>
<%
  try(Connection conn=DBConnection.getConnection();PreparedStatement ps=conn.prepareStatement(
    "SELECT full_name,branch,year_of_study,cgpa,backlogs,created_at FROM users WHERE college_id=? AND role='STUDENT' AND status='ACTIVE' ORDER BY created_at DESC LIMIT 20")){
    ps.setInt(1,collegeId);ResultSet rs=ps.executeQuery();
    boolean anyS=false;
    while(rs.next()){anyS=true;%>
    <tr><td><strong><%= HtmlUtils.escape(rs.getString("full_name")) %></strong></td>
      <td><span class="badge bg-blue"><%= HtmlUtils.escape(rs.getString("branch")) %></span></td>
      <td><%= HtmlUtils.escape(rs.getString("year_of_study")) %></td>
      <td><%= rs.getDouble("cgpa") %></td>
      <td><%= rs.getInt("backlogs") %></td>
      <td class="text-sm text-muted"><%= rs.getTimestamp("created_at").toString().substring(0,10) %></td>
    </tr>
<%  }
    if(!anyS){%><tr><td colspan="6"><div class="empty-state" style="padding:24px"><p>No students registered yet under this college.</p></div></td></tr><%}}catch(Exception e){e.printStackTrace();}%>
      </tbody></table></div>
  </div>
</div></body></html>
