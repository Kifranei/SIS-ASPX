<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected Courses CurrentCourse;
    protected List<StudentCourses> Enrollments = new List<StudentCourses>();
    protected string ErrorMessage = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        var currentUser = Session["User"] as Users;
        if (currentUser == null || currentUser.Role != 1)
        {
            Response.Redirect("~/Login.aspx", true);
            return;
        }

        int courseId;
        if (!int.TryParse(Request.QueryString["courseId"], out courseId) || courseId <= 0)
        {
            ErrorMessage = "参数 courseId 无效。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            var teacher = db.Teachers.FirstOrDefault(t => t.UserID == currentUser.UserID);
            if (teacher == null)
            {
                Response.Redirect("~/Login.aspx", true);
                return;
            }

            CurrentCourse = db.Courses.Include("Teachers").FirstOrDefault(c => c.CourseID == courseId && c.TeacherID == teacher.TeacherID);
            if (CurrentCourse == null)
            {
                ErrorMessage = "课程不存在或不属于当前教师。";
                return;
            }

            Enrollments = db.StudentCourses
                .Include("Students.Classes")
                .Where(sc => sc.CourseID == courseId)
                .OrderBy(sc => sc.Students.StudentID)
                .ToList();
        }
    }
</script>

<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>班级名单<%= CurrentCourse != null ? " - " + CurrentCourse.CourseName : "" %></title>
    <link href="<%= ResolveUrl("~/Content/bootstrap.min.css") %>" rel="stylesheet" />
    <style>
        body { padding: 20px; }
        .print-header { text-align: center; margin-bottom: 20px; }
        @media print { .no-print { display: none !important; } }
    </style>
</head>
<body>
    <div class="container-fluid">
        <% if (!string.IsNullOrEmpty(ErrorMessage)) { %>
            <div class="alert alert-danger"><%= ErrorMessage %></div>
            <a class="btn btn-default no-print" href="CourseList.aspx">返回授课列表</a>
        <% } else { %>
            <div class="print-header">
                <h2><%= CurrentCourse.CourseName %></h2>
                <h4>班级学生名单</h4>
                <p>授课教师：<%= CurrentCourse.Teachers == null ? "-" : CurrentCourse.Teachers.TeacherName %></p>
            </div>

            <button class="btn btn-primary no-print" onclick="window.print();">打印名单</button>
            <a class="btn btn-default no-print" href="CourseList.aspx">返回授课列表</a>

            <table class="table table-bordered table-striped" style="margin-top: 16px;">
                <thead>
                    <tr>
                        <th class="text-center" style="width: 70px;">序号</th>
                        <th>学号</th>
                        <th>姓名</th>
                        <th>性别</th>
                        <th>班级</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (int i = 0; i < Enrollments.Count; i++) {
                           var item = Enrollments[i]; %>
                        <tr>
                            <td class="text-center"><%= i + 1 %></td>
                            <td><%= item.Students == null ? "-" : item.Students.StudentID %></td>
                            <td><%= item.Students == null ? "-" : item.Students.StudentName %></td>
                            <td><%= item.Students == null ? "-" : item.Students.Gender %></td>
                            <td><%= item.Students == null || item.Students.Classes == null ? "-" : item.Students.Classes.ClassName %></td>
                        </tr>
                    <% } %>
                    <% if (!Enrollments.Any()) { %>
                        <tr><td colspan="5" class="text-center text-muted">暂无学生名单。</td></tr>
                    <% } %>
                </tbody>
            </table>
        <% } %>
    </div>
</body>
</html>

