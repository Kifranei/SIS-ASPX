<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Helpers" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected List<ClassSessions> Sessions = new List<ClassSessions>();
    protected Dictionary<int, string> HolidayDescriptions = new Dictionary<int, string>();
    protected List<int> HolidayWeeks = new List<int>();
    protected string FlashMessage = string.Empty;
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

        FlashMessage = (Request.QueryString["msg"] ?? string.Empty).Trim();
        HolidayDescriptions = HolidayHelper.GetHolidayWeekDescriptions();
        HolidayWeeks = HolidayHelper.GetCurrentSemesterHolidayWeeks();

        using (var db = new StudentManagementDBEntities())
        {
            var teacher = db.Teachers.FirstOrDefault(t => t.UserID == currentUser.UserID);
            if (teacher == null)
            {
                Response.Redirect("~/Login.aspx", true);
                return;
            }

            var taughtCourseIds = db.Courses.Where(c => c.TeacherID == teacher.TeacherID).Select(c => c.CourseID).ToList();
            Sessions = db.ClassSessions
                .Include("Courses")
                .Where(cs => taughtCourseIds.Contains(cs.CourseID))
                .OrderBy(cs => cs.Courses.CourseName)
                .ThenBy(cs => cs.StartWeek)
                .ThenBy(cs => cs.DayOfWeek)
                .ThenBy(cs => cs.StartPeriod)
                .ToList();
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
    <title>课程安排管理</title>
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
                    <% if (!string.IsNullOrEmpty(FlashMessage)) { %>
                        <div class="alert alert-success"><%= Server.HtmlEncode(FlashMessage) %></div>
                    <% } %>

                    <div style="display:flex;justify-content:space-between;align-items:center;">
                        <h2>课程安排管理</h2>
                        <div>
                            <a class="btn btn-primary" href="AddClassSession.aspx">添加新安排</a>
                            <a class="btn btn-default" href="Timetable.aspx">返回课表</a>
                        </div>
                    </div>
                    <hr />

                    <% if (HolidayDescriptions.Any()) { %>
                        <div class="alert alert-info">
                            <h5>本学期法定假日提醒</h5>
                            <p>
                                <% foreach (var holiday in HolidayDescriptions) { %>
                                    <span class="label label-warning" style="margin-right:8px;">第<%= holiday.Key %>周：<%= holiday.Value %></span>
                                <% } %>
                            </p>
                        </div>
                    <% } %>

                    <% if (Sessions.Any()) { %>
                        <div class="table-responsive">
                            <table class="table table-striped table-hover table-bordered">
                                <thead>
                                    <tr>
                                        <th>课程名称</th>
                                        <th>周次范围</th>
                                        <th>上课时间</th>
                                        <th>教室</th>
                                        <th>假日状态</th>
                                        <th>操作</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% foreach (var s in Sessions) {
                                           var conflicts = new List<int>();
                                           for (int w = s.StartWeek; w <= s.EndWeek; w++) {
                                               if (HolidayWeeks.Contains(w)) { conflicts.Add(w); }
                                           }
                                    %>
                                        <tr>
                                            <td><strong><%= s.Courses == null ? "-" : s.Courses.CourseName %></strong></td>
                                            <td><span class="label label-info">第 <%= s.StartWeek %> - <%= s.EndWeek %> 周</span></td>
                                            <td>
                                                <%= DayText(s.DayOfWeek) %> 第 <%= s.StartPeriod %> - <%= s.EndPeriod %> 节<br />
                                                <small class="text-muted"><%= TimeRange(s) %></small>
                                            </td>
                                            <td><span class="label label-default"><%= s.Classroom %></span></td>
                                            <td>
                                                <% if (conflicts.Any()) { %>
                                                    <span class="label label-warning">含假日</span><br />
                                                    <small class="text-muted">第<%= string.Join("、", conflicts) %>周</small>
                                                <% } else { %>
                                                    <span class="label label-success">正常</span>
                                                <% } %>
                                            </td>
                                            <td>
                                                <div class="btn-group btn-group-sm">
                                                    <a class="btn btn-warning" href="AdjustClass.aspx?sessionId=<%= s.SessionID %>">调整</a>
                                                    <a class="btn btn-danger" href="DeleteClassSession.aspx?id=<%= s.SessionID %>">删除</a>
                                                </div>
                                            </td>
                                        </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    <% } else { %>
                        <div class="well text-center">
                            <h4>暂无课程安排</h4>
                            <p class="text-muted">您还没有添加任何课程安排。</p>
                            <a class="btn btn-primary" href="AddClassSession.aspx">立即添加</a>
                        </div>
                    <% } %>
                </div>
            </main>
        </div>
    </div>
    <script src="<%= ResolveUrl("~/Scripts/webforms-student-layout.js") %>"></script>
</body>
</html>

