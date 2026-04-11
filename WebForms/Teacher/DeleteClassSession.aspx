<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Helpers" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected ClassSessions CurrentSession;
    protected string MessageType = string.Empty;
    protected string MessageText = string.Empty;
    protected int SessionId = 0;
    protected string[] DayNames = { "", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日" };
    protected string[] PeriodTimes = { "08:40-09:25", "09:30-10:15", "10:35-11:20", "11:25-12:10", "13:20-14:05", "14:10-14:55", "15:15-16:00", "16:05-16:50", "17:30-18:15", "18:20-19:05", "19:10-19:55", "20:00-20:45" };

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
            int.TryParse(Request.Form["id"], out SessionId);
        }
        else
        {
            int.TryParse(Request.QueryString["id"], out SessionId);
        }

        if (SessionId <= 0)
        {
            MessageType = "danger";
            MessageText = "无效的课程安排参数。";
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
            CurrentSession = db.ClassSessions.Include("Courses").FirstOrDefault(cs => cs.SessionID == SessionId);

            if (CurrentSession == null || !taughtCourseIds.Contains(CurrentSession.CourseID))
            {
                CurrentSession = null;
                MessageType = "danger";
                MessageText = "课程安排不存在或不属于当前教师。";
                return;
            }

            if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
            {
                var courseName = CurrentSession.Courses == null ? "课程" : CurrentSession.Courses.CourseName;
                var scheduleInfo = "第" + CurrentSession.StartWeek + "-" + CurrentSession.EndWeek + "周，" + DayText(CurrentSession.DayOfWeek) + "第" + CurrentSession.StartPeriod + "-" + CurrentSession.EndPeriod + "节，" + CurrentSession.Classroom + "教室";

                db.ClassSessions.Remove(CurrentSession);
                db.SaveChanges();

                var msg = "课程安排删除成功！已删除 " + courseName + " 的安排：" + scheduleInfo;
                Response.Redirect("ManageClassSessions.aspx?msg=" + Server.UrlEncode(msg), true);
            }
        }
    }

    protected string DayText(int day)
    {
        return day >= 1 && day <= 7 ? DayNames[day] : "未知";
    }

    protected string TimeRange(ClassSessions s)
    {
        var start = s.StartPeriod >= 1 && s.StartPeriod <= 12 ? PeriodTimes[s.StartPeriod - 1].Split('-')[0] : "";
        var end = s.EndPeriod >= 1 && s.EndPeriod <= 12 ? PeriodTimes[s.EndPeriod - 1].Split('-')[1] : "";
        return start + " - " + end;
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
    <title>删除课程安排</title>
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
                    <h2>删除课程安排</h2>
                    <hr />

                    <% if (!string.IsNullOrEmpty(MessageText)) { %>
                        <div class="alert alert-<%= MessageType %>"><%= MessageText %></div>
                    <% } %>

                    <% if (CurrentSession != null) { %>
                        <div class="alert alert-danger">
                            <h4>确认删除</h4>
                            <p>您确定要删除以下课程安排吗？此操作无法撤销。</p>
                        </div>

                        <div class="panel panel-default">
                            <div class="panel-heading"><h4 class="panel-title">课程安排详情</h4></div>
                            <div class="panel-body">
                                <dl class="dl-horizontal">
                                    <dt>课程名称：</dt><dd><strong><%= CurrentSession.Courses == null ? "-" : CurrentSession.Courses.CourseName %></strong></dd>
                                    <dt>周次范围：</dt><dd>第 <%= CurrentSession.StartWeek %> - <%= CurrentSession.EndWeek %> 周</dd>
                                    <dt>上课时间：</dt><dd><%= DayText(CurrentSession.DayOfWeek) %> 第 <%= CurrentSession.StartPeriod %> - <%= CurrentSession.EndPeriod %> 节<br /><small class="text-muted">(<%= TimeRange(CurrentSession) %>)</small></dd>
                                    <dt>教室：</dt><dd><%= CurrentSession.Classroom %></dd>
                                </dl>
                            </div>
                        </div>

                        <form method="post">
                            <input type="hidden" name="id" value="<%= SessionId %>" />
                            <button type="submit" class="btn btn-danger" onclick="return confirm('您确定要删除这个课程安排吗？此操作无法撤销！');">确认删除</button>
                            <a class="btn btn-default" href="ManageClassSessions.aspx">取消</a>
                        </form>
                    <% } else { %>
                        <a class="btn btn-default" href="ManageClassSessions.aspx">返回安排管理</a>
                    <% } %>
                </div>
            </main>
        </div>
    </div>
    <script src="<%= ResolveUrl("~/Scripts/webforms-student-layout.js") %>"></script>
</body>
</html>

