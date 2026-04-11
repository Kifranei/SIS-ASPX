<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected string TeacherName = string.Empty;
    protected List<ClassSessions> TodaysClasses = new List<ClassSessions>();
    protected string[] PeriodTimes = new[] { "08:40-09:25", "09:30-10:15", "10:35-11:20", "11:25-12:10", "13:20-14:05", "14:10-14:55", "15:15-16:00", "16:05-16:50", "17:30-18:15", "18:20-19:05", "19:10-19:55", "20:00-20:45" };

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

            TeacherName = teacher.TeacherName;

            int dayOfWeek = (int)DateTime.Now.DayOfWeek;
            int ourDayOfWeek = dayOfWeek == 0 ? 7 : dayOfWeek;

            var taughtCourseIds = db.Courses
                .Where(c => c.TeacherID == teacher.TeacherID)
                .Select(c => c.CourseID)
                .ToList();

            TodaysClasses = db.ClassSessions
                .Include("Courses")
                .Where(cs => taughtCourseIds.Contains(cs.CourseID) && cs.DayOfWeek == ourDayOfWeek)
                .OrderBy(cs => cs.StartPeriod)
                .ToList();
        }
    }

    protected string Active(string page)
    {
        var current = VirtualPathUtility.GetFileName(Request.AppRelativeCurrentExecutionFilePath) ?? string.Empty;
        return current.Equals(page, StringComparison.OrdinalIgnoreCase) ? "active" : string.Empty;
    }

    protected string GetTimeRange(ClassSessions session)
    {
        var start = Math.Max(1, session.StartPeriod);
        var end = Math.Min(12, session.EndPeriod);
        return PeriodTimes[start - 1] + " - " + PeriodTimes[end - 1];
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
    <title>教师工作台</title>
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
                        <span class="username">欢迎您, <%= (Session["DisplayName"] as string) ?? ((Session["User"] as Users)?.Username ?? "教师") %></span>
                        <span class="sep">|</span>
                        <a class="logout-link" href="../Logout.aspx">安全退出</a>
                    </div>
                </div>
            </header>
            <main class="content-body">
                <div class="container-fluid">
                    <div class="mb-4">
                        <h2><%= TeacherName %> 老师，欢迎回来！</h2>
                        <p class="text-muted">今天是 <%= DateTime.Now.ToString("yyyy年MM月dd日, dddd") %></p>
                    </div>

                    <div class="row g-3">
                        <div class="col-md-8">
                            <div class="card h-100">
                                <div class="card-header bg-primary text-white">今日授课安排</div>
                                <div class="card-body">
                                    <% if (TodaysClasses.Any()) { %>
                                        <ul class="list-group">
                                            <% foreach (var session in TodaysClasses) { %>
                                                <li class="list-group-item">
                                                    <strong><%= session.Courses == null ? "-" : session.Courses.CourseName %></strong><br />
                                                    <small>
                                                        时间：第 <%= session.StartPeriod %>-<%= session.EndPeriod %> 节（<%= GetTimeRange(session) %>）<br />
                                                        地点：<%= session.Classroom %>
                                                    </small>
                                                </li>
                                            <% } %>
                                        </ul>
                                    <% } else { %>
                                        <div class="text-center py-5"><h5>您今天没有课程安排，祝您工作愉快！</h5></div>
                                    <% } %>
                                </div>
                            </div>
                        </div>

                        <div class="col-md-4">
                            <div class="list-group">
                                <a href="Timetable.aspx" class="list-group-item list-group-item-action">
                                    <h5 class="mb-1">我的完整课表</h5>
                                    <p class="mb-1 text-muted">查看并管理所有周的课程安排。</p>
                                </a>
                                <a href="CourseList.aspx" class="list-group-item list-group-item-action">
                                    <h5 class="mb-1">进入成绩录入</h5>
                                    <p class="mb-1 text-muted">为您的课程录入和修改学生成绩。</p>
                                </a>
                                <a href="ExamList.aspx" class="list-group-item list-group-item-action">
                                    <h5 class="mb-1">考试安排管理</h5>
                                    <p class="mb-1 text-muted">创建、编辑和删除您的课程考试安排。</p>
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    </div>
    <script src="<%= ResolveUrl("~/Scripts/webforms-student-layout.js") %>"></script>
</body>
</html>

