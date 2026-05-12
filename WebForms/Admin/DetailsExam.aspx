<%@ Page CodePage="65001" Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Exams CurrentExam;
    protected string MessageText = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "考试详情";
        if (!EnsureAdminRole())
        {
            return;
        }

        int id;
        if (!int.TryParse(Request.QueryString["id"], out id) || id <= 0)
        {
            MessageText = "考试参数无效。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            CurrentExam = db.Exams.Include("Courses").FirstOrDefault(ei => ei.ExamID == id);
        }

        if (CurrentExam == null)
        {
            MessageText = "考试记录不存在。";
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>考试详情</h2>

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } else { %>
    <div>
        <h4><%= CurrentExam.Courses == null ? "-" : H(CurrentExam.Courses.CourseName) %></h4>
        <hr />
        <dl class="dl-horizontal">
            <dt>课程名称</dt>
            <dd><%= CurrentExam.Courses == null ? "-" : H(CurrentExam.Courses.CourseName) %></dd>

            <dt>考试时间</dt>
            <dd><%= CurrentExam.StartTime.ToString("yyyy-MM-dd HH:mm") + " - " + CurrentExam.EndTime.ToString("HH:mm") %></dd>

            <dt>考试地点</dt>
            <dd><%= H(CurrentExam.Location) %></dd>

            <dt>备注</dt>
            <dd><%= H(CurrentExam.Details) %></dd>
        </dl>
    </div>
    <p>
        <a class="btn btn-primary" href='EditExam.aspx?id=<%= CurrentExam.ExamID %>'>编辑</a>
        <a class="btn btn-default" href="ExamList.aspx">返回列表</a>
    </p>
<% } %>

<!--#include file="_AdminLayoutBottom.inc" -->
