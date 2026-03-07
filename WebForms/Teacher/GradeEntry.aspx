<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected int CourseId = 0;
    protected Courses CurrentCourse;
    protected List<StudentCourses> Enrollments = new List<StudentCourses>();
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

        if (!int.TryParse(Request.QueryString["courseId"], out CourseId) || CourseId <= 0)
        {
            MessageType = "danger";
            MessageText = "参数 courseId 无效。";
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

            CurrentCourse = db.Courses.Include("Teachers").FirstOrDefault(c => c.CourseID == CourseId && c.TeacherID == teacher.TeacherID);
            if (CurrentCourse == null)
            {
                MessageType = "danger";
                MessageText = "课程不存在或不属于当前教师。";
                return;
            }

            if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
            {
                var studentIds = Request.Form.GetValues("studentIds");
                var grades = Request.Form.GetValues("grades");
                if (studentIds != null && grades != null && studentIds.Length == grades.Length)
                {
                    for (int i = 0; i < studentIds.Length; i++)
                    {
                        var studentId = (studentIds[i] ?? string.Empty).Trim();
                        var gradeText = (grades[i] ?? string.Empty).Trim();

                        float? parsedGrade = null;
                        if (!string.IsNullOrEmpty(gradeText))
                        {
                            float g;
                            var ok = float.TryParse(gradeText, NumberStyles.Float, CultureInfo.CurrentCulture, out g)
                                || float.TryParse(gradeText, NumberStyles.Float, CultureInfo.InvariantCulture, out g);
                            if (ok)
                            {
                                if (g < 0f || g > 100f)
                                {
                                    MessageType = "danger";
                                    MessageText = "成绩必须在 0-100 之间。";
                                    break;
                                }
                                parsedGrade = g;
                            }
                            else
                            {
                                MessageType = "danger";
                                MessageText = "存在无法识别的成绩数值，请检查后重试。";
                                break;
                            }
                        }

                        var enrollment = db.StudentCourses.FirstOrDefault(sc => sc.StudentID == studentId && sc.CourseID == CourseId);
                        if (enrollment != null)
                        {
                            enrollment.Grade = parsedGrade;
                        }
                    }

                    if (string.IsNullOrEmpty(MessageText))
                    {
                        db.SaveChanges();
                        MessageType = "success";
                        MessageText = "成绩保存成功。";
                    }
                }
                else
                {
                    MessageType = "danger";
                    MessageText = "提交数据不完整，请刷新页面后重试。";
                }
            }

            Enrollments = db.StudentCourses
                .Include("Students")
                .Where(sc => sc.CourseID == CourseId)
                .OrderBy(sc => sc.Students.StudentID)
                .ToList();
        }
    }

    protected string Active(string page)
    {
        var current = VirtualPathUtility.GetFileName(Request.AppRelativeCurrentExecutionFilePath) ?? string.Empty;
        return current.Equals(page, StringComparison.OrdinalIgnoreCase) ? "active" : string.Empty;
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
    <title>成绩录入</title>
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
                    <% if (!string.IsNullOrEmpty(MessageText)) { %>
                        <div class="alert alert-<%= MessageType %>"><%= MessageText %></div>
                    <% } %>

                    <% if (CurrentCourse != null) { %>
                        <h2>为课程 “<%= CurrentCourse.CourseName %>” 录入成绩</h2>
                        <hr />
                        <form method="post">
                            <div class="table-responsive">
                                <table class="table table-striped table-bordered">
                                    <thead>
                                        <tr>
                                            <th>学号</th>
                                            <th>姓名</th>
                                            <th>成绩 (0-100)</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <% if (Enrollments.Any()) { %>
                                            <% foreach (var item in Enrollments) { %>
                                                <tr>
                                                    <td>
                                                        <%= item.Students == null ? "-" : item.Students.StudentID %>
                                                        <input type="hidden" name="studentIds" value="<%= item.Students == null ? "" : item.Students.StudentID %>" />
                                                    </td>
                                                    <td><%= item.Students == null ? "-" : item.Students.StudentName %></td>
                                                    <td>
                                                        <input type="number" name="grades" value="<%= item.Grade.HasValue ? item.Grade.Value.ToString("0.##", CultureInfo.InvariantCulture) : "" %>" class="form-control" min="0" max="100" step="0.1" />
                                                    </td>
                                                </tr>
                                            <% } %>
                                        <% } else { %>
                                            <tr><td colspan="3" class="text-center text-muted">该课程暂无选课学生。</td></tr>
                                        <% } %>
                                    </tbody>
                                </table>
                            </div>
                            <div class="form-group" style="margin-top: 12px;">
                                <button type="submit" class="btn btn-success">保存全部成绩</button>
                                <a class="btn btn-default" href="CourseList.aspx">返回列表</a>
                            </div>
                        </form>
                    <% } else { %>
                        <a class="btn btn-default" href="CourseList.aspx">返回课程列表</a>
                    <% } %>
                </div>
            </main>
        </div>
    </div>
    <script src="<%= ResolveUrl("~/Scripts/webforms-student-layout.js") %>"></script>
</body>
</html>

