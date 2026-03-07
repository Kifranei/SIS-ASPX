<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Helpers" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected int CurrentWeek = 1;
    protected List<ClassSessions> AllSessions = new List<ClassSessions>();
    protected List<ClassSessions> WeeklySessions = new List<ClassSessions>();
    protected Dictionary<string, ClassSessions> MasterTimetable = new Dictionary<string, ClassSessions>();
    protected Dictionary<string, ClassSessions> WeeklyTimetable = new Dictionary<string, ClassSessions>();
    protected Dictionary<int, string> HolidayDescriptions = new Dictionary<int, string>();
    protected string FlashMessage = string.Empty;

    protected string[] DayNames = new[] { "", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日" };
    protected string[] PeriodTimes = new[]
    {
        "08:40-09:25", "09:30-10:15", "10:35-11:20", "11:25-12:10",
        "13:20-14:05", "14:10-14:55", "15:15-16:00", "16:05-16:50",
        "17:30-18:15", "18:20-19:05", "19:10-19:55", "20:00-20:45"
    };

    protected void Page_Load(object sender, EventArgs e)
    {
        var currentUser = Session["User"] as Users;
        if (currentUser == null || currentUser.Role != 1)
        {
            Response.Redirect("~/Login.aspx", true);
            return;
        }

        if (!int.TryParse(Request.QueryString["selectedWeek"], out CurrentWeek) || CurrentWeek < 1 || CurrentWeek > 21)
        {
            CurrentWeek = 1;
        }

        FlashMessage = (Request.QueryString["msg"] ?? string.Empty).Trim();
        HolidayDescriptions = HolidayHelper.GetHolidayWeekDescriptions();

        using (var db = new StudentManagementDBEntities())
        {
            var teacher = db.Teachers.FirstOrDefault(t => t.UserID == currentUser.UserID);
            if (teacher == null)
            {
                Response.Redirect("~/Login.aspx", true);
                return;
            }

            var taughtCourseIds = db.Courses
                .Where(c => c.TeacherID == teacher.TeacherID)
                .Select(c => c.CourseID)
                .ToList();

            AllSessions = db.ClassSessions
                .Include("Courses")
                .Where(cs => taughtCourseIds.Contains(cs.CourseID))
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

    protected bool IsHolidayWeek(int week)
    {
        return HolidayHelper.IsHolidayWeek(week);
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
        .timetable-tabs { margin-bottom: 15px; display: flex; gap: 10px; }
        .timetable { min-width: 900px; table-layout: fixed; }
        .timetable th, .timetable td { vertical-align: middle !important; height: 80px; padding: 5px !important; text-align: center; }
        .timetable .has-class { background-color: #d9edf7; border: 1px solid #bce8f1; font-size: 13px; line-height: 1.5; }
        .holiday-week { background-color: #f2dede !important; border: 2px solid #d9534f !important; color: #a94442; }
        .holiday-notice { padding: 20px 10px; text-align: center; }
        .view-card { background: #fff; border: 1px solid #d9d9d9; border-radius: 6px; padding: 10px; }
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

                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <h2>我的课表</h2>
                        <div>
                            <a class="btn btn-primary" href="AddClassSession.aspx" style="margin-right: 5px;">添加课程安排</a>
                            <a class="btn btn-info" href="ManageClassSessions.aspx" style="margin-right: 5px;">管理安排</a>
                            <a class="btn btn-warning" href="CourseStudentManage.aspx" style="margin-right: 10px;">课程学生管理</a>
                            <label class="checkbox-inline" style="margin-right: 15px;">
                                <input type="checkbox" id="toggle-adjust-btn" /> 隐藏调课按钮
                            </label>
                            <button id="export-timetable-btn" class="btn btn-success" type="button">导出为图片</button>
                        </div>
                    </div>

                    <% if (HolidayDescriptions.Any()) { %>
                        <div class="alert alert-info" style="margin-top: 15px;">
                            <h5>本学期法定假日提醒</h5>
                            <p>
                                <% foreach (var holiday in HolidayDescriptions) { %>
                                    <span class="label label-warning" style="margin-right: 8px;">第<%= holiday.Key %>周：<%= holiday.Value %></span>
                                <% } %>
                            </p>
                            <small class="text-muted">假日周次将自动从课表中排除，不会显示课程安排。</small>
                        </div>
                    <% } %>

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

                            <% if (IsHolidayWeek(CurrentWeek)) { %>
                                <div style="margin-bottom: 10px;">
                                    <span class="label label-danger">第<%= CurrentWeek %>周为法定假日（无课）</span>
                                </div>
                            <% } %>

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
                                                       if (IsHolidayWeek(CurrentWeek)) {
                                                           if (period == 1) { %>
                                                                <td rowspan="12" class="holiday-week">
                                                                    <div class="holiday-notice">
                                                                        <strong>法定假日</strong><br />
                                                                        <small>本周无课</small>
                                                                    </div>
                                                                </td>
                                                           <% }
                                                           continue;
                                                       }

                                                       if (HasCell(WeeklyTimetable, day, period)) {
                                                           var session = GetCell(WeeklyTimetable, day, period);
                                                           if (session != null && session.StartPeriod == period) {
                                                               var rowspan = session.EndPeriod - session.StartPeriod + 1;
                                                %>
                                                    <td rowspan="<%= rowspan %>" class="has-class">
                                                        <strong><%= SafeCourseName(session) %></strong><br />
                                                        <small>(<%= session.StartWeek %>-<%= session.EndWeek %> 周)</small><br />
                                                        <small><%= session.Classroom %></small>
                                                        <hr style="margin: 5px 0;" class="adjust-class-hr" />
                                                        <a class="btn btn-warning btn-xs adjust-class-btn" href="AdjustClass.aspx?sessionId=<%= session.SessionID %>">调课</a>
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
                                                        <hr style="margin: 5px 0;" class="adjust-class-hr" />
                                                        <a class="btn btn-warning btn-xs adjust-class-btn" href="AdjustClass.aspx?sessionId=<%= session.SessionID %>">调课</a>
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

                    <% if (!AllSessions.Any()) { %>
                        <div class="well text-center" style="margin-top: 30px;">
                            <h4>暂无课程安排</h4>
                            <p class="text-muted">您还没有添加任何课程安排。点击上方的“添加课程安排”按钮开始创建。</p>
                            <a class="btn btn-primary btn-lg" href="AddClassSession.aspx">立即添加</a>
                        </div>
                    <% } %>
                </div>
            </main>
        </div>
    </div>

    <script src="<%= ResolveUrl("~/Scripts/webforms-student-layout.js") %>"></script>
    <script src="<%= ResolveUrl("~/Scripts/jquery-3.7.1.min.js") %>"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
    <script>
        $(function () {
            $('#toggle-adjust-btn').on('change', function () {
                if ($(this).is(':checked')) {
                    $('.adjust-class-btn, .adjust-class-hr').hide();
                } else {
                    $('.adjust-class-btn, .adjust-class-hr').show();
                }
            });

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
                var adjustElements = $('.adjust-class-btn, .adjust-class-hr');
                var wereVisible = adjustElements.is(':visible');

                button.text('正在生成...').prop('disabled', true);
                if (wereVisible) {
                    adjustElements.hide();
                }

                html2canvas(timetableElement).then(function (canvas) {
                    var link = document.createElement('a');
                    link.download = '我的课表.png';
                    link.href = canvas.toDataURL('image/png');
                    link.click();
                }).catch(function () {
                    alert('导出失败，请重试。');
                }).finally(function () {
                    button.text('导出为图片').prop('disabled', false);
                    if (wereVisible) {
                        adjustElements.show();
                    }
                });
            });
        });
    </script>
</body>
</html>


