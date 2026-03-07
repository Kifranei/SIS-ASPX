<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Exams CurrentExam;
    protected string MessageText = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "删除考试";
        if (!EnsureAdminRole())
        {
            return;
        }

        int id;
        if (!int.TryParse(Request.QueryString["id"] ?? Request.Form["ExamID"], out id) || id <= 0)
        {
            MessageText = "考试参数无效。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            CurrentExam = db.Exams.Include("Courses").FirstOrDefault(ei => ei.ExamID == id);
            if (CurrentExam == null)
            {
                MessageText = "考试记录不存在。";
                return;
            }

            if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
            {
                db.Exams.Remove(CurrentExam);
                db.SaveChanges();
                Response.Redirect("ExamList.aspx", true);
            }
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>删除考试</h2>

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } else { %>
    <h3>您确定要删除这条考试安排吗？</h3>
    <div>
        <h4><%= CurrentExam.Courses == null ? "-" : H(CurrentExam.Courses.CourseName) %></h4>
        <hr />
        <dl class="dl-horizontal">
            <dt>课程名称</dt>
            <dd><%= CurrentExam.Courses == null ? "-" : H(CurrentExam.Courses.CourseName) %></dd>

            <dt>考试时间</dt>
            <dd><%= CurrentExam.ExamTime.ToString("yyyy-MM-dd HH:mm") %></dd>

            <dt>考试地点</dt>
            <dd><%= H(CurrentExam.Location) %></dd>
        </dl>

        <form method="post" class="form-actions no-color">
            <input type="hidden" name="ExamID" value="<%= CurrentExam.ExamID %>" />
            <button type="submit" class="btn btn-danger">确认删除</button>
            <a class="btn btn-default" href="ExamList.aspx">返回列表</a>
        </form>
    </div>
<% } %>

<!--#include file="_AdminLayoutBottom.inc" -->
