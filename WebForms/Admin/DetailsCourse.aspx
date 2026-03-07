<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Courses CurrentCourse;
    protected string MessageText = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "课程详情";
        if (!EnsureAdminRole())
        {
            return;
        }

        int id;
        if (!int.TryParse(Request.QueryString["id"], out id) || id <= 0)
        {
            MessageText = "课程参数无效。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            CurrentCourse = db.Courses.Include("Teachers").FirstOrDefault(c => c.CourseID == id);
        }

        if (CurrentCourse == null)
        {
            MessageText = "课程不存在。";
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>课程详情</h2>

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } else { %>
    <div>
        <h4><%= H(CurrentCourse.CourseName) %></h4>
        <hr />
        <dl class="dl-horizontal">
            <dt>课程名称</dt>
            <dd><%= H(CurrentCourse.CourseName) %></dd>

            <dt>学分</dt>
            <dd><%= CurrentCourse.Credits %></dd>

            <dt>教师名称</dt>
            <dd><%= CurrentCourse.Teachers == null ? "-" : H(CurrentCourse.Teachers.TeacherName) %></dd>

            <dt>课程类别</dt>
            <dd><%= H(CourseTypeText(CurrentCourse.CourseType)) %></dd>
        </dl>
    </div>
    <p>
        <a class="btn btn-primary" href='EditCourse.aspx?id=<%= CurrentCourse.CourseID %>'>编辑</a>
        <a class="btn btn-default" href="CourseList.aspx">返回列表</a>
    </p>
<% } %>

<!--#include file="_AdminLayoutBottom.inc" -->
