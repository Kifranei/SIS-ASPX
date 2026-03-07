<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected Exams CurrentExam;
    protected string MessageType = string.Empty;
    protected string MessageText = string.Empty;
    protected int ExamId = 0;

    protected void Page_Load(object sender, EventArgs e)
    {
        var currentUser = Session["User"] as Users;
        if (currentUser == null || currentUser.Role != 1)
        {
            Response.Redirect("~/Login.aspx", true);
            return;
        }

        if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
        {
            int.TryParse(Request.Form["id"], out ExamId);
        }
        else
        {
            int.TryParse(Request.QueryString["id"], out ExamId);
        }

        if (ExamId <= 0)
        {
            MessageType = "danger";
            MessageText = "无效的考试参数。";
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

            var taughtCourseIds = db.Courses.Where(c => c.TeacherID == teacher.TeacherID).Select(c => c.CourseID).ToList();
            CurrentExam = db.Exams.Include("Courses").FirstOrDefault(ei => ei.ExamID == ExamId);
            if (CurrentExam == null || !taughtCourseIds.Contains(CurrentExam.CourseID))
            {
                CurrentExam = null;
                MessageType = "danger";
                MessageText = "考试记录不存在或不属于当前教师。";
                return;
            }

            if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
            {
                db.Exams.Remove(CurrentExam);
                db.SaveChanges();
                Response.Redirect("ExamList.aspx?msg=" + Server.UrlEncode("考试安排删除成功。"), true);
            }
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
    <title>删除考试</title>
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
                    <h2>删除考试</h2>

                    <% if (!string.IsNullOrEmpty(MessageText)) { %>
                        <div class="alert alert-<%= MessageType %>"><%= MessageText %></div>
                    <% } %>

                    <% if (CurrentExam != null) { %>
                        <h3>您确定要删除这条考试安排吗？</h3>
                        <div>
                            <h4><%= CurrentExam.Courses == null ? "-" : CurrentExam.Courses.CourseName %></h4>
                            <hr />
                            <dl class="dl-horizontal">
                                <dt>课程名称</dt>
                                <dd><%= CurrentExam.Courses == null ? "-" : CurrentExam.Courses.CourseName %></dd>
                                <dt>考试时间</dt>
                                <dd><%= CurrentExam.ExamTime.ToString("yyyy-MM-dd HH:mm") %></dd>
                                <dt>考试地点</dt>
                                <dd><%= CurrentExam.Location %></dd>
                            </dl>
                            <form method="post">
                                <input type="hidden" name="id" value="<%= ExamId %>" />
                                <button type="submit" class="btn btn-danger">确认删除</button>
                                <a class="btn btn-default" href="ExamList.aspx">返回列表</a>
                            </form>
                        </div>
                    <% } else { %>
                        <a class="btn btn-default" href="ExamList.aspx">返回列表</a>
                    <% } %>
                </div>
            </main>
        </div>
    </div>
    <script src="<%= ResolveUrl("~/Scripts/webforms-student-layout.js") %>"></script>
</body>
</html>

