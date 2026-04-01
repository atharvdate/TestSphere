<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.testsphere.util.DBConnection" %>
<%@ page import="com.testsphere.util.HtmlUtils" %>
<%@ page session="true" %>
<!DOCTYPE html><html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Admin — TestSphere</title>
<link rel="stylesheet" href="css/main.css"></head>
<body>
<%
  String user=(String)session.getAttribute("username");
  if(user==null||!"ADMIN".equals(session.getAttribute("role"))){response.sendRedirect("login.jsp");return;}
  String action=request.getParameter("action");
  int pendingR=0,pendingC=0,totalUsers=0,totalDrives=0;
  try(Connection conn=DBConnection.getConnection()){
    try(PreparedStatement ps=conn.prepareStatement("SELECT COUNT(*) FROM users WHERE role='RECRUITER' AND status='PENDING'")){ResultSet rs=ps.executeQuery();if(rs.next())pendingR=rs.getInt(1);}
    try(PreparedStatement ps=conn.prepareStatement("SELECT COUNT(*) FROM users WHERE role='COLLEGE_ADMIN' AND status='PENDING'")){ResultSet rs=ps.executeQuery();if(rs.next())pendingC=rs.getInt(1);}
    try(PreparedStatement ps=conn.prepareStatement("SELECT COUNT(*) FROM users WHERE role!='ADMIN'")){ResultSet rs=ps.executeQuery();if(rs.next())totalUsers=rs.getInt(1);}
    try(PreparedStatement ps=conn.prepareStatement("SELECT COUNT(*) FROM drives")){ResultSet rs=ps.executeQuery();if(rs.next())totalDrives=rs.getInt(1);}
  }catch(Exception e){e.printStackTrace();}
  String colorR = pendingR > 0 ? "#c0392b" : "#1e7e34";
  String colorC = pendingC > 0 ? "#c0392b" : "#1e7e34";
%>
<div class="sidebar">
  <div class="sb-brand">Test<span>Sphere</span></div>
  <ul class="menu">
    <li class="active"><a href="admin_dashboard.jsp"><span class="ico">⊞</span>Dashboard</a></li>
    <li><a href="admin_dashboard.jsp#recruiters"><span class="ico">🏢</span>Recruiters</a></li>
    <li><a href="admin_dashboard.jsp#colleges"><span class="ico">🎓</span>Colleges</a></li>
    <li><a href="admin_dashboard.jsp#users"><span class="ico">👥</span>All Users</a></li>
  </ul>
  <div class="sb-foot">
    <div class="sb-user"><div class="avatar">AD</div>
      <div><div class="user-name"><%= HtmlUtils.escape(user) %></div>
      <div class="user-role-lbl">Super Admin</div></div>
    </div>
    <a href="logout" class="logout-lnk">↩ Sign Out</a>
  </div>
</div>

<div class="main">
  <div class="topbar">
    <div><h1>Admin Dashboard</h1><p>System management & approvals</p></div>
  </div>
  <div class="content">
    <% if("approve".equals(action)){%><div class="alert alert-success">✓ Account approved.</div><%}%>
    <% if("reject".equals(action)){%><div class="alert alert-error">Account rejected.</div><%}%>
    <% if("deactivated".equals(action)){%><div class="alert alert-warn">User deactivated.</div><%}%>

    <div class="stats-grid">
      <div class="stat-card"><div class="stat-lbl">Pending Recruiters</div>
        <div class="stat-val" style="color:<%= colorR %>"><%= pendingR %></div>
        <div class="stat-sub">Awaiting approval</div></div>
      <div class="stat-card"><div class="stat-lbl">Pending Colleges</div>
        <div class="stat-val" style="color:<%= colorC %>"><%= pendingC %></div>
        <div class="stat-sub">Awaiting approval</div></div>
      <div class="stat-card"><div class="stat-lbl">Total Users</div>
        <div class="stat-val"><%= totalUsers %></div><div class="stat-sub">All roles</div></div>
      <div class="stat-card"><div class="stat-lbl">Total Drives</div>
        <div class="stat-val"><%= totalDrives %></div><div class="stat-sub">All companies</div></div>
    </div>

    <%-- PENDING RECRUITERS --%>
    <div class="section" id="recruiters">
      <div class="sec-hdr"><span class="sec-title">Pending Recruiter Approvals
        <% if(pendingR>0){%><span class="badge bg-red" style="margin-left:8px"><%= pendingR %></span><%}%>
      </span></div>
      <table><thead><tr><th>Name</th><th>Username</th><th>Company</th><th>Official Email</th><th>Website</th><th>Action</th></tr></thead><tbody>
<%
  boolean anyR=false;
  try(Connection conn=DBConnection.getConnection();
      PreparedStatement ps=conn.prepareStatement("SELECT id,full_name,username,company_name,official_email,company_website FROM users WHERE role='RECRUITER' AND status='PENDING' ORDER BY id DESC")){
    ResultSet rs=ps.executeQuery();
    while(rs.next()){anyR=true;%>
      <tr>
        <td><strong><%= HtmlUtils.escape(rs.getString("full_name")) %></strong></td>
        <td><%= HtmlUtils.escape(rs.getString("username")) %></td>
        <td><%= HtmlUtils.escape(rs.getString("company_name")) %></td>
        <td><%= HtmlUtils.escape(rs.getString("official_email")) %></td>
        <td><a href="<%= HtmlUtils.escape(rs.getString("company_website")) %>" target="_blank" class="btn-ghost btn-sm">Visit ↗</a></td>
        <td><div class="td-actions">
          <form method="POST" action="admin/approve_recruiter" style="margin:0">
            <input type="hidden" name="userId" value="<%= rs.getInt("id") %>">
            <input type="hidden" name="type" value="recruiter">
            <input type="hidden" name="action" value="approve">
            <button class="btn-success btn-sm">✓ Approve</button>
          </form>
          <form method="POST" action="admin/approve_recruiter" style="margin:0">
            <input type="hidden" name="userId" value="<%= rs.getInt("id") %>">
            <input type="hidden" name="type" value="recruiter">
            <input type="hidden" name="action" value="reject">
            <button class="btn-danger btn-sm">✕ Reject</button>
          </form>
        </div></td>
      </tr>
<%  }}catch(Exception e){e.printStackTrace();}
  if(!anyR){%><tr><td colspan="6"><div class="empty-state"><p>No pending recruiter approvals.</p></div></td></tr><%}%>
      </tbody></table>
    </div>

    <%-- PENDING COLLEGES --%>
    <div class="section" id="colleges">
      <div class="sec-hdr"><span class="sec-title">Pending College Approvals
        <% if(pendingC>0){%><span class="badge bg-red" style="margin-left:8px"><%= pendingC %></span><%}%>
      </span></div>
      <table><thead><tr><th>Coordinator</th><th>College Name</th><th>City</th><th>Code</th><th>Email</th><th>Action</th></tr></thead><tbody>
<%
  boolean anyC=false;
  try(Connection conn=DBConnection.getConnection();
      PreparedStatement ps=conn.prepareStatement(
        "SELECT u.id,u.full_name,u.email,c.name AS cname,c.city,c.college_code FROM users u JOIN colleges c ON u.college_id=c.id WHERE u.role='COLLEGE_ADMIN' AND u.status='PENDING' ORDER BY u.id DESC")){
    ResultSet rs=ps.executeQuery();
    while(rs.next()){anyC=true;%>
      <tr>
        <td><strong><%= HtmlUtils.escape(rs.getString("full_name")) %></strong></td>
        <td><%= HtmlUtils.escape(rs.getString("cname")) %></td>
        <td><%= HtmlUtils.escape(rs.getString("city")) %></td>
        <td><span class="badge bg-blue"><%= HtmlUtils.escape(rs.getString("college_code")) %></span></td>
        <td><%= HtmlUtils.escape(rs.getString("email")) %></td>
        <td><div class="td-actions">
          <form method="POST" action="admin/approve_recruiter" style="margin:0">
            <input type="hidden" name="userId" value="<%= rs.getInt("id") %>">
            <input type="hidden" name="type" value="college">
            <input type="hidden" name="action" value="approve">
            <button class="btn-success btn-sm">✓ Approve</button>
          </form>
          <form method="POST" action="admin/approve_recruiter" style="margin:0">
            <input type="hidden" name="userId" value="<%= rs.getInt("id") %>">
            <input type="hidden" name="type" value="college">
            <input type="hidden" name="action" value="reject">
            <button class="btn-danger btn-sm">✕ Reject</button>
          </form>
        </div></td>
      </tr>
<%  }}catch(Exception e){e.printStackTrace();}
  if(!anyC){%><tr><td colspan="6"><div class="empty-state"><p>No pending college approvals.</p></div></td></tr><%}%>
      </tbody></table>
    </div>

    <%-- ALL USERS --%>
    <div class="section" id="users">
      <div class="sec-hdr"><span class="sec-title">All Users</span></div>
      <table><thead><tr><th>Name</th><th>Username</th><th>Role</th><th>Status</th><th>Joined</th><th>Action</th></tr></thead><tbody>
<%
  try(Connection conn=DBConnection.getConnection();
      PreparedStatement ps=conn.prepareStatement("SELECT id,full_name,username,role,status,created_at FROM users WHERE role!='ADMIN' ORDER BY created_at DESC LIMIT 100")){
    ResultSet rs=ps.executeQuery();
    while(rs.next()){
      String st=rs.getString("status");
      String rl=rs.getString("role");%>
      <tr>
        <td><strong><%= HtmlUtils.escape(rs.getString("full_name")) %></strong></td>
        <td><%= HtmlUtils.escape(rs.getString("username")) %></td>
        <td><span class="badge <%= "RECRUITER".equals(rl)?"bg-purple":"STUDENT".equals(rl)?"bg-blue":"bg-orange" %>"><%= rl %></span></td>
        <td><span class="badge <%= "ACTIVE".equals(st)?"bg-green":"PENDING".equals(st)?"bg-orange":"bg-red" %>"><%= st %></span></td>
        <td class="text-sm text-muted"><%= rs.getTimestamp("created_at").toString().substring(0,10) %></td>
        <td><% if("ACTIVE".equals(st)){%>
          <form method="POST" action="admin/deactivate" style="margin:0">
            <input type="hidden" name="userId" value="<%= rs.getInt("id") %>">
            <button class="btn-danger btn-sm">Deactivate</button>
          </form>
        <%}else{%><span class="text-muted text-sm"><%= st %></span><%}%></td>
      </tr>
<%  }}catch(Exception e){e.printStackTrace();}%>
      </tbody></table>
    </div>
  </div>
</div>
</body></html>
