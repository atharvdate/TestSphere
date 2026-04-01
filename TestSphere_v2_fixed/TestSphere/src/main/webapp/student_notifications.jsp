<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.testsphere.util.DBConnection,com.testsphere.util.HtmlUtils" %>
<%@ page session="true" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Notifications — TestSphere</title><link rel="stylesheet" href="<%= request.getContextPath() %>/css/main.css"></head><body>
<%
  String user=(String)session.getAttribute("username");String name=(String)session.getAttribute("fullName");
  int uid=Integer.parseInt((String)session.getAttribute("userId"));
  if(user==null||!"STUDENT".equals(session.getAttribute("role"))){response.sendRedirect("login.jsp");return;}
  String ini=name!=null&&name.length()>=2?name.substring(0,2).toUpperCase():user.substring(0,Math.min(2,user.length())).toUpperCase();
  // Mark all as read when this page is opened
  try(Connection conn=DBConnection.getConnection();
      PreparedStatement ps=conn.prepareStatement("UPDATE notifications SET is_read=1 WHERE user_id=?")){
    ps.setInt(1,uid);ps.executeUpdate();
  }catch(Exception e){e.printStackTrace();}
%>
<div class="sidebar"><div class="sb-brand">Test<span>Sphere</span></div>
  <ul class="menu">
    <li><a href="student_dashboard.jsp"><span class="ico">⊞</span>Dashboard</a></li>
    <li><a href="my_applications.jsp"><span class="ico">📋</span>My Applications</a></li>
    <li class="active"><a href="student_notifications.jsp"><span class="ico">🔔</span>Notifications</a></li>
  </ul>
  <div class="sb-foot"><div class="sb-user"><div class="avatar"><%= HtmlUtils.escape(ini) %></div>
    <div><div class="user-name"><%= HtmlUtils.escape(name!=null?name:user) %></div><div class="user-role-lbl">Student</div></div></div>
    <a href="logout" class="logout-lnk">↩ Sign Out</a></div></div>
<div class="main">
  <div class="topbar"><div><h1>Notifications</h1><p>All updates about your drives and rounds</p></div></div>
  <div class="content">
    <div class="section">
      <div class="sec-hdr"><span class="sec-title">All Notifications</span></div>
      <div>
<%
  boolean any=false;
  try(Connection conn=DBConnection.getConnection();
      PreparedStatement ps=conn.prepareStatement(
        "SELECT title,message,is_read,created_at FROM notifications WHERE user_id=? ORDER BY created_at DESC")){
    ps.setInt(1,uid);ResultSet rs=ps.executeQuery();
    while(rs.next()){any=true;
      boolean isPass=rs.getString("message").toLowerCase().contains("congratulations")||rs.getString("message").toLowerCase().contains("qualified")||rs.getString("message").toLowerCase().contains("registered");
      boolean isFail=rs.getString("message").toLowerCase().contains("not qualified")||rs.getString("message").toLowerCase().contains("not taken forward");
%>
        <div style="padding:16px 20px;border-bottom:1px solid #f5f5f7;display:flex;align-items:flex-start;gap:14px">
          <div style="width:36px;height:36px;border-radius:50%;flex-shrink:0;
            background:<%= isPass?"#e8f8ef":isFail?"#fff2f2":"#e8f0fd" %>;
            display:flex;align-items:center;justify-content:center;font-size:16px">
            <%= isPass?"✓":isFail?"✕":"ℹ" %>
          </div>
          <div style="flex:1">
            <div style="font-size:14px;font-weight:600;color:#1d1d1f;margin-bottom:3px">
              <%= HtmlUtils.escape(rs.getString("title")) %>
            </div>
            <div style="font-size:13.5px;color:#6e6e73;line-height:1.5">
              <%= HtmlUtils.escape(rs.getString("message")) %>
            </div>
            <div style="font-size:12px;color:#aeaeb2;margin-top:5px">
              <%= rs.getTimestamp("created_at").toString().substring(0,16) %>
            </div>
          </div>
        </div>
<%  }}catch(Exception e){e.printStackTrace();}
  if(!any){%>
        <div class="empty-state" style="padding:48px">
          <div class="ico">🔔</div>
          <p>No notifications yet. Join a placement drive to get started.</p>
        </div>
<%  }%>
      </div>
    </div>
  </div>
</div></body></html>
