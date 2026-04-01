<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.testsphere.util.DBConnection,com.testsphere.util.HtmlUtils" %>
<%@ page session="true" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Round Results — TestSphere</title><link rel="stylesheet" href="<%= request.getContextPath() %>/css/main.css"></head><body>
<%
  String user=(String)session.getAttribute("username");String name=(String)session.getAttribute("fullName");
  int uid=Integer.parseInt((String)session.getAttribute("userId"));
  if(user==null||!"RECRUITER".equals(session.getAttribute("role"))){response.sendRedirect("login.jsp");return;}
  String ini=name!=null&&name.length()>=2?name.substring(0,2).toUpperCase():user.substring(0,Math.min(2,user.length())).toUpperCase();
  String roundIdStr=request.getParameter("roundId");String driveIdStr=request.getParameter("driveId");
  if(roundIdStr==null||driveIdStr==null){response.sendRedirect("manage_drives.jsp");return;}
  int roundId=Integer.parseInt(roundIdStr);int driveId=Integer.parseInt(driveIdStr);
  String roundTitle="Round",roundType="GD";
  try(Connection conn=DBConnection.getConnection();PreparedStatement ps=conn.prepareStatement("SELECT title,round_type FROM drive_rounds WHERE id=?")){
    ps.setInt(1,roundId);ResultSet rs=ps.executeQuery();if(rs.next()){roundTitle=rs.getString("title");roundType=rs.getString("round_type");}
  }catch(Exception e){e.printStackTrace();}
  String saved=request.getParameter("saved");
%>
<div class="sidebar"><div class="sb-brand">Test<span>Sphere</span></div>
  <ul class="menu"><li><a href="recruiter_dashboard.jsp"><span class="ico">⊞</span>Dashboard</a></li>
    <li class="active"><a href="manage_drives.jsp"><span class="ico">📋</span>My Drives</a></li></ul>
  <div class="sb-foot"><div class="sb-user"><div class="avatar"><%= HtmlUtils.escape(ini) %></div>
    <div><div class="user-name"><%= HtmlUtils.escape(name!=null?name:user) %></div><div class="user-role-lbl">Recruiter</div></div></div>
    <a href="logout" class="logout-lnk">↩ Sign Out</a></div></div>
<div class="main">
  <div class="topbar"><div><h1><%= HtmlUtils.escape(roundTitle) %></h1><p>Mark pass/fail for each candidate</p></div>
    <div class="topbar-actions"><a href="drive_detail.jsp?driveId=<%= driveId %>" class="btn-secondary">← Back</a></div></div>
  <div class="content">
    <% if("1".equals(saved)){%><div class="alert alert-success">✓ Result saved. Student notified.</div><%}%>
    <div class="section">
      <div class="sec-hdr"><span class="sec-title">Candidates in <%= HtmlUtils.escape(roundTitle) %></span></div>
      <table><thead><tr><th>Candidate</th><th>Branch</th><th>CGPA</th><th>Current Result</th><th>Notes</th><th>Action</th></tr></thead><tbody>
<%
  boolean any=false;
  try(Connection conn=DBConnection.getConnection();PreparedStatement ps=conn.prepareStatement(
    "SELECT u.id AS uid,u.full_name,u.username,u.branch,u.cgpa,da.id AS app_id," +
    "rr.pass_fail,rr.recruiter_notes FROM drive_applications da " +
    "JOIN users u ON da.student_id=u.id " +
    "LEFT JOIN round_results rr ON rr.application_id=da.id AND rr.round_id=? " +
    "WHERE da.drive_id=? AND da.status='ACTIVE' ORDER BY u.full_name")){
    ps.setInt(1,roundId);ps.setInt(2,driveId);ResultSet rs=ps.executeQuery();
    while(rs.next()){any=true;String pf=rs.getString("pass_fail");%>
    <tr>
      <td><strong><%= HtmlUtils.escape(rs.getString("full_name")) %></strong><br>
        <span class="text-sm text-muted"><%= HtmlUtils.escape(rs.getString("username")) %></span></td>
      <td><span class="badge bg-blue"><%= HtmlUtils.escape(rs.getString("branch")) %></span></td>
      <td><%= rs.getDouble("cgpa") %></td>
      <td><% if(pf!=null){%><span class="badge <%= "PASS".equals(pf)?"bg-green":"bg-red" %>"><%= pf %></span>
          <%}else{%><span class="badge bg-gray">Pending</span><%}%></td>
      <td class="text-sm text-muted"><%= pf!=null&&rs.getString("recruiter_notes")!=null?HtmlUtils.escape(rs.getString("recruiter_notes")):"—" %></td>
      <td>
        <button onclick="openMark(<%= rs.getInt("app_id") %>,'<%= HtmlUtils.escape(rs.getString("full_name")) %>')" class="btn-ghost btn-sm">Mark Result</button>
      </td>
    </tr>
<%  }}catch(Exception e){e.printStackTrace();}
  if(!any){%><tr><td colspan="6"><div class="empty-state"><p>No active candidates in this round yet.</p></div></td></tr><%}%>
      </tbody></table></div></div></div>

<div id="mark-modal" class="modal-bg">
  <div class="modal">
    <h3>Mark Result</h3>
    <p id="mark-name" style="margin-bottom:14px;font-weight:500"></p>
    <form method="POST" action="markRoundResult">
      <input type="hidden" name="roundId" value="<%= roundId %>">
      <input type="hidden" name="driveId" value="<%= driveId %>">
      <input type="hidden" name="applicationId" id="mark-app-id">
      <div class="form-group"><label>Result</label>
        <select name="result" required>
          <option value="PASS">PASS — Moves to next round</option>
          <option value="FAIL">FAIL — Eliminated</option>
        </select></div>
      <div class="form-group"><label>Notes (optional)</label>
        <textarea name="notes" rows="2" placeholder="Internal notes about this candidate…"></textarea></div>
      <div class="modal-actions">
        <button type="button" onclick="document.getElementById('mark-modal').classList.remove('open')" class="btn-secondary">Cancel</button>
        <button type="submit" class="btn-primary">Save Result</button>
      </div>
    </form>
  </div>
</div>
<script>
function openMark(appId,name){
  document.getElementById('mark-app-id').value=appId;
  document.getElementById('mark-name').textContent=name;
  document.getElementById('mark-modal').classList.add('open');
}
document.getElementById('mark-modal').addEventListener('click',function(e){if(e.target===this)this.classList.remove('open')});
</script>
</body></html>
