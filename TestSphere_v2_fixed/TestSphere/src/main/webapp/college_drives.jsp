<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.testsphere.util.DBConnection,com.testsphere.util.HtmlUtils" %>
<%@ page session="true" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Drives — TestSphere</title><link rel="stylesheet" href="<%= request.getContextPath() %>/css/main.css"></head><body>
<%
  String user=(String)session.getAttribute("username");String name=(String)session.getAttribute("fullName");
  int uid=Integer.parseInt((String)session.getAttribute("userId"));
  if(user==null||!"COLLEGE_ADMIN".equals(session.getAttribute("role"))){response.sendRedirect("login.jsp");return;}
  String ini=name!=null&&name.length()>=2?name.substring(0,2).toUpperCase():user.substring(0,Math.min(2,user.length())).toUpperCase();
  int collegeId=0;
  try(Connection conn=DBConnection.getConnection();PreparedStatement ps=conn.prepareStatement("SELECT college_id FROM users WHERE id=?")){
    ps.setInt(1,uid);ResultSet rs=ps.executeQuery();if(rs.next())collegeId=rs.getInt("college_id");
  }catch(Exception e){e.printStackTrace();}
%>
<div class="sidebar"><div class="sb-brand">Test<span>Sphere</span></div>
  <ul class="menu"><li><a href="college_dashboard.jsp"><span class="ico">⊞</span>Dashboard</a></li>
    <li><a href="college_students.jsp"><span class="ico">👥</span>Students</a></li>
    <li class="active"><a href="college_drives.jsp"><span class="ico">🏢</span>Drives</a></li></ul>
  <div class="sb-foot"><div class="sb-user"><div class="avatar"><%= HtmlUtils.escape(ini) %></div>
    <div><div class="user-name"><%= HtmlUtils.escape(name!=null?name:user) %></div><div class="user-role-lbl">College Admin</div></div></div>
    <a href="logout" class="logout-lnk">↩ Sign Out</a></div></div>
<div class="main">
  <div class="topbar"><div><h1>Placement Drives</h1><p>All drives targeting your college</p></div></div>
  <div class="content">
    <div class="section"><div class="sec-hdr"><span class="sec-title">All Drives</span></div>
      <table><thead><tr><th>Drive</th><th>Company</th><th>Role</th><th>Package</th><th>Applicants</th><th>Placed</th><th>Status</th></tr></thead><tbody>
<%
  boolean any=false;
  try(Connection conn=DBConnection.getConnection();PreparedStatement ps=conn.prepareStatement(
    "SELECT d.title,d.job_role,d.package_lpa,d.status,u.company_name," +
    "(SELECT COUNT(*) FROM drive_applications da WHERE da.drive_id=d.id) AS apps," +
    "(SELECT COUNT(*) FROM drive_applications da WHERE da.drive_id=d.id AND da.status='SELECTED') AS placed " +
    "FROM drives d JOIN users u ON d.recruiter_id=u.id WHERE d.college_id=? ORDER BY d.id DESC")){
    ps.setInt(1,collegeId);ResultSet rs=ps.executeQuery();
    while(rs.next()){any=true;String st=rs.getString("status");%>
    <tr><td><strong><%= HtmlUtils.escape(rs.getString("title")) %></strong></td>
      <td><%= HtmlUtils.escape(rs.getString("company_name")) %></td>
      <td><%= HtmlUtils.escape(rs.getString("job_role")) %></td>
      <td><%= rs.getString("package_lpa")!=null&&!rs.getString("package_lpa").isEmpty()?HtmlUtils.escape(rs.getString("package_lpa")):"—" %></td>
      <td><%= rs.getInt("apps") %></td>
      <td><span class="badge bg-green"><%= rs.getInt("placed") %></span></td>
      <td><span class="badge <%= "ACTIVE".equals(st)?"bg-green":"DRAFT".equals(st)?"bg-orange":"bg-gray" %>"><%= st %></span></td>
    </tr>
<%  }}catch(Exception e){e.printStackTrace();}
  if(!any){%><tr><td colspan="7"><div class="empty-state"><div class="ico">🏢</div><p>No drives targeting your college yet.</p></div></td></tr><%}%>
      </tbody></table></div></div></div></body></html>
