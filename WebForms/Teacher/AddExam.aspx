<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected List<Courses> TeacherCourses = new List<Courses>();
    protected string MessageType = string.Empty;
    protected string MessageText = string.Empty;

    protected int FormCourseId = 0;
    protected string FormExamTime = string.Empty;
    protected string FormLocation = string.Empty;
    protected string FormDetails = string.Empty;

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

            TeacherCourses = db.Courses.Where(c => c.TeacherID == teacher.TeacherID).OrderBy(c => c.CourseName).ToList();

            if (!Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
            {
                if (TeacherCourses.Any())
                {
                    FormCourseId = TeacherCourses[0].CourseID;
                }
                return;
            }

            int.TryParse(Request.Form["CourseID"], out FormCourseId);
            FormExamTime = (Request.Form["ExamTime"] ?? string.Empty).Trim();
            FormLocation = (Request.Form["Location"] ?? string.Empty).Trim();
            FormDetails = (Request.Form["Details"] ?? string.Empty).Trim();

            if (!TeacherCourses.Any(c => c.CourseID == FormCourseId))
            {
                MessageType = "danger";
                MessageText = "课程参数无效。";
                return;
            }

            DateTime examTime;
            if (!DateTime.TryParse(FormExamTime, out examTime))
            {
                MessageType = "danger";
                MessageText = "考试时间格式无效。";
                return;
            }

            if (string.IsNullOrWhiteSpace(FormLocation))
            {
                MessageType = "danger";
                MessageText = "请填写考试地点。";
                return;
            }

            var selectedCourse = TeacherCourses.FirstOrDefault(c => c.CourseID == FormCourseId);
            var teacherConflicts = GetTeacherExamConflicts(
                db,
                selectedCourse == null ? null : selectedCourse.TeacherID,
                examTime);
            if (teacherConflicts.Any())
            {
                MessageType = "danger";
                MessageText = BuildTeacherExamConflictMessage(
                    teacherConflicts,
                    "考试时间冲突！您在该时段已有以下考试安排：");
                return;
            }

            var studentConflicts = GetStudentExamConflictsForCourse(
                db,
                FormCourseId,
                examTime);
            if (studentConflicts.Any())
            {
                MessageType = "danger";
                MessageText = BuildStudentExamConflictMessage(
                    studentConflicts,
                    "考试时间冲突！以下学生在该时段已有其他考试：");
                return;
            }

            var exam = new Exams
            {
                CourseID = FormCourseId,
                ExamTime = examTime,
                Location = FormLocation,
                Details = FormDetails
            };

            db.Exams.Add(exam);
            db.SaveChanges();

            Response.Redirect("ExamList.aspx?msg=" + Server.UrlEncode("考试安排创建成功。"), true);
        }
    }

    protected string Active(string page)
    {
        var current = VirtualPathUtility.GetFileName(Request.AppRelativeCurrentExecutionFilePath) ?? string.Empty;
        return current.Equals(page, StringComparison.OrdinalIgnoreCase) ? "active" : string.Empty;
    }

    private List<Exams> GetTeacherExamConflicts(StudentManagementDBEntities db, string teacherId, DateTime examTime, int? excludeExamId = null)
    {
        if (string.IsNullOrWhiteSpace(teacherId))
        {
            return new List<Exams>();
        }

        var query = db.Exams
            .Include("Courses")
            .Where(e => e.ExamTime == examTime && e.Courses != null && e.Courses.TeacherID == teacherId);

        if (excludeExamId.HasValue)
        {
            int examId = excludeExamId.Value;
            query = query.Where(e => e.ExamID != examId);
        }

        return query.OrderBy(e => e.Courses.CourseName).ToList();
    }

    private List<string> GetStudentExamConflictsForCourse(StudentManagementDBEntities db, int courseId, DateTime examTime, int? excludeExamId = null)
    {
        var studentIds = db.StudentCourses
            .Where(sc => sc.CourseID == courseId)
            .Select(sc => sc.StudentID)
            .Distinct()
            .ToList();

        if (!studentIds.Any())
        {
            return new List<string>();
        }

        var query = db.StudentCourses
            .Where(sc => studentIds.Contains(sc.StudentID)
                && sc.CourseID != courseId
                && sc.Courses.Exams.Any(e => e.ExamTime == examTime && (!excludeExamId.HasValue || e.ExamID != excludeExamId.Value)))
            .Select(sc => sc.StudentID + " " + sc.Students.StudentName + " -> " + sc.Courses.CourseName)
            .Distinct();

        return query.OrderBy(x => x).ToList();
    }

    private string BuildTeacherExamConflictMessage(IEnumerable<Exams> conflicts, string prefix)
    {
        return prefix + " " + string.Join("；", conflicts.Select(e => (e.Courses == null ? "未知课程" : e.Courses.CourseName) + "（" + e.ExamTime.ToString("yyyy-MM-dd HH:mm") + "）"));
    }

    private string BuildStudentExamConflictMessage(IEnumerable<string> conflicts, string prefix)
    {
        return prefix + " " + string.Join("；", conflicts);
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
    <title>添加新考试</title>
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
                    <h2>添加新考试</h2>
                    <hr />

                    <% if (!string.IsNullOrEmpty(MessageText)) { %>
                        <div class="alert alert-<%= MessageType %>"><%= MessageText %></div>
                    <% } %>

                    <form method="post" class="form-horizontal" style="max-width: 820px;">
                        <div class="form-group">
                            <label class="control-label col-md-2">课程名称</label>
                            <div class="col-md-10">
                                <select class="form-control" name="CourseID" required>
                                    <option value="">--请选择课程--</option>
                                    <% foreach (var c in TeacherCourses) { %>
                                        <option value="<%= c.CourseID %>" <%= c.CourseID == FormCourseId ? "selected" : "" %>><%= c.CourseName %></option>
                                    <% } %>
                                </select>
                            </div>
                        </div>

                        <div class="form-group">
                            <label class="control-label col-md-2">考试时间</label>
                            <div class="col-md-10">
                                <input class="form-control" type="datetime-local" name="ExamTime" value="<%= FormExamTime %>" required />
                            </div>
                        </div>

                        <div class="form-group">
                            <label class="control-label col-md-2">考试地点</label>
                            <div class="col-md-10">
                                <input class="form-control" name="Location" value="<%= FormLocation %>" required />
                            </div>
                        </div>

                        <div class="form-group">
                            <label class="control-label col-md-2">备注</label>
                            <div class="col-md-10">
                                <input class="form-control" name="Details" value="<%= FormDetails %>" />
                            </div>
                        </div>

                        <div class="form-group">
                            <div class="col-md-offset-2 col-md-10">
                                <button type="submit" class="btn btn-success">创建</button>
                                <a class="btn btn-default" href="ExamList.aspx">返回列表</a>
                            </div>
                        </div>
                    </form>
                </div>
            </main>
        </div>
    </div>
    <script src="<%= ResolveUrl("~/Scripts/webforms-student-layout.js") %>">
</script>
</body>
</html>

