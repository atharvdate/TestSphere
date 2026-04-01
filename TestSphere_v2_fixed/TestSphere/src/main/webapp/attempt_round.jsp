<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.testsphere.util.DBConnection,com.testsphere.util.HtmlUtils" %>
<%@ page session="true" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Attempt Test — TestSphere</title><link rel="stylesheet" href="<%= request.getContextPath() %>/css/main.css">
<style>
.test-wrap{max-width:780px;margin:0 auto;padding:28px 20px}
.test-nav{display:flex;align-items:center;justify-content:space-between;margin-bottom:24px}
.test-brand{font-size:18px;font-weight:700;letter-spacing:-.3px}
.test-brand span{color:#0071e3}
.test-head{margin-bottom:22px}
.test-title{font-size:20px;font-weight:700;letter-spacing:-.3px;margin-bottom:4px}
.test-meta{font-size:13.5px;color:#6e6e73}
.submit-zone{margin-top:28px;padding-top:20px;border-top:1px solid #e5e5ea;display:flex;align-items:center;gap:14px}
.tab-warn{position:fixed;top:14px;left:50%;transform:translateX(-50%);
  background:#1d1d1f;color:#fff;padding:9px 18px;border-radius:10px;
  font-size:13px;z-index:999;opacity:0;transition:opacity .3s;pointer-events:none}
.tab-warn.show{opacity:1}
.timer-box{background:#fff;border:1px solid #e5e5ea;border-radius:10px;
  padding:8px 16px;font-size:14px;font-weight:600;color:#1d1d1f;
  display:flex;align-items:center;gap:6px}
.timer-box.warn{border-color:#ff9500;color:#ff9500;background:#fffbf0}
.timer-box.danger{border-color:#ff3b30;color:#ff3b30;background:#fff5f5}
</style></head>
<body style="background:#f5f5f7;min-height:100vh">
<%
  String user=(String)session.getAttribute("username");
  int uid=Integer.parseInt((String)session.getAttribute("userId"));
  if(user==null||!"STUDENT".equals(session.getAttribute("role"))){response.sendRedirect("login.jsp");return;}

  String roundIdStr=request.getParameter("roundId");
  String appIdStr  =request.getParameter("appId");
  if(roundIdStr==null||appIdStr==null){response.sendRedirect("student_dashboard.jsp");return;}
  int roundId=Integer.parseInt(roundIdStr);
  int appId  =Integer.parseInt(appIdStr);

  // Verify student owns this application, is active, and has been shortlisted
  try(Connection conn=DBConnection.getConnection();
      PreparedStatement vp=conn.prepareStatement(
        "SELECT id FROM drive_applications WHERE id=? AND student_id=? AND status='ACTIVE' AND recruiter_status='SHORTLISTED'")){
    vp.setInt(1,appId);vp.setInt(2,uid);
    if(!vp.executeQuery().next()){response.sendRedirect("student_dashboard.jsp?error=not_shortlisted");return;}
  }catch(Exception e){e.printStackTrace();}

  // Already submitted?
  try(Connection conn=DBConnection.getConnection();
      PreparedStatement cp=conn.prepareStatement(
        "SELECT id FROM round_results WHERE application_id=? AND round_id=? AND submitted_at IS NOT NULL")){
    cp.setInt(1,appId);cp.setInt(2,roundId);
    if(cp.executeQuery().next()){response.sendRedirect("student_dashboard.jsp?error=already_submitted");return;}
  }catch(Exception e){e.printStackTrace();}

  // Load round info
  String roundTitle="Aptitude Test",driveTitle="",endTime="";
  boolean windowOpen=true;
  try(Connection conn=DBConnection.getConnection();
      PreparedStatement ps=conn.prepareStatement(
        "SELECT dr.title,dr.end_time,d.title AS dtitle, NOW()>dr.end_time AS expired " +
        "FROM drive_rounds dr JOIN drives d ON dr.drive_id=d.id WHERE dr.id=?")){
    ps.setInt(1,roundId);ResultSet rs=ps.executeQuery();
    if(rs.next()){
      roundTitle=rs.getString("title");driveTitle=rs.getString("dtitle");
      endTime=rs.getString("end_time")!=null?rs.getString("end_time"):"";windowOpen=rs.getInt("expired")==0;
    }
  }catch(Exception e){e.printStackTrace();}

  if(!windowOpen){response.sendRedirect("student_dashboard.jsp?error=window_closed");return;}

  // Load questions and shuffle order (anti-cheat)
  java.util.List<int[]>    qIds  = new java.util.ArrayList<>();
  java.util.List<String[]> qData = new java.util.ArrayList<>();
  try(Connection conn=DBConnection.getConnection();
      PreparedStatement ps=conn.prepareStatement(
        "SELECT id,question_text,option_a,option_b,option_c,option_d FROM questions WHERE round_id=? ORDER BY id")){
    ps.setInt(1,roundId);ResultSet rs=ps.executeQuery();
    while(rs.next()){
      qIds.add(new int[]{rs.getInt("id")});
      // Shuffle option order per student — map original A/B/C/D to a random order
      String[] opts = {rs.getString("option_a"),rs.getString("option_b"),
                       rs.getString("option_c"),rs.getString("option_d")};
      int[] idx = {0,1,2,3};
      // Fisher-Yates using student+question as seed for consistency within session
      java.util.Random rnd = new java.util.Random((long)uid * rs.getInt("id"));
      for(int k=3;k>0;k--){int j=rnd.nextInt(k+1);int t=idx[k];idx[k]=idx[j];idx[j]=t;}
      // Store: [questionText, opt0, opt1, opt2, opt3, letter0, letter1, letter2, letter3]
      String[] letters = {"A","B","C","D"};
      qData.add(new String[]{rs.getString("question_text"),
        opts[idx[0]],opts[idx[1]],opts[idx[2]],opts[idx[3]],
        letters[idx[0]],letters[idx[1]],letters[idx[2]],letters[idx[3]]});
    }
  }catch(Exception e){e.printStackTrace();}
  // Shuffle question order
  java.util.Collections.shuffle(qIds, new java.util.Random((long)uid * roundId));
  java.util.Collections.shuffle(qData, new java.util.Random((long)uid * roundId));
  int totalQ=qIds.size();
%>

<div id="tab-warn" class="tab-warn">⚠ Tab switch detected during test</div>

<div class="test-wrap">
  <div class="test-nav">
    <div class="test-brand">Test<span>Sphere</span></div>
    <div style="display:flex;align-items:center;gap:12px">
      <% if(!endTime.isEmpty()){%>
      <div class="timer-box" id="timer-box">
        ⏱ <span id="timer">--:--</span>
      </div>
      <%}%>
    </div>
  </div>

  <div class="test-head">
    <div class="test-title"><%= HtmlUtils.escape(roundTitle) %></div>
    <div class="test-meta"><%= HtmlUtils.escape(driveTitle) %> &nbsp;·&nbsp;
      <%= totalQ %> question<%= totalQ!=1?"s":"" %> &nbsp;·&nbsp;
      Results will be announced after the test closes</div>
  </div>

  <% if(totalQ==0){%>
    <div class="alert alert-info">No questions have been added to this round yet. Please check back later.</div>
  <%}else{%>

  <div class="prog-wrap"><div class="prog-bar" id="prog" style="width:0%"></div></div>
  <div style="font-size:13px;color:#6e6e73;margin-bottom:20px" id="q-counter">0 of <%= totalQ %> answered</div>

  <form action="submitTest" method="post" id="test-form">
    <input type="hidden" name="roundId"       value="<%= HtmlUtils.escape(roundIdStr) %>">
    <input type="hidden" name="applicationId" value="<%= HtmlUtils.escape(appIdStr) %>">
<%
  for(int i=0;i<qIds.size();i++){
    int qid=qIds.get(i)[0];String[] d=qData.get(i);
%>
    <div class="q-block" id="qb-<%= qid %>">
      <div class="q-text">
        <span style="color:#0071e3;font-weight:600;margin-right:6px">Q<%= (i+1) %>.</span>
        <%= HtmlUtils.escape(d[0]) %>
      </div>
<% String[] dispLetters={"A","B","C","D"};
   for(int k=0;k<4;k++){%>
      <label class="opt-label">
        <input type="radio" name="q<%= qid %>" value="<%= d[5+k] %>" onchange="onAnswer(this)">
        <span class="opt-letter"><%= dispLetters[k] %></span>
        <%= HtmlUtils.escape(d[k+1]) %>
      </label>
<%  }%>
    </div>
<%}%>

    <div class="submit-zone">
      <button type="submit" class="btn-primary" id="sub-btn" style="padding:11px 26px;font-size:15px">Submit Test</button>
      <span style="font-size:13px;color:#6e6e73" id="sub-status">Answer all questions before submitting.</span>
    </div>
  </form>
  <%}%>
</div>

<script>
const totalQ=<%= totalQ %>;
const endTimeMs=<%= !endTime.isEmpty() ? "new Date('"+endTime.replace(" ","T")+"').getTime()" : "0" %>;
let answered=0,submitted=false;

function onAnswer(radio){
  const block=radio.closest('.q-block');
  if(!block.dataset.answered){
    block.dataset.answered='1';answered++;
    document.getElementById('prog').style.width=Math.round(answered/totalQ*100)+'%';
    document.getElementById('q-counter').textContent=answered+' of '+totalQ+' answered';
    document.getElementById('sub-status').textContent=
      answered<totalQ?(totalQ-answered)+' question'+(totalQ-answered>1?'s':'')+' remaining':'All answered — ready to submit!';
  }
}

document.getElementById('test-form').addEventListener('submit',function(e){
  if(answered<totalQ){
    e.preventDefault();
    const first=document.querySelector('.q-block:not([data-answered])');
    if(first){first.scrollIntoView({behavior:'smooth',block:'center'});
      first.style.borderColor='#ff3b30';setTimeout(()=>first.style.borderColor='',1800);}
    document.getElementById('sub-status').textContent='⚠ Answer all '+totalQ+' questions first.';
    document.getElementById('sub-status').style.color='#c0392b';return;
  }
  submitted=true;
  document.getElementById('sub-btn').disabled=true;
  document.getElementById('sub-btn').textContent='Submitting…';
});

// Countdown timer
if(endTimeMs>0){
  function tick(){
    const left=endTimeMs-Date.now();
    if(left<=0){
      document.getElementById('timer').textContent='00:00';
      if(!submitted)document.getElementById('test-form').submit();
      return;
    }
    const m=Math.floor(left/60000);
    const s=Math.floor((left%60000)/1000);
    document.getElementById('timer').textContent=(m<10?'0':'')+m+':'+(s<10?'0':'')+s;
    const box=document.getElementById('timer-box');
    if(left<300000)box.className='timer-box warn';
    if(left<60000)box.className='timer-box danger';
    setTimeout(tick,1000);
  }
  tick();
}

// Tab switch detection
document.addEventListener('visibilitychange',function(){
  if(document.hidden&&!submitted){
    const w=document.getElementById('tab-warn');
    w.classList.add('show');setTimeout(()=>w.classList.remove('show'),3500);
  }
});
</script>
</body></html>
