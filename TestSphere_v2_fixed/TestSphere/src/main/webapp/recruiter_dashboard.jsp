<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.testsphere.util.DBConnection,com.testsphere.util.HtmlUtils" %>
<%@ page session="true" %>
<!DOCTYPE html><html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Recruiter Dashboard — TestSphere</title>
<link rel="stylesheet" href="<%= request.getContextPath() %>/css/main.css"></head>
<body>
<%
  String user=(String)session.getAttribute("username");
  String name=(String)session.getAttribute("fullName");
  int uid=Integer.parseInt((String)session.getAttribute("userId"));
  if(user==null||!"RECRUITER".equals(session.getAttribute("role"))){response.sendRedirect("login.jsp");return;}
  String ini=name!=null&&name.length()>=2?name.substring(0,2).toUpperCase():user.substring(0,Math.min(2,user.length())).toUpperCase();
  int totalDrives=0,activeDrives=0,totalApplicants=0,totalCompleted=0;
  try(Connection conn=DBConnection.getConnection()){
    try(PreparedStatement ps=conn.prepareStatement("SELECT COUNT(*) FROM drives WHERE recruiter_id=?")){ps.setInt(1,uid);ResultSet rs=ps.executeQuery();if(rs.next())totalDrives=rs.getInt(1);}
    try(PreparedStatement ps=conn.prepareStatement("SELECT COUNT(*) FROM drives WHERE recruiter_id=? AND status='ACTIVE'")){ps.setInt(1,uid);ResultSet rs=ps.executeQuery();if(rs.next())activeDrives=rs.getInt(1);}
    try(PreparedStatement ps=conn.prepareStatement("SELECT COUNT(*) FROM drive_applications da JOIN drives d ON da.drive_id=d.id WHERE d.recruiter_id=?")){ps.setInt(1,uid);ResultSet rs=ps.executeQuery();if(rs.next())totalApplicants=rs.getInt(1);}
    try(PreparedStatement ps=conn.prepareStatement("SELECT COUNT(*) FROM drive_applications da JOIN drives d ON da.drive_id=d.id WHERE d.recruiter_id=? AND da.status='SELECTED'")){ps.setInt(1,uid);ResultSet rs=ps.executeQuery();if(rs.next())totalCompleted=rs.getInt(1);}
  }catch(Exception e){e.printStackTrace();}
%>
<div class="sidebar">
  <div class="sb-brand">Test<span>Sphere</span></div>
  <ul class="menu">
    <li class="active"><a href="recruiter_dashboard.jsp"><span class="ico">⊞</span>Dashboard</a></li>
    <li><a href="manage_drives.jsp"><span class="ico">📋</span>My Drives</a></li>
    <li><a href="create_drive.jsp"><span class="ico">＋</span>Create Drive</a></li>
  </ul>
  <div class="sb-foot">
    <div class="sb-user"><div class="avatar"><%= HtmlUtils.escape(ini) %></div>
      <div><div class="user-name"><%= HtmlUtils.escape(name!=null?name:user) %></div>
      <div class="user-role-lbl">Recruiter</div></div>
    </div>
    <a href="logout" class="logout-lnk">↩ Sign Out</a>
  </div>
</div>
<div class="main">
  <div class="topbar">
    <div><h1>Dashboard</h1><p>Welcome back, <%= HtmlUtils.escape(name!=null?name:user) %></p></div>
    <div class="topbar-actions"><a href="create_drive.jsp" class="btn-primary">+ New Drive</a></div>
  </div>
  <div class="content">
    <div class="stats-grid">
      <a href="manage_drives.jsp" class="stat-card"><div class="stat-lbl">Total Drives</div><div class="stat-val"><%= totalDrives %></div><div class="stat-sub">All time</div></a>
      <a href="manage_drives.jsp" class="stat-card"><div class="stat-lbl">Active Drives</div><div class="stat-val"><%= activeDrives %></div><div class="stat-sub">Currently running</div></a>
      <div class="stat-card"><div class="stat-lbl">Total Applicants</div><div class="stat-val"><%= totalApplicants %></div><div class="stat-sub">Across all drives</div></div>
      <div class="stat-card"><div class="stat-lbl">Final Selections</div><div class="stat-val"><%= totalCompleted %></div><div class="stat-sub">Offers made</div></div>
    </div>
    <div class="section">
      <div class="sec-hdr"><span class="sec-title">Recent Drives</span><a href="manage_drives.jsp" class="btn-ghost">View all →</a></div>
      <table><thead><tr><th>Drive</th><th>College</th><th>Status</th><th>Applicants</th><th>Reg. Deadline</th><th></th></tr></thead><tbody>
<%
  boolean any=false;
  try(Connection conn=DBConnection.getConnection();
      PreparedStatement ps=conn.prepareStatement(
        "SELECT d.id,d.title,d.status,d.registration_deadline,c.name AS cname," +
        "(SELECT COUNT(*) FROM drive_applications da WHERE da.drive_id=d.id) AS apps " +
        "FROM drives d JOIN colleges c ON d.college_id=c.id " +
        "WHERE d.recruiter_id=? ORDER BY d.id DESC LIMIT 8")){
    ps.setInt(1,uid);ResultSet rs=ps.executeQuery();
    while(rs.next()){any=true;String st=rs.getString("status");%>
    <tr>
      <td><strong><%= HtmlUtils.escape(rs.getString("title")) %></strong></td>
      <td><%= HtmlUtils.escape(rs.getString("cname")) %></td>
      <td><span class="badge <%= "ACTIVE".equals(st)?"bg-green":"DRAFT".equals(st)?"bg-orange":"bg-gray" %>"><%= st %></span></td>
      <td><%= rs.getInt("apps") %></td>
      <td class="text-sm text-muted"><%= rs.getString("registration_deadline")!=null?rs.getString("registration_deadline").substring(0,10):"—" %></td>
      <td><a href="drive_detail.jsp?driveId=<%= rs.getInt("id") %>" class="btn-ghost btn-sm">Manage →</a></td>
    </tr>
<%  }}catch(Exception e){e.printStackTrace();}
  if(!any){%><tr><td colspan="6"><div class="empty-state"><div class="ico">📋</div><p>No drives yet. <a href="create_drive.jsp" style="color:var(--accent)">Create your first drive →</a></p></div></td></tr><%}%>
      </tbody></table>
    </div>
  </div>
</div>
</body></html>
