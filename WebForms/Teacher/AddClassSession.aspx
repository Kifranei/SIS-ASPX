<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Helpers" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected List<Courses> TeacherCourses = new List<Courses>();
    protected Dictionary<int, string> HolidayDescriptions = new Dictionary<int, string>();
    protected string MessageType = string.Empty;
    protected string MessageText = string.Empty;

    protected int FormCourseId = 0;
    protected int FormStartWeek = 1;
    protected int FormEndWeek = 1;
    protected int FormDayOfWeek = 1;
    protected int FormStartPeriod = 1;
    protected int FormEndPeriod = 1;
    protected string FormClassroom = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        var currentUser = Session["User"] as Users;
        if (currentUser == null || currentUser.Role != 1)
        {
            Response.Redirect("~/Login.aspx", true);
            return;
        }

        HolidayDescriptions = HolidayHelper.GetHolidayWeekDescriptions();

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
            int.TryParse(Request.Form["StartWeek"], out FormStartWeek);
            int.TryParse(Request.Form["EndWeek"], out FormEndWeek);
            int.TryParse(Request.Form["DayOfWeek"], out FormDayOfWeek);
            int.TryParse(Request.Form["StartPeriod"], out FormStartPeriod);
            int.TryParse(Request.Form["EndPeriod"], out FormEndPeriod);
            FormClassroom = (Request.Form["Classroom"] ?? string.Empty).Trim();

            if (!TeacherCourses.Any(c => c.CourseID == FormCourseId))
            {
                MessageType = "danger";
                MessageText = "您只能为自己教授的课程添加安排。";
                return;
            }

            if (FormStartWeek < 1 || FormEndWeek > 21 || FormStartWeek > FormEndWeek)
            {
                MessageType = "danger";
                MessageText = "周次范围不合法。";
                return;
            }

            if (FormDayOfWeek < 1 || FormDayOfWeek > 7)
            {
                MessageType = "danger";
                MessageText = "星期参数不合法。";
                return;
            }

            if (FormStartPeriod < 1 || FormEndPeriod > 12 || FormStartPeriod > FormEndPeriod)
            {
                MessageType = "danger";
                MessageText = "节次范围不合法。";
                return;
            }

            if (string.IsNullOrWhiteSpace(FormClassroom))
            {
                MessageType = "danger";
                MessageText = "请填写教室。";
                return;
            }

            var taughtCourseIds = TeacherCourses.Select(c => c.CourseID).ToList();
            var conflictingSessions = db.ClassSessions.Include("Courses")
                .Where(cs => taughtCourseIds.Contains(cs.CourseID)
                           && cs.DayOfWeek == FormDayOfWeek
                           && !(FormEndWeek < cs.StartWeek || FormStartWeek > cs.EndWeek)
                           && !(FormEndPeriod < cs.StartPeriod || FormStartPeriod > cs.EndPeriod))
                .ToList();

            if (conflictingSessions.Any())
            {
                var conflictDescription = string.Join("；", conflictingSessions.Select(cs =>
                    (cs.Courses == null ? "课程" : cs.Courses.CourseName) + "(第" + cs.StartWeek + "-" + cs.EndWeek + "周, 第" + cs.StartPeriod + "-" + cs.EndPeriod + "节)"));
                MessageType = "danger";
                MessageText = "时间冲突！您在该时间段已有以下课程安排：" + conflictDescription;
                return;
            }

            var session = new ClassSessions
            {
                CourseID = FormCourseId,
                StartWeek = FormStartWeek,
                EndWeek = FormEndWeek,
                DayOfWeek = FormDayOfWeek,
                StartPeriod = FormStartPeriod,
                EndPeriod = FormEndPeriod,
                Classroom = FormClassroom
            };

            db.ClassSessions.Add(session);
            db.SaveChanges();

            var courseName = TeacherCourses.First(c => c.CourseID == FormCourseId).CourseName;
            var msg = "课程安排添加成功！" + courseName + " - 第" + FormStartWeek + "-" + FormEndWeek + "周，星期" + DayName(FormDayOfWeek) + "第" + FormStartPeriod + "-" + FormEndPeriod + "节，" + FormClassroom + "教室。";
            Response.Redirect("Timetable.aspx?msg=" + Server.UrlEncode(msg), true);
        }
    }

    protected string DayName(int day)
    {
        string[] days = { "", "一", "二", "三", "四", "五", "六", "日" };
        return day >= 1 && day <= 7 ? days[day] : "?";
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
    <title>添加课程安排</title>
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
                    <h2>添加课程安排</h2>
                    <hr />

                    <% if (!string.IsNullOrEmpty(MessageText)) { %>
                        <div class="alert alert-<%= MessageType %>"><%= MessageText %></div>
                    <% } %>

                    <% if (HolidayDescriptions.Any()) { %>
                        <div class="alert alert-warning">
                            <h5>本学期法定假日提醒</h5>
                            <p>
                                <% foreach (var holiday in HolidayDescriptions) { %>
                                    <span class="label label-warning" style="margin-right:8px;">第<%= holiday.Key %>周：<%= holiday.Value %></span>
                                <% } %>
                            </p>
                        </div>
                    <% } %>

                    <form method="post" class="form-horizontal" style="max-width: 880px;">
                        <div class="form-group">
                            <label class="control-label col-md-2">选择课程</label>
                            <div class="col-md-10">
                                <select class="form-control" name="CourseID" id="CourseID" required>
                                    <option value="">-- 请选择课程 --</option>
                                    <% foreach (var course in TeacherCourses) { %>
                                        <option value="<%= course.CourseID %>" <%= course.CourseID == FormCourseId ? "selected" : "" %>><%= course.CourseName %></option>
                                    <% } %>
                                </select>
                            </div>
                        </div>

                        <div class="form-group">
                            <label class="control-label col-md-2">开始周数</label>
                            <div class="col-md-4"><input class="form-control" type="number" min="1" max="21" name="StartWeek" id="StartWeek" value="<%= FormStartWeek %>" required /></div>
                            <label class="control-label col-md-2">结束周数</label>
                            <div class="col-md-4"><input class="form-control" type="number" min="1" max="21" name="EndWeek" id="EndWeek" value="<%= FormEndWeek %>" required /></div>
                        </div>

                        <div class="form-group">
                            <label class="control-label col-md-2">星期几</label>
                            <div class="col-md-4">
                                <select class="form-control" name="DayOfWeek" id="DayOfWeek" required>
                                    <% for (int d = 1; d <= 7; d++) { %>
                                        <option value="<%= d %>" <%= d == FormDayOfWeek ? "selected" : "" %>>星期<%= DayName(d) %></option>
                                    <% } %>
                                </select>
                            </div>
                            <label class="control-label col-md-2">教室</label>
                            <div class="col-md-4"><input class="form-control" name="Classroom" id="Classroom" value="<%= FormClassroom %>" required /></div>
                        </div>

                        <div class="form-group">
                            <label class="control-label col-md-2">开始节次</label>
                            <div class="col-md-4">
                                <select class="form-control" name="StartPeriod" id="StartPeriod" required>
                                    <% for (int p = 1; p <= 12; p++) { %>
                                        <option value="<%= p %>" <%= p == FormStartPeriod ? "selected" : "" %>>第 <%= p %> 节</option>
                                    <% } %>
                                </select>
                            </div>
                            <label class="control-label col-md-2">结束节次</label>
                            <div class="col-md-4">
                                <select class="form-control" name="EndPeriod" id="EndPeriod" required>
                                    <% for (int p = 1; p <= 12; p++) { %>
                                        <option value="<%= p %>" <%= p == FormEndPeriod ? "selected" : "" %>>第 <%= p %> 节</option>
                                    <% } %>
                                </select>
                            </div>
                        </div>

                        <div class="form-group">
                            <div class="col-md-offset-2 col-md-10">
                                <button type="submit" class="btn btn-primary">添加课程安排</button>
                                <a class="btn btn-default" href="Timetable.aspx">返回课表</a>
                            </div>
                        </div>
                    </form>
                </div>
            </main>
        </div>
    </div>
    <script src="<%= ResolveUrl("~/Scripts/webforms-student-layout.js") %>"></script>
    <script src="<%= ResolveUrl("~/Scripts/jquery-3.7.1.min.js") %>"></script>
    <script>
        $(function () {
            $('#StartPeriod').on('change', function () {
                var startPeriod = parseInt($(this).val(), 10);
                var endPeriodSelect = $('#EndPeriod');
                var currentEnd = parseInt(endPeriodSelect.val(), 10);
                if (currentEnd < startPeriod) {
                    endPeriodSelect.val(startPeriod);
                }
                endPeriodSelect.find('option').each(function () {
                    var v = parseInt($(this).val(), 10);
                    $(this).prop('disabled', v < startPeriod);
                });
            }).trigger('change');

            $('#StartWeek').on('change', function () {
                var startWeek = parseInt($(this).val(), 10);
                var endWeekInput = $('#EndWeek');
                var currentEnd = parseInt(endWeekInput.val(), 10);
                if (currentEnd < startWeek) {
                    endWeekInput.val(startWeek);
                }
                endWeekInput.attr('min', startWeek);
            }).trigger('change');
        });
    </script>
</body>
</html>

