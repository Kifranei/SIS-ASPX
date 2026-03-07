<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Courses CurrentCourse;
    protected string MessageText = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "删除课程";
        if (!EnsureAdminRole())
        {
            return;
        }

        int id;
        if (!int.TryParse(Request.QueryString["id"] ?? Request.Form["CourseID"], out id) || id <= 0)
        {
            MessageText = "课程参数无效。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            CurrentCourse = db.Courses.Include("Teachers").FirstOrDefault(c => c.CourseID == id);
            if (CurrentCourse == null)
            {
                MessageText = "课程不存在。";
                return;
            }

            if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
            {
                var isEnrolled = db.StudentCourses.Any(sc => sc.CourseID == id);
                if (isEnrolled)
                {
                    Session["AdminFlashError"] = "删除失败！该课程已被学生选择，无法删除。";
                    Response.Redirect("CourseList.aspx", true);
                    return;
                }

                var sessionsToDelete = db.ClassSessions.Where(cs => cs.CourseID == id).ToList();
                if (sessionsToDelete.Any())
                {
                    db.ClassSessions.RemoveRange(sessionsToDelete);
                }

                var examsToDelete = db.Exams.Where(ei => ei.CourseID == id).ToList();
                if (examsToDelete.Any())
                {
                    db.Exams.RemoveRange(examsToDelete);
                }

                db.Courses.Remove(CurrentCourse);
                db.SaveChanges();
                Session["AdminFlashMessage"] = "课程删除成功！";
                Response.Redirect("CourseList.aspx", true);
            }
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>删除课程</h2>

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } else { %>
    <h3>您确定要删除这个课程吗？</h3>
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
        </dl>

        <form method="post" class="form-actions no-color">
            <input type="hidden" name="CourseID" value="<%= CurrentCourse.CourseID %>" />
            <button type="submit" class="btn btn-danger">确认删除</button>
            <a class="btn btn-default" href="CourseList.aspx">返回列表</a>
        </form>
    </div>
<% } %>

<!--#include file="_AdminLayoutBottom.inc" -->

