<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.testsphere.util.DBConnection,com.testsphere.util.HtmlUtils" %>
<%@ page session="true" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Student Dashboard — TestSphere</title><link rel="stylesheet" href="<%= request.getContextPath() %>/css/main.css"></head>
<body style="background:var(--bg);padding:0">
<%
  response.setHeader("Cache-Control","no-cache,no-store,must-revalidate");
  response.setHeader("Pragma","no-cache");response.setDateHeader("Expires",0);
  String user=(String)session.getAttribute("username");String name=(String)session.getAttribute("fullName");
  int uid=Integer.parseInt((String)session.getAttribute("userId"));
  if(user==null||!"STUDENT".equals(session.getAttribute("role"))){response.sendRedirect("login.jsp");return;}
  String ini=name!=null&&name.length()>=2?name.substring(0,2).toUpperCase():user.substring(0,Math.min(2,user.length())).toUpperCase();
  // Unread notification count
  int unread=0;
  try(Connection conn=DBConnection.getConnection();PreparedStatement ps=conn.prepareStatement("SELECT COUNT(*) FROM notifications WHERE user_id=? AND is_read=0")){
    ps.setInt(1,uid);ResultSet rs=ps.executeQuery();if(rs.next())unread=rs.getInt(1);
  }catch(Exception e){e.printStackTrace();}
  String joined=request.getParameter("joined");
  String submitted=request.getParameter("submitted");
  String errParam=request.getParameter("error");
%>
<div class="sidebar"><div class="sb-brand">Test<span>Sphere</span></div>
  <ul class="menu">
    <li class="active"><a href="student_dashboard.jsp"><span class="ico">⊞</span>Dashboard</a></li>
    <li><a href="my_applications.jsp"><span class="ico">📋</span>My Applications</a></li>
    <li><a href="student_notifications.jsp"><span class="ico">🔔</span>Notifications<% if(unread>0){%><span class="notif-dot"></span><%}%></a></li>
  </ul>
  <div class="sb-foot"><div class="sb-user"><div class="avatar"><%= HtmlUtils.escape(ini) %></div>
    <div><div class="user-name"><%= HtmlUtils.escape(name!=null?name:user) %></div><div class="user-role-lbl">Student</div></div></div>
    <a href="logout" class="logout-lnk">↩ Sign Out</a></div></div>
<div class="main">
  <div class="topbar"><div><h1>Dashboard</h1><p>Welcome, <%= HtmlUtils.escape(name!=null?name:user) %></p></div></div>
  <div class="content">
    <% if("1".equals(joined)){%><div class="alert alert-success">✓ Successfully registered for the drive!</div><%}%>
    <% if("1".equals(submitted)){%><div class="alert alert-info">✓ Test submitted. Results will be announced after the test window closes.</div><%}%>
    <% if("wrong_college".equals(errParam)){%><div class="alert alert-error">This drive is not for your college.</div><%}%>
    <% if("not_eligible_year".equals(errParam)||"not_eligible_cgpa".equals(errParam)||"not_eligible_branch".equals(errParam)||"not_eligible_backlogs".equals(errParam)){%>
      <div class="alert alert-error">You do not meet the eligibility criteria for this drive.</div><%}%>
    <% if("already_applied".equals(errParam)){%><div class="alert alert-info">You are already registered for this drive.</div><%}%>
    <% if("deadline_passed".equals(errParam)){%><div class="alert alert-error">Registration deadline has passed for this drive.</div><%}%>
    <% if("drive_closed".equals(errParam)){%><div class="alert alert-error">This drive is closed.</div><%}%>
    <% if("already_submitted".equals(errParam)){%><div class="alert alert-info">You have already submitted this test.</div><%}%>
    <% if("window_closed".equals(errParam)){%><div class="alert alert-error">The test window has closed.</div><%}%>
    <% if("not_shortlisted".equals(errParam)){%><div class="alert alert-warn">You need to be shortlisted by the recruiter before you can attempt this test.</div><%}%>

    <%-- ACTIVE DRIVES with pending aptitude --%>
    <div class="section" style="margin-bottom:20px">
      <div class="sec-hdr"><span class="sec-title">Tests Ready to Attempt</span></div>
      <table><thead><tr><th>Drive</th><th>Company</th><th>Round</th><th>Closes</th><th></th></tr></thead><tbody>
<%
  boolean anyTest=false;
  try(Connection conn=DBConnection.getConnection();PreparedStatement ps=conn.prepareStatement(
    "SELECT da.id AS app_id,d.title,u2.company_name,dr.id AS round_id,dr.title AS rtitle,dr.end_time " +
    "FROM drive_applications da " +
    "JOIN drives d ON da.drive_id=d.id " +
    "JOIN users u2 ON d.recruiter_id=u2.id " +
    "JOIN drive_rounds dr ON dr.drive_id=d.id AND dr.round_type='APTITUDE' AND dr.status!='COMPLETED' " +
    "WHERE da.student_id=? AND da.status='ACTIVE' AND da.recruiter_status='SHORTLISTED' " +
    "AND NOW() BETWEEN dr.start_time AND dr.end_time " +
    "AND NOT EXISTS (SELECT 1 FROM round_results rr WHERE rr.application_id=da.id AND rr.round_id=dr.id AND rr.submitted_at IS NOT NULL)")){
    ps.setInt(1,uid);ResultSet rs=ps.executeQuery();
    while(rs.next()){anyTest=true;%>
    <tr>
      <td><strong><%= HtmlUtils.escape(rs.getString("title")) %></strong></td>
      <td><%= HtmlUtils.escape(rs.getString("company_name")) %></td>
      <td><span class="badge bg-blue"><%= HtmlUtils.escape(rs.getString("rtitle")) %></span></td>
      <td class="text-sm text-muted"><%= rs.getString("end_time")!=null?rs.getString("end_time").substring(0,16):"—" %></td>
      <td><a href="attempt_round.jsp?roundId=<%= rs.getInt("round_id") %>&appId=<%= rs.getInt("app_id") %>" class="btn-primary btn-sm">Start →</a></td>
    </tr>
<%  }}catch(Exception e){e.printStackTrace();}
  if(!anyTest){%><tr><td colspan="5"><div class="empty-state"><div class="ico">✅</div><p>No tests available right now. Check notifications for updates.</p></div></td></tr><%}%>
      </tbody></table></div>

    <%-- RECENT NOTIFICATIONS --%>
    <div class="section">
      <div class="sec-hdr"><span class="sec-title">Recent Notifications</span>
        <a href="student_notifications.jsp" class="btn-ghost">View all →</a></div>
      <table><thead><tr><th>Message</th><th>When</th></tr></thead><tbody>
<%
  boolean anyNotif=false;
  try(Connection conn=DBConnection.getConnection();PreparedStatement ps=conn.prepareStatement(
    "SELECT title,message,created_at,is_read FROM notifications WHERE user_id=? ORDER BY created_at DESC LIMIT 5")){
    ps.setInt(1,uid);ResultSet rs=ps.executeQuery();
    while(rs.next()){anyNotif=true;boolean read=rs.getInt("is_read")==1;%>
    <tr style="<%= !read?"font-weight:500":"" %>">
      <td><div style="font-size:13.5px"><%= HtmlUtils.escape(rs.getString("title")) %></div>
        <div class="text-sm text-muted"><%= HtmlUtils.escape(rs.getString("message")) %></div></td>
      <td class="text-sm text-muted" style="white-space:nowrap"><%= rs.getTimestamp("created_at").toString().substring(0,16) %></td>
    </tr>
<%  }}catch(Exception e){e.printStackTrace();}
  // Mark all as read after viewing
  try(Connection conn=DBConnection.getConnection();PreparedStatement ps=conn.prepareStatement("UPDATE notifications SET is_read=1 WHERE user_id=?")){
    ps.setInt(1,uid);ps.executeUpdate();
  }catch(Exception e){e.printStackTrace();}
  if(!anyNotif){%><tr><td colspan="2"><div class="empty-state" style="padding:24px"><p>No notifications yet.</p></div></td></tr><%}%>
      </tbody></table></div>
  </div>
</div></body></html>
