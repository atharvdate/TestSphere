<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.testsphere.util.DBConnection,com.testsphere.util.HtmlUtils" %>
<%@ page session="true" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Add Questions — TestSphere</title><link rel="stylesheet" href="<%= request.getContextPath() %>/css/main.css"></head><body>
<%
  String user=(String)session.getAttribute("username");String name=(String)session.getAttribute("fullName");
  int uid=Integer.parseInt((String)session.getAttribute("userId"));
  if(user==null||!"RECRUITER".equals(session.getAttribute("role"))){response.sendRedirect("login.jsp");return;}
  String ini=name!=null&&name.length()>=2?name.substring(0,2).toUpperCase():user.substring(0,Math.min(2,user.length())).toUpperCase();
  String roundIdStr=request.getParameter("roundId");String driveIdStr=request.getParameter("driveId");
  if(roundIdStr==null||driveIdStr==null){response.sendRedirect("manage_drives.jsp");return;}
  int roundId=Integer.parseInt(roundIdStr);int driveId=Integer.parseInt(driveIdStr);
  String roundTitle="Round";int qcount=0;
  try(Connection conn=DBConnection.getConnection()){
    try(PreparedStatement ps=conn.prepareStatement("SELECT title FROM drive_rounds WHERE id=?")){ps.setInt(1,roundId);ResultSet rs=ps.executeQuery();if(rs.next())roundTitle=rs.getString("title");}
    try(PreparedStatement ps=conn.prepareStatement("SELECT COUNT(*) FROM questions WHERE round_id=?")){ps.setInt(1,roundId);ResultSet rs=ps.executeQuery();if(rs.next())qcount=rs.getInt(1);}
  }catch(Exception e){e.printStackTrace();}
  String added=request.getParameter("added");String errParam=request.getParameter("error");
  String errMsg=null;if("missing".equals(errParam))errMsg="All fields required.";
  else if("invalid_option".equals(errParam))errMsg="Correct option must be A, B, C or D.";
%>
<div class="sidebar"><div class="sb-brand">Test<span>Sphere</span></div>
  <ul class="menu"><li><a href="recruiter_dashboard.jsp"><span class="ico">⊞</span>Dashboard</a></li>
    <li class="active"><a href="manage_drives.jsp"><span class="ico">📋</span>My Drives</a></li>
    <li><a href="create_drive.jsp"><span class="ico">＋</span>Create Drive</a></li></ul>
  <div class="sb-foot"><div class="sb-user"><div class="avatar"><%= HtmlUtils.escape(ini) %></div>
    <div><div class="user-name"><%= HtmlUtils.escape(name!=null?name:user) %></div><div class="user-role-lbl">Recruiter</div></div></div>
    <a href="logout" class="logout-lnk">↩ Sign Out</a></div></div>
<div class="main">
  <div class="topbar"><div><h1>Add Questions</h1><p><%= HtmlUtils.escape(roundTitle) %> &mdash; <%= qcount %> question<%= qcount!=1?"s":"" %> added</p></div>
    <div class="topbar-actions"><a href="drive_detail.jsp?driveId=<%= driveId %>" class="btn-secondary">← Back to Drive</a></div></div>
  <div class="content">
    <% if("1".equals(added)){%><div class="alert alert-success">✓ Question added. Add another or go back.</div><%}%>
    <% if(errMsg!=null){%><div class="alert alert-error"><%= HtmlUtils.escape(errMsg) %></div><%}%>
    <div class="form-card">
      <form action="addQuestion" method="post">
        <input type="hidden" name="roundId" value="<%= HtmlUtils.escape(roundIdStr) %>">
        <input type="hidden" name="driveId" value="<%= HtmlUtils.escape(driveIdStr) %>">
        <div class="form-group"><label>Question <span class="req">*</span></label>
          <textarea name="question" rows="3" placeholder="Enter question text…" required></textarea></div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px">
          <div class="form-group"><label>Option A <span class="req">*</span></label><input type="text" name="optionA" placeholder="Option A" required></div>
          <div class="form-group"><label>Option B <span class="req">*</span></label><input type="text" name="optionB" placeholder="Option B" required></div>
          <div class="form-group"><label>Option C <span class="req">*</span></label><input type="text" name="optionC" placeholder="Option C" required></div>
          <div class="form-group"><label>Option D <span class="req">*</span></label><input type="text" name="optionD" placeholder="Option D" required></div>
        </div>
        <div class="form-group" style="max-width:200px"><label>Correct Answer <span class="req">*</span></label>
          <select name="correctOption" required>
            <option value="" disabled selected hidden>Select</option>
            <option>A</option><option>B</option><option>C</option><option>D</option>
          </select></div>
        <button type="submit" class="btn-primary">Add Question</button>
      </form>
    </div>
    <% if(qcount>0){%>
    <div class="section" style="margin-top:20px">
      <div class="sec-hdr"><span class="sec-title">Questions in this round</span>
        <span class="badge bg-blue"><%= qcount %> total</span></div>
      <table><thead><tr><th>#</th><th>Question</th><th>A</th><th>B</th><th>C</th><th>D</th><th>Answer</th></tr></thead><tbody>
<%  int qno=1;
    try(Connection conn=DBConnection.getConnection();PreparedStatement ps=conn.prepareStatement("SELECT * FROM questions WHERE round_id=? ORDER BY id")){
      ps.setInt(1,roundId);ResultSet rs=ps.executeQuery();
      while(rs.next()){%>
      <tr><td class="text-sm text-muted"><%= qno++ %></td>
        <td style="max-width:260px"><%= HtmlUtils.escape(rs.getString("question_text")) %></td>
        <td class="text-sm"><%= HtmlUtils.escape(rs.getString("option_a")) %></td>
        <td class="text-sm"><%= HtmlUtils.escape(rs.getString("option_b")) %></td>
        <td class="text-sm"><%= HtmlUtils.escape(rs.getString("option_c")) %></td>
        <td class="text-sm"><%= HtmlUtils.escape(rs.getString("option_d")) %></td>
        <td><span class="badge bg-green"><%= HtmlUtils.escape(rs.getString("correct_option")) %></span></td>
      </tr>
<%    }}catch(Exception e){e.printStackTrace();}%>
      </tbody></table></div>
    <%}%>
  </div>
</div></body></html>
