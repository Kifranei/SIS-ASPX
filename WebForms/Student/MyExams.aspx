<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected List<Exams> MyExamList = new List<Exams>();

    protected void Page_Load(object sender, EventArgs e)
    {
        var currentUser = Session["User"] as Users;
        if (currentUser == null || currentUser.Role != 2)
        {
            Response.Redirect("~/Login.aspx", true);
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            var student = db.Students.FirstOrDefault(s => s.UserID == currentUser.UserID);
            if (student == null)
            {
                Response.Redirect("~/Login.aspx", true);
                return;
            }

            var enrolledCourseIds = db.StudentCourses
                .Where(sc => sc.StudentID == student.StudentID)
                .Select(sc => sc.CourseID)
                .ToList();

            MyExamList = db.Exams
                .Include("Courses")
                .Where(e => enrolledCourseIds.Contains(e.CourseID))
                .OrderBy(e => e.ExamTime)
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
    <title>我的考试</title>
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
                <li><a class="<%= Active("Index.aspx") %>" href="Index.aspx">个人中心</a></li>
                <li><a class="<%= Active("Timetable.aspx") %>" href="Timetable.aspx">我的课表</a></li>
                <li><a class="<%= Active("CourseSelection.aspx") %>" href="CourseSelection.aspx">在线选课</a></li>
                <li><a class="<%= Active("MyExams.aspx") %>" href="MyExams.aspx">我的考试</a></li>
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
                        <span class="username">欢迎您, <%= (Session["DisplayName"] as string) ?? ((Session["User"] as Users)?.Username ?? "学生") %></span>
                        <span class="sep">|</span>
                        <a class="logout-link" href="../Logout.aspx">安全退出</a>
                    </div>
                </div>
            </header>
            <main class="content-body">
                <div class="container-fluid">
        <h2>我的考试安排</h2>
        <div class="table-responsive">
            <table class="table table-striped bg-white">
                <thead>
                    <tr>
                        <th>课程名称</th>
                        <th>考试时间</th>
                        <th>考试地点</th>
                        <th>备注</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (MyExamList.Any()) { foreach (var e in MyExamList) { %>
                        <tr>
                            <td><%= e.Courses == null ? "-" : e.Courses.CourseName %></td>
                            <td><%= e.ExamTime %></td>
                            <td><%= e.Location %></td>
                            <td><%= e.Details %></td>
                        </tr>
                    <% } } else { %>
                        <tr><td colspan="4" class="text-center text-muted py-4">暂无考试安排</td></tr>
                    <% } %>
                </tbody>
            </table>
        </div>
                    </div>
            </main>
        </div>
    </div>
    <script src="<%= ResolveUrl("~/Scripts/webforms-student-layout.js") %>"></script>
    </body>
</html>













