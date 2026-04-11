<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected string StudentName = string.Empty;
    protected int CurrentWeek = 1;
    protected List<ClassSessions> AllSessions = new List<ClassSessions>();
    protected List<ClassSessions> WeeklySessions = new List<ClassSessions>();
    protected Dictionary<string, ClassSessions> MasterTimetable = new Dictionary<string, ClassSessions>();
    protected Dictionary<string, ClassSessions> WeeklyTimetable = new Dictionary<string, ClassSessions>();

    protected string[] DayNames = new[] { "", "周一", "周二", "周三", "周四", "周五", "周六", "周日" };
    protected string[] PeriodTimes = new[]
    {
        "08:40-09:25", "09:30-10:15", "10:35-11:20", "11:25-12:10",
        "13:20-14:05", "14:10-14:55", "15:15-16:00", "16:05-16:50",
        "17:30-18:15", "18:20-19:05", "19:10-19:55", "20:00-20:45"
    };

    protected void Page_Load(object sender, EventArgs e)
    {
        Response.Cache.SetCacheability(HttpCacheability.NoCache);
        Response.Cache.SetNoStore();
        Response.Cache.SetExpires(DateTime.UtcNow.AddMinutes(-1));
        Response.Cache.SetRevalidation(HttpCacheRevalidation.AllCaches);
        var currentUser = Session["User"] as Users;
        if (currentUser == null || currentUser.Role != 2)
        {
            Response.Redirect("~/Login.aspx", true);
            return;
        }

        if (!int.TryParse(Request.QueryString["selectedWeek"], out CurrentWeek) || CurrentWeek < 1 || CurrentWeek > 21)
        {
            CurrentWeek = 1;
        }

        using (var db = new StudentManagementDBEntities())
        {
            var student = db.Students.FirstOrDefault(s => s.UserID == currentUser.UserID);
            if (student == null)
            {
                Response.Redirect("~/Login.aspx", true);
                return;
            }

            StudentName = student.StudentName;

            var enrolledCourseIds = db.StudentCourses
                .Where(sc => sc.StudentID == student.StudentID)
                .Select(sc => sc.CourseID)
                .ToList();

            AllSessions = db.ClassSessions
                .Include("Courses")
                .Where(cs => enrolledCourseIds.Contains(cs.CourseID))
                .OrderBy(cs => cs.DayOfWeek)
                .ThenBy(cs => cs.StartPeriod)
                .ToList();

            WeeklySessions = AllSessions
                .Where(cs => CurrentWeek >= cs.StartWeek && CurrentWeek <= cs.EndWeek)
                .ToList();
        }

        BuildTimetableMap(AllSessions, MasterTimetable);
        BuildTimetableMap(WeeklySessions, WeeklyTimetable);
    }

    protected void BuildTimetableMap(List<ClassSessions> sessions, Dictionary<string, ClassSessions> map)
    {
        map.Clear();
        foreach (var session in sessions)
        {
            for (int period = session.StartPeriod; period <= session.EndPeriod; period++)
            {
                map[CellKey(session.DayOfWeek, period)] = session;
            }
        }
    }

    protected string Active(string page)
    {
        var current = VirtualPathUtility.GetFileName(Request.AppRelativeCurrentExecutionFilePath) ?? string.Empty;
        return current.Equals(page, StringComparison.OrdinalIgnoreCase) ? "active" : string.Empty;
    }

    protected string CellKey(int day, int period)
    {
        return day + "_" + period;
    }

    protected bool HasCell(Dictionary<string, ClassSessions> map, int day, int period)
    {
        return map.ContainsKey(CellKey(day, period));
    }

    protected ClassSessions GetCell(Dictionary<string, ClassSessions> map, int day, int period)
    {
        ClassSessions session;
        map.TryGetValue(CellKey(day, period), out session);
        return session;
    }

    protected string SafeCourseName(ClassSessions session)
    {
        return session != null && session.Courses != null ? session.Courses.CourseName : "-";
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
    <title>我的课表</title>
    <link href="<%= ResolveUrl("~/Content/bootstrap.min.css") %>" rel="stylesheet" />
    <link href="<%= ResolveUrl("~/Content/theme-system.css") %>" rel="stylesheet" />
    <link href="<%= ResolveUrl("~/Content/webforms-student-layout.css") %>" rel="stylesheet" />
    <style>
        .timetable-tabs {
            margin-bottom: 15px;
            display: flex;
            gap: 10px;
        }

        .timetable {
            min-width: 800px;
            table-layout: fixed;
        }

        .timetable th,
        .timetable td {
            vertical-align: middle !important;
            height: 80px;
            padding: 5px !important;
            text-align: center;
        }

        .timetable .has-class {
            background-color: #d9edf7;
            border: 1px solid #bce8f1;
            font-size: 13px;
            line-height: 1.5;
        }

        .view-card {
            background: #fff;
            border: 1px solid #d9d9d9;
            border-radius: 6px;
            padding: 10px;
        }
    </style>
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
                        <span class="username">欢迎您, <%= ((Session["User"] as Users)?.Username ?? "学生") %></span>
                        <span class="sep">|</span>
                        <a class="logout-link" href="../Logout.aspx">安全退出</a>
                    </div>
                </div>
            </header>

            <main class="content-body">
                <div class="container-fluid">
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <h2>我的课表</h2>
                        <button id="export-timetable-btn" class="btn btn-success" type="button">导出为图片</button>
                    </div>

                    <div class="timetable-tabs">
                        <button id="master-view-btn" class="btn btn-primary active" type="button">总课表</button>
                        <button id="weekly-view-btn" class="btn btn-default" type="button">周课表</button>
                    </div>
                    <hr />

                    <div id="weekly-view" style="display:none;">
                        <div class="view-card">
                            <form method="get" class="form-inline" style="margin-bottom: 12px;">
                                <div class="form-group">
                                    <label style="margin-right: 8px;">选择周数：</label>
                                    <select name="selectedWeek" class="form-control" style="width: 140px; display:inline-block; margin-right:8px;">
                                        <% for (int w = 1; w <= 21; w++) { %>
                                            <option value="<%= w %>" <%= w == CurrentWeek ? "selected" : "" %>>第 <%= w %> 周</option>
                                        <% } %>
                                    </select>
                                    <button type="submit" class="btn btn-primary">查询</button>
                                </div>
                            </form>

                            <div class="table-responsive">
                                <table class="table table-bordered timetable" id="weekly-timetable-table">
                                    <thead>
                                        <tr>
                                            <th style="width:120px;">时间</th>
                                            <% for (int day = 1; day <= 7; day++) { %>
                                                <th><%= DayNames[day] %></th>
                                            <% } %>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <% for (int period = 1; period <= 12; period++) { %>
                                            <tr>
                                                <td><strong>第 <%= period %> 节</strong><br /><small class="text-muted"><%= PeriodTimes[period - 1] %></small></td>
                                                <% for (int day = 1; day <= 7; day++) {
                                                       if (HasCell(WeeklyTimetable, day, period)) {
                                                           var session = GetCell(WeeklyTimetable, day, period);
                                                           if (session != null && session.StartPeriod == period) {
                                                               var rowspan = session.EndPeriod - session.StartPeriod + 1;
                                                %>
                                                    <td rowspan="<%= rowspan %>" class="has-class">
                                                        <strong><%= SafeCourseName(session) %></strong><br />
                                                        <small>(<%= session.StartWeek %>-<%= session.EndWeek %> 周)</small><br />
                                                        <small><%= session.Classroom %></small>
                                                    </td>
                                                <%         }
                                                       } else { %>
                                                    <td></td>
                                                <%     }
                                                   } %>
                                            </tr>
                                        <% } %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>

                    <div id="master-view">
                        <div class="view-card">
                            <div class="table-responsive">
                                <table class="table table-bordered timetable" id="master-timetable-table">
                                    <thead>
                                        <tr>
                                            <th style="width:120px;">时间</th>
                                            <% for (int day = 1; day <= 7; day++) { %>
                                                <th><%= DayNames[day] %></th>
                                            <% } %>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <% for (int period = 1; period <= 12; period++) { %>
                                            <tr>
                                                <td><strong>第 <%= period %> 节</strong><br /><small class="text-muted"><%= PeriodTimes[period - 1] %></small></td>
                                                <% for (int day = 1; day <= 7; day++) {
                                                       if (HasCell(MasterTimetable, day, period)) {
                                                           var session = GetCell(MasterTimetable, day, period);
                                                           if (session != null && session.StartPeriod == period) {
                                                               var rowspan = session.EndPeriod - session.StartPeriod + 1;
                                                %>
                                                    <td rowspan="<%= rowspan %>" class="has-class">
                                                        <strong><%= SafeCourseName(session) %></strong><br />
                                                        <small>(<%= session.StartWeek %>-<%= session.EndWeek %> 周)</small><br />
                                                        <small><%= session.Classroom %></small>
                                                    </td>
                                                <%         }
                                                       } else { %>
                                                    <td></td>
                                                <%     }
                                                   } %>
                                            </tr>
                                        <% } %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <script src="<%= ResolveUrl("~/Scripts/webforms-student-layout.js") %>"></script>
        <script src="<%= ResolveUrl("~/Scripts/jquery-3.7.1.min.js") %>"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
    <script>
        $(function () {
            $('#weekly-view-btn').on('click', function () {
                $('#master-view').hide();
                $('#weekly-view').show();
                $(this).removeClass('btn-default').addClass('btn-primary active');
                $('#master-view-btn').removeClass('btn-primary active').addClass('btn-default');
            });

            $('#master-view-btn').on('click', function () {
                $('#weekly-view').hide();
                $('#master-view').show();
                $(this).removeClass('btn-default').addClass('btn-primary active');
                $('#weekly-view-btn').removeClass('btn-primary active').addClass('btn-default');
            });

            var urlParams = new URLSearchParams(window.location.search);
            if (urlParams.has('selectedWeek')) {
                $('#weekly-view-btn').trigger('click');
            }

            $('#export-timetable-btn').on('click', function () {
                if (!window.html2canvas) {
                    alert('导出组件未加载成功，请稍后重试。');
                    return;
                }

                var activeTableId = $('#weekly-view').is(':visible') ? 'weekly-timetable-table' : 'master-timetable-table';
                var timetableElement = document.getElementById(activeTableId);
                var button = $(this);

                button.text('正在生成...').prop('disabled', true);
                html2canvas(timetableElement).then(function (canvas) {
                    var link = document.createElement('a');
                    link.download = '我的课表.png';
                    link.href = canvas.toDataURL('image/png');
                    link.click();
                    button.text('导出为图片').prop('disabled', false);
                }).catch(function () {
                    button.text('导出为图片').prop('disabled', false);
                    alert('导出失败，请重试。');
                });
            });
        });
    </script>
</body>
</html>






