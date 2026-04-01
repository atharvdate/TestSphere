<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.testsphere.util.DBConnection,com.testsphere.util.HtmlUtils" %>
<%@ page session="true" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>My Applications — TestSphere</title><link rel="stylesheet" href="<%= request.getContextPath() %>/css/main.css"></head><body>
<%
  String user=(String)session.getAttribute("username");String name=(String)session.getAttribute("fullName");
  int uid=Integer.parseInt((String)session.getAttribute("userId"));
  if(user==null||!"STUDENT".equals(session.getAttribute("role"))){response.sendRedirect("login.jsp");return;}
  String ini=name!=null&&name.length()>=2?name.substring(0,2).toUpperCase():user.substring(0,Math.min(2,user.length())).toUpperCase();
  int unread=0;
  try(Connection conn=DBConnection.getConnection();PreparedStatement ps=conn.prepareStatement("SELECT COUNT(*) FROM notifications WHERE user_id=? AND is_read=0")){
    ps.setInt(1,uid);ResultSet rs=ps.executeQuery();if(rs.next())unread=rs.getInt(1);
  }catch(Exception e){e.printStackTrace();}
%>
<div class="sidebar"><div class="sb-brand">Test<span>Sphere</span></div>
  <ul class="menu">
    <li><a href="student_dashboard.jsp"><span class="ico">⊞</span>Dashboard</a></li>
    <li class="active"><a href="my_applications.jsp"><span class="ico">📋</span>My Applications</a></li>
    <li><a href="student_notifications.jsp"><span class="ico">🔔</span>Notifications<% if(unread>0){%><span class="notif-dot"></span><%}%></a></li>
  </ul>
  <div class="sb-foot"><div class="sb-user"><div class="avatar"><%= HtmlUtils.escape(ini) %></div>
    <div><div class="user-name"><%= HtmlUtils.escape(name!=null?name:user) %></div><div class="user-role-lbl">Student</div></div></div>
    <a href="logout" class="logout-lnk">↩ Sign Out</a></div></div>
<div class="main">
  <div class="topbar"><div><h1>My Applications</h1><p>Track your placement drive progress</p></div></div>
  <div class="content">
<%
  try(Connection conn=DBConnection.getConnection();PreparedStatement ps=conn.prepareStatement(
    "SELECT d.id AS did,d.title,d.job_role,d.package_lpa,u.company_name,c.name AS college," +
    "da.id AS app_id,da.status AS app_status,da.recruiter_status,da.ai_score,da.applied_at," +
    "(SELECT COUNT(*) FROM drive_rounds WHERE drive_id=d.id) AS total_rounds " +
    "FROM drive_applications da " +
    "JOIN drives d ON da.drive_id=d.id " +
    "JOIN users u ON d.recruiter_id=u.id " +
    "JOIN colleges c ON d.college_id=c.id " +
    "WHERE da.student_id=? ORDER BY da.applied_at DESC")){
    ps.setInt(1,uid);ResultSet rs=ps.executeQuery();
    boolean any=false;
    while(rs.next()){any=true;
      String ast=rs.getString("app_status");
      int appId=rs.getInt("app_id");int driveId=rs.getInt("did");
%>
    <div class="section" style="margin-bottom:18px">
      <div class="sec-hdr">
        <div>
          <div style="font-size:15px;font-weight:600"><%= HtmlUtils.escape(rs.getString("title")) %></div>
          <div class="text-sm text-muted"><%= HtmlUtils.escape(rs.getString("company_name")) %> &nbsp;·&nbsp;
            <%= HtmlUtils.escape(rs.getString("job_role")) %>
            <% if(rs.getString("package_lpa")!=null&&!rs.getString("package_lpa").isEmpty()){%>
              &nbsp;·&nbsp; <%= HtmlUtils.escape(rs.getString("package_lpa")) %>
            <%}%>
          </div>
        </div>
        <%
          String rst2=rs.getString("recruiter_status");
          int ais=rs.getInt("ai_score"); boolean hasAis=!rs.wasNull();
        %>
        <div style="display:flex;flex-direction:column;align-items:flex-end;gap:4px">
          <span class="badge <%= "ACTIVE".equals(ast)?"bg-green":"ELIMINATED".equals(ast)?"bg-red":"bg-blue" %>">
            <%= "ACTIVE".equals(ast)?"In Progress":"ELIMINATED".equals(ast)?"Eliminated":"Selected" %>
          </span>
          <% if("PENDING".equals(rst2)){%>
            <span class="badge bg-orange" style="font-size:10px">Resume under review</span>
          <%} else if("SHORTLISTED".equals(rst2)){%>
            <span class="badge bg-green" style="font-size:10px">✓ Shortlisted</span>
          <%} else if("REJECTED".equals(rst2)){%>
            <span class="badge bg-red" style="font-size:10px">Not selected</span>
          <%}%>
          <% if(hasAis){%>
            <span style="font-size:11px;color:var(--muted)">AI match: <%= ais %>%</span>
          <%}%>
        </div>
      </div>
      <%-- Pipeline progress --%>
      <div style="padding:16px 20px">
        <div class="pipeline-steps">
<%
      try(PreparedStatement rp=conn.prepareStatement(
        "SELECT dr.id,dr.round_number,dr.round_type,dr.title,dr.status AS rstatus,dr.result_released," +
        "rr.pass_fail,rr.submitted_at " +
        "FROM drive_rounds dr " +
        "LEFT JOIN round_results rr ON rr.round_id=dr.id AND rr.application_id=? " +
        "WHERE dr.drive_id=? ORDER BY dr.round_number")){
        rp.setInt(1,appId);rp.setInt(2,driveId);ResultSet rrs=rp.executeQuery();
        boolean firstNode=true;
        while(rrs.next()){
          String pf=rrs.getString("pass_fail");
          boolean released=rrs.getInt("result_released")==1;
          boolean submitted=rrs.getTimestamp("submitted_at")!=null;
          String nodeClass="";
          String label=rrs.getString("title");
          if(pf!=null&&released){
            nodeClass="PASS".equals(pf)?"done":"fail";
            label+=" (" + ("PASS".equals(pf) ? "✓" : "✕") + ")";
          } else if(submitted){
            nodeClass="active";label+=" (Submitted)";
          }
          if(!firstNode){%><div class="pipe-arrow"></div><%}firstNode=false;%>
          <div class="pipe-step"><div class="pipe-node <%= nodeClass %>"><%= HtmlUtils.escape(label) %></div></div>
<%      }}catch(Exception e){e.printStackTrace();}%>
        </div>
        <div class="text-sm text-muted" style="margin-top:10px">Applied: <%= rs.getTimestamp("applied_at").toString().substring(0,10) %></div>
      </div>

      <%-- Round results detail --%>
      <table style="border-top:1px solid #f5f5f7"><thead>
        <tr><th>Round</th><th>Type</th><th>Your Status</th><th>Score</th></tr>
      </thead><tbody>
<%
      try(PreparedStatement rp=conn.prepareStatement(
        "SELECT dr.title,dr.round_type,dr.result_released,rr.pass_fail,rr.score,rr.total_questions,rr.submitted_at " +
        "FROM drive_rounds dr " +
        "LEFT JOIN round_results rr ON rr.round_id=dr.id AND rr.application_id=? " +
        "WHERE dr.drive_id=? ORDER BY dr.round_number")){
        rp.setInt(1,appId);rp.setInt(2,driveId);ResultSet rrs=rp.executeQuery();
        while(rrs.next()){
          String pf=rrs.getString("pass_fail");
          boolean released=rrs.getInt("result_released")==1;
          boolean submitted=rrs.getTimestamp("submitted_at")!=null;
          int sc=rrs.getInt("score"),tot=rrs.getInt("total_questions");
          int pct=tot>0?(sc*100/tot):0;%>
        <tr>
          <td><strong><%= HtmlUtils.escape(rrs.getString("title")) %></strong></td>
          <td><span class="badge <%= "APTITUDE".equals(rrs.getString("round_type"))?"bg-blue":"bg-orange" %>"><%= rrs.getString("round_type") %></span></td>
          <td>
            <% boolean isAptitude="APTITUDE".equals(rrs.getString("round_type")); %>
            <% if(!submitted && !isAptitude){%><span class="badge bg-gray">Pending</span>
            <%}else if(!submitted){%><span class="badge bg-gray">Not Attempted</span>
            <%}else if(pf!=null && (released || !isAptitude)){%><span class="badge <%= "PASS".equals(pf)?"bg-green":"bg-red" %>"><%= pf %></span>
            <%}else if(!released && isAptitude){%><span class="badge bg-orange">Awaiting Results</span>
            <%}else{%><span class="badge bg-gray">—</span><%}%>
          </td>
          <td>
            <% if(submitted && "APTITUDE".equals(rrs.getString("round_type")) && released){%>
              <span class="score-pill <%= "PASS".equals(pf)?"pass":"fail" %>"><%= sc %>/<%= tot %> (<%= pct %>%)</span>
            <%}else{%><span class="text-muted text-sm">—</span><%}%>
          </td>
        </tr>
<%      }}catch(Exception e){e.printStackTrace();}%>
      </tbody></table>
    </div>
<%  }
    if(!any){%>
    <div class="section"><div class="empty-state" style="padding:48px">
      <div class="ico">📋</div>
      <p>No applications yet. Use an invite link from your college to register for a placement drive.</p>
    </div></div>
<%  }
  }catch(Exception e){e.printStackTrace();}%>
  </div>
</div></body></html>
