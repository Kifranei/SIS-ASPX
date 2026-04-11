<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected List<Exams> ExamsList = new List<Exams>();
    protected string FlashMessage = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        var currentUser = Session["User"] as Users;
        if (currentUser == null || currentUser.Role != 1)
        {
            Response.Redirect("~/Login.aspx", true);
            return;
        }

        FlashMessage = (Request.QueryString["msg"] ?? string.Empty).Trim();

        using (var db = new StudentManagementDBEntities())
        {
            var teacher = db.Teachers.FirstOrDefault(t => t.UserID == currentUser.UserID);
            if (teacher == null)
            {
                Response.Redirect("~/Login.aspx", true);
                return;
            }

            var taughtCourseIds = db.Courses.Where(c => c.TeacherID == teacher.TeacherID).Select(c => c.CourseID).ToList();
            ExamsList = db.Exams.Include("Courses")
                .Where(ei => taughtCourseIds.Contains(ei.CourseID))
                .OrderBy(ei => ei.ExamTime)
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
    <title>考试安排列表</title>
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
                    <% if (!string.IsNullOrEmpty(FlashMessage)) { %>
                        <div class="alert alert-success"><%= Server.HtmlEncode(FlashMessage) %></div>
                    <% } %>

                    <h2>考试安排列表</h2>
                    <p><a class="btn btn-primary" href="AddExam.aspx">添加新考试</a></p>

                    <div class="table-responsive">
                        <table class="table table-striped table-bordered">
                            <thead>
                                <tr>
                                    <th>课程名称</th>
                                    <th>考试时间</th>
                                    <th>考试地点</th>
                                    <th>操作</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (ExamsList.Any()) { %>
                                    <% foreach (var item in ExamsList) { %>
                                        <tr>
                                            <td><%= item.Courses == null ? "-" : item.Courses.CourseName %></td>
                                            <td><%= item.ExamTime.ToString("yyyy-MM-dd HH:mm") %></td>
                                            <td><%= item.Location %></td>
                                            <td>
                                                <a href="EditExam.aspx?id=<%= item.ExamID %>">编辑</a> |
                                                <a href="DetailsExam.aspx?id=<%= item.ExamID %>">详情</a> |
                                                <a href="DeleteExam.aspx?id=<%= item.ExamID %>">删除</a>
                                            </td>
                                        </tr>
                                    <% } %>
                                <% } else { %>
                                    <tr><td colspan="4" class="text-center text-muted">暂无考试安排。</td></tr>
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

