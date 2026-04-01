<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.testsphere.util.DBConnection,com.testsphere.util.HtmlUtils" %>
<%@ page session="true" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Join Drive — TestSphere</title><link rel="stylesheet" href="<%= request.getContextPath() %>/css/main.css"></head>
<body class="auth-page" style="align-items:flex-start;padding-top:48px">
<%
  String inviteToken=(String)request.getAttribute("inviteToken");
  if(inviteToken==null)inviteToken=request.getParameter("token");
  if(inviteToken==null){response.sendRedirect("login.jsp");return;}

  // Load drive info
  String driveTitle="",jobRole="",companyName="",collegeName="",packageLpa="",description="",regDeadline="",driveStatus="";
  String elYear="",elBranches=""; double elCgpa=0; int elBacklogs=99;
  boolean found=false;
  try(Connection conn=DBConnection.getConnection();PreparedStatement ps=conn.prepareStatement(
    "SELECT d.*,u.company_name,c.name AS cname FROM drives d JOIN users u ON d.recruiter_id=u.id JOIN colleges c ON d.college_id=c.id WHERE d.invite_token=?")){
    ps.setString(1,inviteToken);ResultSet rs=ps.executeQuery();
    if(rs.next()){found=true;driveTitle=rs.getString("title");jobRole=rs.getString("job_role");
      companyName=rs.getString("company_name");collegeName=rs.getString("cname");
      packageLpa=rs.getString("package_lpa");description=rs.getString("description");
      regDeadline=rs.getString("registration_deadline");driveStatus=rs.getString("status");
      elYear=rs.getString("eligibility_year");elCgpa=rs.getDouble("eligibility_min_cgpa");
      elBacklogs=rs.getInt("eligibility_max_backlogs");elBranches=rs.getString("eligibility_branches");
    }
  }catch(Exception e){e.printStackTrace();}
%>
<div style="max-width:520px;margin:0 auto;width:100%;padding:0 20px">
  <div style="text-align:center;margin-bottom:24px">
    <div class="brand">Test<span style="color:#0071e3">Sphere</span></div>
    <div style="font-size:14px;color:#6e6e73;margin-top:4px">Placement Drive Invitation</div>
  </div>

  <% if(!found){%>
    <div class="alert alert-error">This invite link is invalid or has expired.</div>
    <div style="text-align:center;margin-top:20px"><a href="login.jsp" class="btn-primary">Go to Login</a></div>
  <%}else if("CLOSED".equals(driveStatus)){%>
    <div class="alert alert-error">This drive is now closed and no longer accepting applications.</div>
    <div style="text-align:center;margin-top:20px"><a href="login.jsp" class="btn-primary">Go to Login</a></div>
  <%}else{%>

  <div class="card" style="text-align:left">
    <div style="display:flex;align-items:flex-start;justify-content:space-between;margin-bottom:20px">
      <div>
        <div style="font-size:18px;font-weight:700;letter-spacing:-.3px"><%= HtmlUtils.escape(driveTitle) %></div>
        <div style="font-size:14px;color:#6e6e73;margin-top:3px">
          <%= HtmlUtils.escape(companyName) %> &nbsp;·&nbsp; <%= HtmlUtils.escape(jobRole) %>
          <% if(packageLpa!=null&&!packageLpa.isEmpty()){%> &nbsp;·&nbsp; <strong><%= HtmlUtils.escape(packageLpa) %></strong><%}%>
        </div>
      </div>
      <span class="badge bg-green" style="flex-shrink:0;margin-left:12px">OPEN</span>
    </div>

    <% if(description!=null&&!description.isEmpty()){%>
    <div style="font-size:13.5px;color:#6e6e73;line-height:1.6;margin-bottom:18px;padding:12px;background:#f5f5f7;border-radius:8px">
      <%= HtmlUtils.escape(description) %>
    </div>
    <%}%>

    <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:18px">
      <div style="padding:12px;background:#f5f5f7;border-radius:8px">
        <div style="font-size:11px;font-weight:600;color:#aeaeb2;text-transform:uppercase;letter-spacing:.4px;margin-bottom:4px">College</div>
        <div style="font-size:13.5px;font-weight:500"><%= HtmlUtils.escape(collegeName) %></div>
      </div>
      <div style="padding:12px;background:#f5f5f7;border-radius:8px">
        <div style="font-size:11px;font-weight:600;color:#aeaeb2;text-transform:uppercase;letter-spacing:.4px;margin-bottom:4px">Reg. Deadline</div>
        <div style="font-size:13.5px;font-weight:500"><%= regDeadline!=null&&regDeadline.length()>=16?regDeadline.substring(0,16):"—" %></div>
      </div>
    </div>

    <div style="padding:12px;border:1px solid #e5e5ea;border-radius:8px;margin-bottom:20px">
      <div style="font-size:12px;font-weight:600;color:#6e6e73;margin-bottom:8px">ELIGIBILITY CRITERIA</div>
      <div style="display:flex;flex-wrap:wrap;gap:7px">
        <span class="badge bg-blue">Year: <%= HtmlUtils.escape(elYear) %></span>
        <span class="badge bg-blue">Min CGPA: <%= elCgpa %></span>
        <span class="badge bg-blue">Max Backlogs: <%= elBacklogs %></span>
        <span class="badge bg-blue">Branches: <%= HtmlUtils.escape(elBranches) %></span>
      </div>
    </div>

    <%
      String loggedInRole=(String)session.getAttribute("role");
      boolean isLoggedIn=session.getAttribute("userId")!=null;
    %>
    <% if(isLoggedIn&&"STUDENT".equals(loggedInRole)){%>
      <% String resumeErr=request.getParameter("error"); %>
      <% if("resume_required".equals(resumeErr)){%>
        <div class="alert alert-error" style="margin-bottom:12px">Please upload your resume (PDF) to apply.</div>
      <%} else if("resume_not_pdf".equals(resumeErr)){%>
        <div class="alert alert-error" style="margin-bottom:12px">Only PDF files are accepted.</div>
      <%} else if("upload_failed".equals(resumeErr)){%>
        <div class="alert alert-error" style="margin-bottom:12px">Upload failed. Please try again (max 5 MB).</div>
      <%}%>
      <form method="POST" action="joinDrive" enctype="multipart/form-data">
        <input type="hidden" name="token" value="<%= HtmlUtils.escape(inviteToken) %>">
        <div style="margin-bottom:14px">
          <label style="display:block;font-size:13px;font-weight:500;color:#6e6e73;margin-bottom:6px">
            Resume <span style="color:#c0392b">*</span>
          </label>
          <input type="file" name="resume" accept=".pdf" required
            style="width:100%;padding:8px 10px;border:1.5px solid #e5e5ea;border-radius:8px;
                   font-size:13px;background:#f5f5f7;color:#1d1d1f;cursor:pointer">
          <div style="font-size:11.5px;color:#aeaeb2;margin-top:4px">PDF only · Max 5 MB</div>
        </div>
        <button type="submit" class="auth-btn">Register for this Drive</button>
      </form>
      <div style="font-size:12.5px;color:#aeaeb2;text-align:center;margin-top:10px">
        Your resume will be reviewed by the recruiter. Profile eligibility is checked automatically.
      </div>
    <%}else if(isLoggedIn){%>
      <div class="alert alert-info">Only student accounts can apply for placement drives.</div>
    <%}else{%>
      <div class="alert alert-info">Please sign in or create a student account to apply.</div>
      <div style="display:flex;gap:10px;margin-top:4px">
        <a href="login.jsp" class="auth-btn" style="text-decoration:none;text-align:center;display:block;flex:1">Sign In</a>
      </div>
      <div style="text-align:center;margin-top:12px;font-size:13px;color:#6e6e73">
        New student? <a href="register.jsp" style="color:#0071e3">Create an account</a> first, then come back to this link.
      </div>
    <%}%>
  </div>
  <%}%>
</div>
</body></html>
