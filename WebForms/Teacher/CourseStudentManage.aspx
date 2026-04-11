<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected List<Courses> CompulsoryCourses = new List<Courses>();
    protected Courses CurrentCourse;
    protected List<StudentCourses> EnrolledStudents = new List<StudentCourses>();
    protected List<Students> AvailableStudents = new List<Students>();

    protected int SelectedCourseId = 0;
    protected string SelectedStudentID = string.Empty;
    protected string MessageType = string.Empty;
    protected string MessageText = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        var currentUser = Session["User"] as Users;
        if (currentUser == null || currentUser.Role != 1)
        {
            Response.Redirect("~/Login.aspx", true);
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

            CompulsoryCourses = db.Courses
                .Where(c => c.TeacherID == teacher.TeacherID && (c.CourseType == 1 || c.CourseType == 2))
                .OrderBy(c => c.CourseName)
                .ToList();

            if (!CompulsoryCourses.Any())
            {
                MessageType = "info";
                MessageText = "您当前没有可管理学生名单的必修课程。";
                return;
            }

            SelectedCourseId = ResolveSelectedCourseId(CompulsoryCourses);
            CurrentCourse = CompulsoryCourses.FirstOrDefault(c => c.CourseID == SelectedCourseId);
            if (CurrentCourse == null)
            {
                CurrentCourse = CompulsoryCourses.First();
                SelectedCourseId = CurrentCourse.CourseID;
            }

            var action = (Request.Form["Action"] ?? string.Empty).Trim();
            if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase) && action == "addStudent")
            {
                SelectedStudentID = (Request.Form["StudentID"] ?? string.Empty).Trim();
                AddStudentToCourse(db, CurrentCourse.CourseID);
            }
            else if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase) && action == "removeStudent")
            {
                SelectedStudentID = (Request.Form["StudentID"] ?? string.Empty).Trim();
                RemoveStudentFromCourse(db, CurrentCourse.CourseID);
            }

            LoadStudentLists(db, CurrentCourse.CourseID);
        }
    }

    protected int ResolveSelectedCourseId(List<Courses> courses)
    {
        int courseId;
        var formCourseId = Request.Form["CourseID"];
        if (!string.IsNullOrWhiteSpace(formCourseId) && int.TryParse(formCourseId, out courseId) && courses.Any(c => c.CourseID == courseId))
        {
            return courseId;
        }

        var queryCourseId = Request.QueryString["courseId"];
        if (!string.IsNullOrWhiteSpace(queryCourseId) && int.TryParse(queryCourseId, out courseId) && courses.Any(c => c.CourseID == courseId))
        {
            return courseId;
        }

        return courses.First().CourseID;
    }

    private void AddStudentToCourse(StudentManagementDBEntities db, int courseId)
    {
        if (string.IsNullOrWhiteSpace(SelectedStudentID))
        {
            MessageType = "warning";
            MessageText = "请选择要添加的学生。";
            return;
        }

        var student = db.Students.Find(SelectedStudentID);
        if (student == null)
        {
            MessageType = "danger";
            MessageText = "学生不存在。";
            return;
        }

        var exists = db.StudentCourses.Any(sc => sc.CourseID == courseId && sc.StudentID == SelectedStudentID);
        if (exists)
        {
            MessageType = "info";
            MessageText = "该学生已在课程名单中，无需重复添加。";
            return;
        }

        var conflicts = StudentInformationSystem.Helpers.ScheduleConflictHelper.GetStudentConflictsForCourseAssignment(db, SelectedStudentID, courseId);
        if (conflicts.Any())
        {
            MessageType = "danger";
            MessageText = StudentInformationSystem.Helpers.ScheduleConflictHelper.BuildStudentConflictMessage(
                conflicts,
                "无法加入课程名单，学生课表存在冲突：");
            return;
        }

        db.StudentCourses.Add(new StudentCourses
        {
            StudentID = SelectedStudentID,
            CourseID = courseId,
            Grade = null
        });
        db.SaveChanges();

        MessageType = "success";
        MessageText = "学生已成功添加到课程名单。";
        SelectedStudentID = string.Empty;
    }

    private void RemoveStudentFromCourse(StudentManagementDBEntities db, int courseId)
    {
        if (string.IsNullOrWhiteSpace(SelectedStudentID))
        {
            MessageType = "warning";
            MessageText = "学生参数无效。";
            return;
        }

        var enrollment = db.StudentCourses.FirstOrDefault(sc => sc.CourseID == courseId && sc.StudentID == SelectedStudentID);
        if (enrollment == null)
        {
            MessageType = "info";
            MessageText = "该学生已不在课程名单中。";
            return;
        }

        db.StudentCourses.Remove(enrollment);
        db.SaveChanges();

        MessageType = "success";
        MessageText = "学生已从课程名单中移除。";
        SelectedStudentID = string.Empty;
    }

    private void LoadStudentLists(StudentManagementDBEntities db, int courseId)
    {
        EnrolledStudents = db.StudentCourses
            .Include("Students.Classes")
            .Where(sc => sc.CourseID == courseId)
            .OrderBy(sc => sc.StudentID)
            .ToList();

        var enrolledIds = EnrolledStudents.Select(sc => sc.StudentID).ToList();
        AvailableStudents = db.Students
            .Include("Classes")
            .Where(s => !enrolledIds.Contains(s.StudentID))
            .OrderBy(s => s.StudentID)
            .ToList();
    }

    protected string Active(string page)
    {
        var current = VirtualPathUtility.GetFileName(Request.AppRelativeCurrentExecutionFilePath) ?? string.Empty;
        return current.Equals(page, StringComparison.OrdinalIgnoreCase) ? "active" : string.Empty;
    }

    protected string CourseTypeText(int courseType)
    {
        switch (courseType)
        {
            case 1: return "专业必修";
            case 2: return "公共必修";
            default: return "其他";
        }
    }

    protected string StudentClassName(Students student)
    {
        if (student == null || student.Classes == null)
        {
            return "未分班";
        }

        return student.Classes.ClassName ?? "未分班";
    }
</script>

<!DOCTYPE html>
<html lang="zh-CN">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <script>
        (function () {
            var theme = localStorage.getItem('theme');
            var isDark = theme === 'dark';
            if (isDark) {
                document.documentElement.classList.add('dark-mode');
            } else {
                document.documentElement.classList.remove('dark-mode');
            }
        })();
    </script>
    <title>课程学生管理</title>
    <link href="<%= ResolveUrl("~/Content/bootstrap.min.css") %>" rel="stylesheet" />
    <link href="<%= ResolveUrl("~/Content/theme-system.css") %>" rel="stylesheet" />
    <link href="<%= ResolveUrl("~/Content/webforms-student-layout.css") %>" rel="stylesheet" />
</head>
<body class="webforms-student">
    <div class="page-wrapper">
        <div class="sidebar-overlay"></div>
        <aside class="sidebar">
            <div class="sidebar-header">
                <img src="https://jwgl.hrbzy.edu.cn:9081/style04/images/logo.png" height="35" alt="校徽" class="sidebar-logo-img" />
            </div>
            <ul class="sidebar-menu">
                <li><a class="<%= Active("Index.aspx") %>" href="Index.aspx">首页</a></li>
                <li><a class="<%= Active("Timetable.aspx") %>" href="Timetable.aspx">我的课表</a></li>
                <li><a class="<%= Active("CourseList.aspx") %>" href="CourseList.aspx">成绩录入</a></li>
                <li><a class="<%= Active("ExamList.aspx") %>" href="ExamList.aspx">考试管理</a></li>
                <li><a class="<%= Active("ChangePassword.aspx") %>" href="ChangePassword.aspx">修改密码</a></li>
            </ul>
        </aside>

        <div class="main-content">
            <header class="header-bar">
                <div class="header-left">
                    <button class="hamburger-menu" type="button" aria-label="菜单">&#9776;</button>
                </div>
                <div class="header-right">
                    <button class='dark-toggle-btn' type='button'>暗色模式</button>
                    <div class="user-info">
                        <span class="username">欢迎您, <%= ((Session["User"] as Users)?.Username ?? "教师") %></span>
                        <span class="sep">|</span>
                        <a class="logout-link" href="../Logout.aspx">安全退出</a>
                    </div>
                </div>
            </header>

            <main class="content-body">
                <div class="container-fluid">
                    <div class="text-right" style="margin-bottom: 15px;">
                        <a class="btn btn-default" href="Timetable.aspx">返回上一页</a>
                    </div>
                    <h2>课程学生管理（必修课）</h2>
                    <p class="text-muted">仅显示当前教师所授的专业必修/公共必修课程，可在此直接添加学生到课程名单。</p>

                    <% if (!string.IsNullOrEmpty(MessageText)) { %>
                        <div class="alert alert-<%= MessageType %>"><%= Server.HtmlEncode(MessageText) %></div>
                    <% } %>

                    <% if (CompulsoryCourses.Any() && CurrentCourse != null) { %>
                        <form method="get" class="form-inline" style="margin-bottom: 15px;">
                            <div class="form-group" style="margin-right: 10px;">
                                <label style="margin-right: 8px;">选择课程：</label>
                                <select name="courseId" class="form-control" style="min-width: 280px;">
                                    <% foreach (var c in CompulsoryCourses) { %>
                                        <option value="<%= c.CourseID %>" <%= c.CourseID == SelectedCourseId ? "selected" : "" %>>
                                            <%= Server.HtmlEncode(c.CourseName) %>（<%= CourseTypeText(c.CourseType) %>）
                                        </option>
                                    <% } %>
                                </select>
                            </div>
                            <button type="submit" class="btn btn-default">切换课程</button>
                        </form>

                        <div class="panel panel-default">
                            <div class="panel-body">
                                <strong>当前课程：</strong>
                                <span><%= Server.HtmlEncode(CurrentCourse.CourseName) %></span>
                                <span class="label label-info" style="margin-left: 8px;"><%= CourseTypeText(CurrentCourse.CourseType) %></span>
                            </div>
                        </div>

                        <form method="post" class="form-inline" style="margin-bottom: 15px;">
                            <input type="hidden" name="Action" value="addStudent" />
                            <input type="hidden" name="CourseID" value="<%= CurrentCourse.CourseID %>" />
                            <div class="form-group" style="min-width: 420px; margin-right: 10px;">
                                <label style="margin-right: 8px;">添加学生：</label>
                                <select class="form-control" name="StudentID" style="min-width: 340px;" required>
                                    <option value="">--请选择学生--</option>
                                    <% foreach (var s in AvailableStudents) { %>
                                        <option value="<%= Server.HtmlEncode(s.StudentID) %>" <%= string.Equals(SelectedStudentID, s.StudentID, StringComparison.OrdinalIgnoreCase) ? "selected" : "" %>>
                                            <%= Server.HtmlEncode(s.StudentID) %> - <%= Server.HtmlEncode(s.StudentName) %>（<%= Server.HtmlEncode(StudentClassName(s)) %>）
                                        </option>
                                    <% } %>
                                </select>
                            </div>
                            <button type="submit" class="btn btn-primary" <%= AvailableStudents.Any() ? "" : "disabled" %>>添加到课程</button>
                            <% if (!AvailableStudents.Any()) { %>
                                <span class="text-muted" style="margin-left: 8px;">暂无可添加学生。</span>
                            <% } %>
                        </form>

                        <div class="table-responsive">
                            <table class="table table-striped table-bordered">
                                <thead>
                                    <tr>
                                        <th>学号</th>
                                        <th>姓名</th>
                                        <th>性别</th>
                                        <th>班级</th>
                                        <th style="width: 110px;">操作</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% if (EnrolledStudents.Any()) { %>
                                        <% foreach (var item in EnrolledStudents) { var stu = item.Students; %>
                                            <tr>
                                                <td><%= stu == null ? "-" : Server.HtmlEncode(stu.StudentID) %></td>
                                                <td><%= stu == null ? "-" : Server.HtmlEncode(stu.StudentName) %></td>
                                                <td><%= stu == null ? "-" : Server.HtmlEncode(stu.Gender) %></td>
                                                <td><%= stu == null ? "-" : Server.HtmlEncode(StudentClassName(stu)) %></td>
                                                <td>
                                                    <% if (stu != null) { %>
                                                        <form method="post" style="display:inline;" onsubmit="return confirm('确认将该学生从本课程中移除？');">
                                                            <input type="hidden" name="Action" value="removeStudent" />
                                                            <input type="hidden" name="CourseID" value="<%= CurrentCourse.CourseID %>" />
                                                            <input type="hidden" name="StudentID" value="<%= Server.HtmlEncode(stu.StudentID) %>" />
                                                            <button type="submit" class="btn btn-danger btn-xs">移除</button>
                                                        </form>
                                                    <% } else { %>
                                                        <span class="text-muted">-</span>
                                                    <% } %>
                                                </td>
                                            </tr>
                                        <% } %>
                                    <% } else { %>
                                        <tr><td colspan="5" class="text-center text-muted">当前课程暂无学生。</td></tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    <% } else { %>
                        <div class="alert alert-info">您当前没有可管理的必修课程。</div>
                    <% } %>
                </div>
            </main>
        </div>
    </div>

    <script src="<%= ResolveUrl("~/Scripts/webforms-student-layout.js") %>"></script>
</body>
</html>
