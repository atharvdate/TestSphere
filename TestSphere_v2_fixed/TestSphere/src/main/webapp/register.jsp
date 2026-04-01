<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.testsphere.util.DBConnection" %>
<%@ page import="com.testsphere.util.HtmlUtils" %>
<!DOCTYPE html><html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>TestSphere — Register</title>
<link rel="stylesheet" href="css/main.css"></head>
<body class="auth-page">
<%
  String err=(String)request.getAttribute("errorMessage");
%>
<div class="auth-wrap">
  <div class="brand">Test<span>Sphere</span></div>
  <div class="brand-sub">Create your account</div>
  <div class="card">
    <% if(err!=null){%><div class="alert alert-error"><%= HtmlUtils.escape(err) %></div><%}%>

    <div class="tabs">
      <button class="tab-btn active" onclick="showTab('student',this)">Student</button>
      <button class="tab-btn" onclick="showTab('recruiter',this)">Recruiter</button>
      <button class="tab-btn" onclick="showTab('college',this)">College Admin</button>
    </div>

    <%-- STUDENT FORM --%>
    <form id="form-student" method="POST" action="register">
      <input type="hidden" name="role" value="STUDENT">
      <div class="alert alert-info">Your registration must be approved by your college admin before you can log in.</div>
      <div class="field-row">
        <div class="field"><label>Full Name</label>
          <input type="text" name="fullName" placeholder="Your full name" required></div>
        <div class="field"><label>Username</label>
          <input type="text" name="username" placeholder="Min 3 chars" required minlength="3"></div>
      </div>
      <div class="field-row">
        <div class="field"><label>Email</label>
          <input type="email" name="email" placeholder="College email preferred" required></div>
        <div class="field"><label>Phone</label>
          <input type="tel" name="phone" placeholder="10-digit number"></div>
      </div>
      <div class="field"><label>Password</label>
        <input type="password" name="password" placeholder="Min 6 characters" required minlength="6"></div>
      <div class="field"><label>College</label>
        <div class="sel-wrap"><select name="collegeId" required>
          <option value="" disabled selected hidden>Select your college</option>
<%
  try(Connection conn=DBConnection.getConnection();
      PreparedStatement ps=conn.prepareStatement("SELECT id,name,city FROM colleges WHERE status='APPROVED' ORDER BY name")){
    ResultSet rs=ps.executeQuery();
    while(rs.next()){%>
          <option value="<%= rs.getInt("id") %>"><%= HtmlUtils.escape(rs.getString("name")) %> — <%= HtmlUtils.escape(rs.getString("city")) %></option>
<%  }}catch(Exception e){e.printStackTrace();}%>
        </select></div>
      </div>
      <div class="field-row">
        <div class="field"><label>Year of Study</label>
          <div class="sel-wrap"><select name="year" required>
            <option value="" disabled selected hidden>Select year</option>
            <option>1st Year</option><option>2nd Year</option>
            <option>3rd Year</option><option>Final Year</option>
          </select></div>
        </div>
        <div class="field"><label>Branch</label>
          <div class="sel-wrap"><select name="branch" required>
            <option value="" disabled selected hidden>Select branch</option>
            <option>CSE</option><option>IT</option><option>ECE</option>
            <option>EEE</option><option>MECH</option><option>CIVIL</option>
            <option>MBA</option><option>MCA</option><option>OTHER</option>
          </select></div>
        </div>
      </div>
      <div class="field-row">
        <div class="field"><label>CGPA</label>
          <input type="number" name="cgpa" placeholder="e.g. 8.5" step="0.01" min="0" max="10" required></div>
        <div class="field"><label>Active Backlogs</label>
          <input type="number" name="backlogs" placeholder="0 if none" min="0" required></div>
      </div>
      <button type="submit" class="auth-btn">Create Student Account</button>
    </form>

    <%-- RECRUITER FORM --%>
    <form id="form-recruiter" method="POST" action="register" style="display:none">
      <input type="hidden" name="role" value="RECRUITER">
      <div class="alert alert-info">Recruiter accounts require admin approval before you can login.</div>
      <div class="field-row">
        <div class="field"><label>Full Name</label>
          <input type="text" name="fullName" placeholder="Your full name"></div>
        <div class="field"><label>Username</label>
          <input type="text" name="username" placeholder="Min 3 chars" minlength="3"></div>
      </div>
      <div class="field"><label>Personal Email</label>
        <input type="email" name="email" placeholder="your@email.com"></div>
      <div class="field-row">
        <div class="field"><label>Phone</label>
          <input type="tel" name="phone" placeholder="10-digit number"></div>
        <div class="field"><label>Password</label>
          <input type="password" name="password" placeholder="Min 6 characters" minlength="6"></div>
      </div>
      <div class="field"><label>Company Name</label>
        <input type="text" name="companyName" placeholder="e.g. Infosys Ltd."></div>
      <div class="field"><label>Company Website</label>
        <input type="url" name="companyWebsite" placeholder="https://company.com"></div>
      <div class="field"><label>Official Company Email <span class="req">*</span></label>
        <input type="email" name="officialEmail" placeholder="you@company.com">
        <span class="form-hint">Must be your company domain — Gmail/Yahoo not accepted</span></div>
      <button type="submit" class="auth-btn">Request Recruiter Account</button>
    </form>

    <%-- COLLEGE ADMIN FORM --%>
    <form id="form-college" method="POST" action="register" style="display:none">
      <input type="hidden" name="role" value="COLLEGE_ADMIN">
      <div class="alert alert-info">College accounts require admin approval. Students can register only after your college is approved.</div>
      <div class="field-row">
        <div class="field"><label>Your Full Name</label>
          <input type="text" name="fullName" placeholder="Coordinator name"></div>
        <div class="field"><label>Username</label>
          <input type="text" name="username" placeholder="Min 3 chars" minlength="3"></div>
      </div>
      <div class="field-row">
        <div class="field"><label>Email</label>
          <input type="email" name="email" placeholder="Official email"></div>
        <div class="field"><label>Phone</label>
          <input type="tel" name="phone" placeholder="10-digit number"></div>
      </div>
      <div class="field"><label>Password</label>
        <input type="password" name="password" placeholder="Min 6 characters" minlength="6"></div>
      <div class="field-row">
        <div class="field"><label>College Name</label>
          <input type="text" name="collegeName" placeholder="Full official name"></div>
        <div class="field"><label>City</label>
          <input type="text" name="collegeCity" placeholder="City"></div>
      </div>
      <div class="field"><label>College Code <span class="req">*</span></label>
        <input type="text" name="collegeCode" placeholder="Unique code e.g. MITCOE" style="text-transform:uppercase">
        <span class="form-hint">Short unique identifier for your college</span></div>
      <button type="submit" class="auth-btn">Register College</button>
    </form>

    <div class="card-foot">Already have an account? <a href="login.jsp">Sign In</a></div>
  </div>
</div>
<script>
function showTab(name,btn){
  document.querySelectorAll('.tab-btn').forEach(b=>b.classList.remove('active'));
  btn.classList.add('active');
  ['student','recruiter','college'].forEach(t=>{
    document.getElementById('form-'+t).style.display=t===name?'block':'none';
  });
}
</script>
</body></html>
