<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.testsphere.util.DBConnection,com.testsphere.util.HtmlUtils" %>
<%@ page session="true" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Students — TestSphere</title><link rel="stylesheet" href="<%= request.getContextPath() %>/css/main.css"></head><body>
<%
  String user=(String)session.getAttribute("username");String name=(String)session.getAttribute("fullName");
  int uid=Integer.parseInt((String)session.getAttribute("userId"));
  if(user==null||!"COLLEGE_ADMIN".equals(session.getAttribute("role"))){response.sendRedirect("login.jsp");return;}
  String ini=name!=null&&name.length()>=2?name.substring(0,2).toUpperCase():user.substring(0,Math.min(2,user.length())).toUpperCase();
  int collegeId=0;
  try(Connection conn=DBConnection.getConnection();PreparedStatement ps=conn.prepareStatement("SELECT college_id FROM users WHERE id=?")){
    ps.setInt(1,uid);ResultSet rs=ps.executeQuery();if(rs.next())collegeId=rs.getInt("college_id");
  }catch(Exception e){e.printStackTrace();}
  int pendingCount=0;
  try(Connection conn=DBConnection.getConnection();PreparedStatement ps=conn.prepareStatement("SELECT COUNT(*) FROM users WHERE college_id=? AND role='STUDENT' AND status='PENDING'")){
    ps.setInt(1,collegeId);ResultSet rs=ps.executeQuery();if(rs.next())pendingCount=rs.getInt(1);
  }catch(Exception e){e.printStackTrace();}
  String action=request.getParameter("action");
%>
<div class="sidebar"><div class="sb-brand">Test<span>Sphere</span></div>
  <ul class="menu"><li><a href="college_dashboard.jsp"><span class="ico">⊞</span>Dashboard</a></li>
    <li class="active"><a href="college_students.jsp"><span class="ico">👥</span>Students</a></li>
    <li><a href="college_drives.jsp"><span class="ico">🏢</span>Drives</a></li></ul>
  <div class="sb-foot"><div class="sb-user"><div class="avatar"><%= HtmlUtils.escape(ini) %></div>
    <div><div class="user-name"><%= HtmlUtils.escape(name!=null?name:user) %></div><div class="user-role-lbl">College Admin</div></div></div>
    <a href="logout" class="logout-lnk">↩ Sign Out</a></div></div>
<div class="main">
  <div class="topbar"><div><h1>Students</h1><p>Manage student registrations at your college</p></div></div>
  <div class="content">
    <% if("approved".equals(action)){%><div class="alert alert-success">✓ Student approved. They can now log in.</div><%}%>
    <% if("rejected".equals(action)){%><div class="alert alert-error">Student registration rejected.</div><%}%>

    <%-- PENDING APPROVALS --%>
    <div class="section" style="margin-bottom:20px">
      <div class="sec-hdr">
        <span class="sec-title">Pending Approvals
          <% if(pendingCount>0){%><span class="badge bg-red" style="margin-left:8px"><%= pendingCount %></span><%}%>
        </span>
      </div>
      <table><thead><tr><th>Name</th><th>Username</th><th>Branch</th><th>Year</th><th>CGPA</th><th>Backlogs</th><th>Action</th></tr></thead><tbody>
<%
  boolean anyP=false;
  try(Connection conn=DBConnection.getConnection();PreparedStatement ps=conn.prepareStatement(
    "SELECT id,full_name,username,branch,year_of_study,cgpa,backlogs FROM users WHERE college_id=? AND role='STUDENT' AND status='PENDING' ORDER BY created_at DESC")){
    ps.setInt(1,collegeId);ResultSet rs=ps.executeQuery();
    while(rs.next()){anyP=true;%>
    <tr>
      <td><strong><%= HtmlUtils.escape(rs.getString("full_name")) %></strong></td>
      <td class="text-muted text-sm"><%= HtmlUtils.escape(rs.getString("username")) %></td>
      <td><span class="badge bg-blue"><%= HtmlUtils.escape(rs.getString("branch")) %></span></td>
      <td><%= HtmlUtils.escape(rs.getString("year_of_study")) %></td>
      <td><%= rs.getDouble("cgpa") %></td>
      <td><%= rs.getInt("backlogs") %></td>
      <td><div class="td-actions">
        <form method="POST" action="college/approveStudent" style="margin:0">
          <input type="hidden" name="studentId" value="<%= rs.getInt("id") %>">
          <input type="hidden" name="action" value="approve">
          <button class="btn-success btn-sm">✓ Approve</button>
        </form>
        <form method="POST" action="college/approveStudent" style="margin:0">
          <input type="hidden" name="studentId" value="<%= rs.getInt("id") %>">
          <input type="hidden" name="action" value="reject">
          <button class="btn-danger btn-sm">✕ Reject</button>
        </form>
      </div></td>
    </tr>
<%  }}catch(Exception e){e.printStackTrace();}
  if(!anyP){%><tr><td colspan="7"><div class="empty-state"><p>No pending student approvals.</p></div></td></tr><%}%>
      </tbody></table>
    </div>

    <%-- ACTIVE STUDENTS --%>
    <div class="section"><div class="sec-hdr"><span class="sec-title">Active Students</span></div>
      <table><thead><tr><th>Name</th><th>Username</th><th>Branch</th><th>Year</th><th>CGPA</th><th>Backlogs</th><th>Drives</th><th>Joined</th></tr></thead><tbody>
<%
  boolean any=false;
  try(Connection conn=DBConnection.getConnection();PreparedStatement ps=conn.prepareStatement(
    "SELECT u.id,u.full_name,u.username,u.branch,u.year_of_study,u.cgpa,u.backlogs,u.created_at," +
    "(SELECT COUNT(*) FROM drive_applications da WHERE da.student_id=u.id) AS drives_applied " +
    "FROM users u WHERE u.college_id=? AND u.role='STUDENT' AND u.status='ACTIVE' ORDER BY u.full_name")){
    ps.setInt(1,collegeId);ResultSet rs=ps.executeQuery();
    while(rs.next()){any=true;%>
    <tr><td><strong><%= HtmlUtils.escape(rs.getString("full_name")) %></strong></td>
      <td class="text-muted text-sm"><%= HtmlUtils.escape(rs.getString("username")) %></td>
      <td><span class="badge bg-blue"><%= HtmlUtils.escape(rs.getString("branch")) %></span></td>
      <td><%= HtmlUtils.escape(rs.getString("year_of_study")) %></td>
      <td><%= rs.getDouble("cgpa") %></td>
      <td><%= rs.getInt("backlogs")==0?"<span class='badge bg-green'>0</span>":"<span class='badge bg-red'>"+rs.getInt("backlogs")+"</span>" %></td>
      <td><%= rs.getInt("drives_applied") %></td>
      <td class="text-sm text-muted"><%= rs.getTimestamp("created_at").toString().substring(0,10) %></td>
    </tr>
<%  }}catch(Exception e){e.printStackTrace();}
  if(!any){%><tr><td colspan="8"><div class="empty-state"><div class="ico">👥</div><p>No active students yet.</p></div></td></tr><%}%>
      </tbody></table></div>
  </div>
</div></body></html>