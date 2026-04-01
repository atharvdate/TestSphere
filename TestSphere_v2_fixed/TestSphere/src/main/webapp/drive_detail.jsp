<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.testsphere.util.DBConnection,com.testsphere.util.HtmlUtils" %>
<%@ page session="true" %>
<!DOCTYPE html><html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Drive Detail — TestSphere</title>
<link rel="stylesheet" href="<%= request.getContextPath() %>/css/main.css"></head>
<body>
<%
  String user=(String)session.getAttribute("username");
  String name=(String)session.getAttribute("fullName");
  int uid=Integer.parseInt((String)session.getAttribute("userId"));
  if(user==null||!"RECRUITER".equals(session.getAttribute("role"))){response.sendRedirect("login.jsp");return;}
  String ini=name!=null&&name.length()>=2?name.substring(0,2).toUpperCase():user.substring(0,Math.min(2,user.length())).toUpperCase();
  String driveIdStr=request.getParameter("driveId");
  if(driveIdStr==null){response.sendRedirect("manage_drives.jsp");return;}
  int driveId=Integer.parseInt(driveIdStr);

  String driveTitle="",jobRole="",driveStatus="",inviteToken="",collegeName="",regDeadline="",packageLpa="",description="",elYear="",elBranches="";
  double elCgpa=0; int elBacklogs=0,applicants=0;
  boolean found=false;
  try(Connection conn=DBConnection.getConnection();
      PreparedStatement ps=conn.prepareStatement(
        "SELECT d.*,c.name AS cname FROM drives d JOIN colleges c ON d.college_id=c.id WHERE d.id=? AND d.recruiter_id=?")){
    ps.setInt(1,driveId);ps.setInt(2,uid);
    ResultSet rs=ps.executeQuery();
    if(rs.next()){found=true;driveTitle=rs.getString("title");jobRole=rs.getString("job_role");
      driveStatus=rs.getString("status");inviteToken=rs.getString("invite_token");
      collegeName=rs.getString("cname");regDeadline=rs.getString("registration_deadline");
      packageLpa=rs.getString("package_lpa");description=rs.getString("description");
      elYear=rs.getString("eligibility_year");elCgpa=rs.getDouble("eligibility_min_cgpa");
      elBacklogs=rs.getInt("eligibility_max_backlogs");elBranches=rs.getString("eligibility_branches");
    }
  }catch(Exception e){e.printStackTrace();}
  if(!found){response.sendRedirect("manage_drives.jsp");return;}

  try(Connection conn=DBConnection.getConnection();
      PreparedStatement ps=conn.prepareStatement("SELECT COUNT(*) FROM drive_applications WHERE drive_id=?")){
    ps.setInt(1,driveId);ResultSet rs=ps.executeQuery();if(rs.next())applicants=rs.getInt(1);
  }catch(Exception e){e.printStackTrace();}

  String baseUrl=request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+request.getContextPath();
  String inviteUrl=baseUrl+"/joinDrive?token="+inviteToken;

  String created=request.getParameter("created");
  String roundAdded=request.getParameter("roundAdded");
  String released=request.getParameter("released");
%>
<div class="sidebar">
  <div class="sb-brand">Test<span>Sphere</span></div>
  <ul class="menu">
    <li><a href="recruiter_dashboard.jsp"><span class="ico">⊞</span>Dashboard</a></li>
    <li class="active"><a href="manage_drives.jsp"><span class="ico">📋</span>My Drives</a></li>
    <li><a href="create_drive.jsp"><span class="ico">＋</span>Create Drive</a></li>
  </ul>
  <div class="sb-foot">
    <div class="sb-user"><div class="avatar"><%= HtmlUtils.escape(ini) %></div>
      <div><div class="user-name"><%= HtmlUtils.escape(name!=null?name:user) %></div><div class="user-role-lbl">Recruiter</div></div>
    </div>
    <a href="logout" class="logout-lnk">↩ Sign Out</a>
  </div>
</div>
<div class="main">
  <div class="topbar">
    <div><h1><%= HtmlUtils.escape(driveTitle) %></h1>
      <p><%= HtmlUtils.escape(collegeName) %> &nbsp;·&nbsp; <%= HtmlUtils.escape(jobRole) %>
        <% if(packageLpa!=null&&!packageLpa.isEmpty()){%> &nbsp;·&nbsp; <%= HtmlUtils.escape(packageLpa) %><%}%>
      </p>
    </div>
    <div class="topbar-actions">
      <span class="badge <%= "ACTIVE".equals(driveStatus)?"bg-green":"DRAFT".equals(driveStatus)?"bg-orange":"bg-gray" %>"><%= driveStatus %></span>
      <% if("DRAFT".equals(driveStatus)){%>
      <form method="POST" action="updateDriveStatus" style="margin:0">
        <input type="hidden" name="driveId" value="<%= driveId %>">
        <input type="hidden" name="status" value="ACTIVE">
        <button class="btn-primary">▶ Activate Drive</button>
      </form>
      <%}%>
      <a href="manage_drives.jsp" class="btn-secondary">← Back</a>
    </div>
  </div>
  <div class="content">
    <% if("1".equals(created)){%><div class="alert alert-success">✓ Drive created! Add rounds below, then activate it.</div><%}%>
    <% if("1".equals(roundAdded)){%><div class="alert alert-success">✓ Round added.</div><%}%>
    <% if("1".equals(released)){%><div class="alert alert-success">✓ Results released. Students have been notified.</div><%}%>

    <%-- INVITE LINK --%>
    <div class="invite-box" style="margin-bottom:20px">
      <div>
        <div style="font-size:12px;font-weight:600;color:var(--muted);margin-bottom:4px">INVITE LINK — Share with <%= HtmlUtils.escape(collegeName) %> students only</div>
        <div class="invite-url" id="invite-url"><%= inviteUrl %></div>
      </div>
      <button class="copy-btn" onclick="copyLink()">Copy Link</button>
    </div>

    <%-- STATS ROW --%>
    <div class="stats-grid" style="grid-template-columns:repeat(3,1fr);margin-bottom:20px">
      <div class="stat-card"><div class="stat-lbl">Applicants</div><div class="stat-val"><%= applicants %></div></div>
      <div class="stat-card"><div class="stat-lbl">Reg. Deadline</div><div class="stat-val" style="font-size:16px"><%= regDeadline!=null&&regDeadline.length()>=10?regDeadline.substring(0,10):"—" %></div></div>
      <div class="stat-card"><div class="stat-lbl">Eligibility</div>
        <div style="font-size:13px;margin-top:6px;color:var(--muted)">
          Year: <strong><%= HtmlUtils.escape(elYear) %></strong><br>
          CGPA ≥ <strong><%= elCgpa %></strong> · Max backlogs: <strong><%= elBacklogs %></strong><br>
          Branches: <strong><%= HtmlUtils.escape(elBranches) %></strong>
        </div>
      </div>
    </div>

    <%-- ROUNDS --%>
    <div class="section" style="margin-bottom:20px">
      <div class="sec-hdr"><span class="sec-title">Rounds</span>
        <button onclick="document.getElementById('add-round-modal').classList.add('open')" class="btn-primary btn-sm">+ Add Round</button>
      </div>
      <table><thead><tr><th>#</th><th>Type</th><th>Title</th><th>Window</th><th>Status</th><th>Questions</th><th>Actions</th></tr></thead><tbody>
<%
  boolean anyRound=false;
  try(Connection conn=DBConnection.getConnection();
      PreparedStatement ps=conn.prepareStatement(
        "SELECT dr.*,(SELECT COUNT(*) FROM questions q WHERE q.round_id=dr.id) AS qcount FROM drive_rounds dr WHERE dr.drive_id=? ORDER BY dr.round_number")){
    ps.setInt(1,driveId);ResultSet rs=ps.executeQuery();
    while(rs.next()){anyRound=true;String rt=rs.getString("round_type");String rst=rs.getString("status");%>
    <tr>
      <td><%= rs.getInt("round_number") %></td>
      <td><span class="badge <%= "APTITUDE".equals(rt)?"bg-blue":"GD".equals(rt)?"bg-orange":"TECHNICAL".equals(rt)?"bg-purple":"bg-green" %>"><%= rt %></span></td>
      <td><strong><%= HtmlUtils.escape(rs.getString("title")) %></strong></td>
      <td class="text-sm text-muted">
        <% if("APTITUDE".equals(rt)&&rs.getString("start_time")!=null){%>
          <%= rs.getString("start_time").substring(0,16) %> → <%= rs.getString("end_time").substring(0,16) %>
        <%}else{%>Manual<%}%>
      </td>
      <td><span class="badge <%= "COMPLETED".equals(rst)?"bg-green":"ACTIVE".equals(rst)?"bg-blue":"bg-gray" %>"><%= rst %></span></td>
      <td><%= rs.getInt("qcount") %> <%= "APTITUDE".equals(rt)?"Q":"—" %></td>
      <td><div class="td-actions">
        <% if("APTITUDE".equals(rt)){%>
          <a href="add_question.jsp?roundId=<%= rs.getInt("id") %>&driveId=<%= driveId %>" class="btn-ghost btn-sm">+ Questions</a>
          <% String rCutoffType=rs.getString("cutoff_type"); String rCutoffVal=rs.getString("cutoff_value");
             boolean hasAutoCutoff = rCutoffType!=null && rCutoffVal!=null;
             if(!"COMPLETED".equals(rst)&&rs.getInt("qcount")>0&&!hasAutoCutoff){%>
          <button onclick="openRelease(<%= rs.getInt("id") %>)" class="btn-primary btn-sm">Release Results</button>
          <%} else if(!"COMPLETED".equals(rst)&&hasAutoCutoff){%>
          <span class="badge bg-blue" style="font-size:11px">⚡ Auto: <%= HtmlUtils.escape(rCutoffType) %> <%= HtmlUtils.escape(rCutoffVal) %></span>
          <%}%>
        <%}else{%>
          <a href="round_results.jsp?roundId=<%= rs.getInt("id") %>&driveId=<%= driveId %>" class="btn-ghost btn-sm">Mark Results</a>
        <%}%>
      </div></td>
    </tr>
<%  }}catch(Exception e){e.printStackTrace();}
  if(!anyRound){%><tr><td colspan="7"><div class="empty-state"><p>No rounds added yet. Add at least one Aptitude round to start.</p></div></td></tr><%}%>
      </tbody></table>
    </div>

    <%-- APPLICANTS LIST --%>
    <% String appAction=request.getParameter("action"); %>
    <% if("shortlisted".equals(appAction)){%><div class="alert alert-success">✓ Applicant shortlisted for aptitude.</div><%}%>
    <% if("rejected".equals(appAction)){%><div class="alert alert-error">Applicant rejected and notified.</div><%}%>
    <div class="section">
      <div class="sec-hdr">
        <span class="sec-title">Applicants (<%= applicants %>)</span>
        <div style="display:flex;gap:8px;align-items:center">
          <input type="text" id="app-search" placeholder="Search name / branch…"
            style="padding:5px 10px;border:1.5px solid #e5e5ea;border-radius:7px;font-size:13px;width:200px"
            oninput="filterApplicants()">
          <select id="app-filter-status" onchange="filterApplicants()"
            style="padding:5px 10px;border:1.5px solid #e5e5ea;border-radius:7px;font-size:13px">
            <option value="">All statuses</option>
            <option value="PENDING">Pending review</option>
            <option value="SHORTLISTED">Shortlisted</option>
            <option value="REJECTED">Rejected</option>
            <option value="ELIMINATED">Eliminated</option>
          </select>
          <label style="font-size:12px;color:var(--muted);display:flex;align-items:center;gap:4px">
            <input type="checkbox" id="sort-ai" onchange="sortByAI(this.checked)"> Sort by AI score
          </label>
        </div>
      </div>
      <table id="app-table"><thead><tr>
        <th>Student</th><th>Branch</th><th>CGPA</th>
        <th>AI Score</th><th>Resume Status</th><th>Round</th><th>Actions</th>
      </tr></thead><tbody>
<%
  boolean anyApp=false;
  try(Connection conn=DBConnection.getConnection();
      PreparedStatement ps=conn.prepareStatement(
        "SELECT u.full_name,u.username,u.branch,u.cgpa,da.id AS app_id," +
        "da.status,da.recruiter_status,da.current_round,da.resume_path,da.ai_score,da.ai_reason " +
        "FROM drive_applications da JOIN users u ON da.student_id=u.id " +
        "WHERE da.drive_id=? ORDER BY COALESCE(da.ai_score,-1) DESC, da.id")){
    ps.setInt(1,driveId);ResultSet rs=ps.executeQuery();
    while(rs.next()){anyApp=true;
      String ast=rs.getString("status");
      String rst=rs.getString("recruiter_status");
      int appId=rs.getInt("app_id");
      String resumeFile=rs.getString("resume_path");
      int aiScore=rs.getInt("ai_score"); boolean hasAi=!rs.wasNull();
      String aiReason=rs.getString("ai_reason");
      String aiColor=hasAi?(aiScore>=70?"#1e7e34":aiScore>=40?"#b85c00":"#c0392b"):"#aeaeb2";
%>
    <tr data-name="<%= HtmlUtils.escape(rs.getString("full_name").toLowerCase()) %>"
        data-branch="<%= HtmlUtils.escape(rs.getString("branch").toLowerCase()) %>"
        data-rstatus="<%= HtmlUtils.escape(rst) %>"
        data-status="<%= HtmlUtils.escape(ast) %>"
        data-ai="<%= hasAi?aiScore:-1 %>">
      <td>
        <strong><%= HtmlUtils.escape(rs.getString("full_name")) %></strong><br>
        <span class="text-sm text-muted"><%= HtmlUtils.escape(rs.getString("username")) %></span>
      </td>
      <td><span class="badge bg-blue"><%= HtmlUtils.escape(rs.getString("branch")) %></span></td>
      <td><%= rs.getDouble("cgpa") %></td>
      <td>
        <% if(hasAi){%>
          <span style="font-weight:600;color:<%= aiColor %>"><%= aiScore %>/100</span>
          <% if(aiReason!=null&&!aiReason.isEmpty()){%>
          <div class="text-sm text-muted" style="max-width:180px;white-space:normal;font-size:11px;margin-top:2px">
            <%= HtmlUtils.escape(aiReason) %>
          </div><%}%>
        <%}else{%><span class="text-sm text-muted">Scoring…</span><%}%>
      </td>
      <td>
        <div style="display:flex;align-items:center;gap:6px;flex-wrap:wrap">
          <span class="badge <%= "SHORTLISTED".equals(rst)?"bg-green":"REJECTED".equals(rst)?"bg-red":"bg-orange" %>">
            <%= rst %>
          </span>
          <% if(resumeFile!=null&&!resumeFile.isEmpty()){%>
          <a href="serveResume?appId=<%= appId %>" target="_blank" class="btn-ghost btn-sm" style="font-size:11px">📄 Resume</a>
          <%}%>
        </div>
      </td>
      <td class="text-sm text-muted">Round <%= rs.getInt("current_round") %></td>
      <td>
        <% if(!"REJECTED".equals(rst)&&!"ELIMINATED".equals(ast)){%>
        <div class="td-actions">
          <% if(!"SHORTLISTED".equals(rst)){%>
          <form method="POST" action="shortlistApplicant" style="margin:0">
            <input type="hidden" name="appId" value="<%= appId %>">
            <input type="hidden" name="driveId" value="<%= driveId %>">
            <input type="hidden" name="action" value="shortlist">
            <button class="btn-success btn-sm">✓ Shortlist</button>
          </form>
          <%}%>
          <form method="POST" action="shortlistApplicant" style="margin:0"
            onsubmit="return confirm('Reject this applicant? They will be notified.')">
            <input type="hidden" name="appId" value="<%= appId %>">
            <input type="hidden" name="driveId" value="<%= driveId %>">
            <input type="hidden" name="action" value="reject">
            <button class="btn-danger btn-sm">✕ Reject</button>
          </form>
        </div>
        <%}else{%><span class="text-sm text-muted"><%= "ELIMINATED".equals(ast)?"Eliminated":rst %></span><%}%>
      </td>
    </tr>
<%  }}catch(Exception e){e.printStackTrace();}
  if(!anyApp){%><tr><td colspan="7"><div class="empty-state"><div class="ico">👥</div><p>No applicants yet. Share the invite link above.</p></div></td></tr><%}%>
      </tbody></table>
    </div>
  </div>
</div>
<script>
function filterApplicants(){
  const q=(document.getElementById('app-search').value||'').toLowerCase();
  const sf=document.getElementById('app-filter-status').value;
  document.querySelectorAll('#app-table tbody tr[data-name]').forEach(row=>{
    const name=row.dataset.name||'';
    const branch=row.dataset.branch||'';
    const rst=row.dataset.rstatus||'';
    const ast=row.dataset.status||'';
    const matchQ=!q||name.includes(q)||branch.includes(q);
    const matchS=!sf||rst===sf||ast===sf;
    row.style.display=(matchQ&&matchS)?'':'none';
  });
}
function sortByAI(on){
  const tbody=document.querySelector('#app-table tbody');
  const rows=[...tbody.querySelectorAll('tr[data-name]')];
  if(on){
    rows.sort((a,b)=>parseInt(b.dataset.ai)-parseInt(a.dataset.ai));
  } else {
    rows.sort((a,b)=>(a.dataset.orig||0)-(b.dataset.orig||0));
  }
  rows.forEach((r,i)=>{if(!r.dataset.orig)r.dataset.orig=i;tbody.appendChild(r);});
}
</script>


<%-- ADD ROUND MODAL --%>
<div id="add-round-modal" class="modal-bg">
  <div class="modal">
    <h3>Add Round</h3>
    <form method="POST" action="addRound">
      <input type="hidden" name="driveId" value="<%= driveId %>">
      <div class="form-group"><label>Round Type</label>
        <select name="roundType" id="roundTypeSelect" onchange="toggleAptFields(this.value)" required>
          <option value="APTITUDE">Aptitude (MCQ — Auto Scored)</option>
          <option value="GD">Group Discussion</option>
          <option value="TECHNICAL">Technical Interview</option>
          <option value="HR">HR Interview</option>
        </select></div>
      <div class="form-group"><label>Round Title</label>
        <input type="text" name="title" placeholder="e.g. Aptitude Round 1"></div>
      <div class="form-group"><label>Instructions</label>
        <textarea name="instructions" rows="2" placeholder="Optional instructions for students"></textarea></div>
      <div id="apt-fields">
        <div class="form-row">
          <div class="form-group"><label>Start Time <span class="req">*</span></label><input type="datetime-local" name="startTime"></div>
          <div class="form-group"><label>End Time <span class="req">*</span></label><input type="datetime-local" name="endTime"></div>
        </div>
        <div class="form-group" style="background:#f0f7ff;border:1px solid #bfdbfe;border-radius:8px;padding:12px;margin-top:4px">
          <label style="color:#1d5fa8;font-weight:600">⚡ Auto-Release Cutoff</label>
          <span class="form-hint" style="display:block;margin-bottom:10px;color:#1d5fa8">Results will be automatically released when the test window closes</span>
          <div class="form-row">
            <div class="form-group" style="margin-bottom:0">
              <label>Cutoff Type</label>
              <select name="cutoffType" id="addCutoffType" onchange="updateAddCutoffHint(this.value)">
                <option value="TOP_N">Top N candidates</option>
                <option value="MIN_PERCENT">Minimum percentage</option>
              </select>
            </div>
            <div class="form-group" style="margin-bottom:0">
              <label id="add-cutoff-lbl">Number to qualify <span class="req">*</span></label>
              <input type="number" name="cutoffValue" id="addCutoffValue" placeholder="e.g. 50" min="1" required>
              <span class="form-hint" id="add-cutoff-hint">Top N students by score qualify</span>
            </div>
          </div>
        </div>
      </div>
      <div class="modal-actions">
        <button type="button" onclick="document.getElementById('add-round-modal').classList.remove('open')" class="btn-secondary">Cancel</button>
        <button type="submit" class="btn-primary">Add Round</button>
      </div>
    </form>
  </div>
</div>

<%-- RELEASE RESULTS MODAL --%>
<div id="release-modal" class="modal-bg">
  <div class="modal">
    <h3>Release Aptitude Results</h3>
    <p>Set the cutoff. Students will be notified immediately after release.</p>
    <form method="POST" action="releaseResults">
      <input type="hidden" name="driveId" value="<%= driveId %>">
      <input type="hidden" name="roundId" id="release-round-id">
      <div class="form-group"><label>Cutoff Type</label>
        <select name="cutoffType" onchange="updateCutoffHint(this.value)">
          <option value="TOP_N">Select Top N candidates</option>
          <option value="MIN_PERCENT">Minimum percentage</option>
        </select></div>
      <div class="form-group"><label id="cutoff-lbl">Number of candidates to qualify</label>
        <input type="number" name="cutoffValue" placeholder="e.g. 200" min="1" required>
        <span class="form-hint" id="cutoff-hint">Top N students by score will be marked qualified</span></div>
      <div class="modal-actions">
        <button type="button" onclick="document.getElementById('release-modal').classList.remove('open')" class="btn-secondary">Cancel</button>
        <button type="submit" class="btn-danger" style="background:#fff;border-color:#0071e3;color:#0071e3">Release & Notify</button>
      </div>
    </form>
  </div>
</div>

<script>
function copyLink(){
  navigator.clipboard.writeText(document.getElementById('invite-url').textContent.trim());
  const btn=document.querySelector('.copy-btn');
  btn.textContent='Copied!';setTimeout(()=>btn.textContent='Copy Link',2000);
}
function toggleAptFields(v){
  document.getElementById('apt-fields').style.display=v==='APTITUDE'?'block':'none';
  if(v==='APTITUDE'){
    document.getElementById('addCutoffValue').required=true;
  } else {
    document.getElementById('addCutoffValue').required=false;
  }
}
function updateAddCutoffHint(v){
  if(v==='TOP_N'){
    document.getElementById('add-cutoff-lbl').innerHTML='Number to qualify <span class="req">*</span>';
    document.getElementById('add-cutoff-hint').textContent='Top N students by score qualify';
    document.getElementById('addCutoffValue').placeholder='e.g. 50';
  } else {
    document.getElementById('add-cutoff-lbl').innerHTML='Min score percentage (%) <span class="req">*</span>';
    document.getElementById('add-cutoff-hint').textContent='Students at or above this % qualify';
    document.getElementById('addCutoffValue').placeholder='e.g. 60';
  }
}
function openRelease(roundId){
  document.getElementById('release-round-id').value=roundId;
  document.getElementById('release-modal').classList.add('open');
}
function updateCutoffHint(v){
  if(v==='TOP_N'){
    document.getElementById('cutoff-lbl').textContent='Number of candidates to qualify';
    document.getElementById('cutoff-hint').textContent='Top N students by score will be marked qualified';
  } else {
    document.getElementById('cutoff-lbl').textContent='Minimum score percentage (%)';
    document.getElementById('cutoff-hint').textContent='Students scoring at or above this percentage qualify';
  }
}
document.getElementById('add-round-modal').addEventListener('click',function(e){if(e.target===this)this.classList.remove('open')});
document.getElementById('release-modal').addEventListener('click',function(e){if(e.target===this)this.classList.remove('open')});
</script>
</body></html>
