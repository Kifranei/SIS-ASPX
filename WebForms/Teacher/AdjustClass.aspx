<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Helpers" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected ClassSessions CurrentSession;
    protected Dictionary<int, string> HolidayDescriptions = new Dictionary<int, string>();
    protected List<int> HolidayWeeks = new List<int>();
    protected string MessageType = string.Empty;
    protected string MessageText = string.Empty;

    protected int FormSessionId = 0;
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

            if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
            {
                int.TryParse(Request.Form["SessionID"], out FormSessionId);
            }
            else
            {
                int.TryParse(Request.QueryString["sessionId"], out FormSessionId);
            }

            if (FormSessionId <= 0)
            {
                MessageType = "danger";
                MessageText = "无效的课程安排参数。";
                return;
            }

            CurrentSession = db.ClassSessions.Include("Courses").FirstOrDefault(cs => cs.SessionID == FormSessionId);
            if (CurrentSession == null || !taughtCourseIds.Contains(CurrentSession.CourseID))
            {
                MessageType = "danger";
                MessageText = "课程安排不存在或不属于当前教师。";
                CurrentSession = null;
                return;
            }

            if (!Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
            {
                FormCourseId = CurrentSession.CourseID;
                FormStartWeek = CurrentSession.StartWeek;
                FormEndWeek = CurrentSession.EndWeek;
                FormDayOfWeek = CurrentSession.DayOfWeek;
                FormStartPeriod = CurrentSession.StartPeriod;
                FormEndPeriod = CurrentSession.EndPeriod;
                FormClassroom = CurrentSession.Classroom;
                return;
            }

            int.TryParse(Request.Form["CourseID"], out FormCourseId);
            int.TryParse(Request.Form["StartWeek"], out FormStartWeek);
            int.TryParse(Request.Form["EndWeek"], out FormEndWeek);
            int.TryParse(Request.Form["DayOfWeek"], out FormDayOfWeek);
            int.TryParse(Request.Form["StartPeriod"], out FormStartPeriod);
            int.TryParse(Request.Form["EndPeriod"], out FormEndPeriod);
            FormClassroom = (Request.Form["Classroom"] ?? string.Empty).Trim();

            if (!taughtCourseIds.Contains(FormCourseId))
            {
                MessageType = "danger";
                MessageText = "您只能调整自己教授的课程。";
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

            var course = db.Courses.Find(FormCourseId);
            var conflictingSessions = ScheduleConflictHelper.GetTeacherSessionConflicts(
                db,
                course == null ? null : course.TeacherID,
                FormDayOfWeek,
                FormStartWeek,
                FormEndWeek,
                FormStartPeriod,
                FormEndPeriod,
                FormSessionId);

            if (conflictingSessions.Any())
            {
                MessageType = "danger";
                MessageText = ScheduleConflictHelper.BuildTeacherConflictMessage(
                    conflictingSessions,
                    "时间冲突！您在该时间段已有以下课程安排：");
                return;
            }

            var studentConflicts = ScheduleConflictHelper.GetConflictsForEnrolledStudentsWhenScheduling(
                db,
                FormCourseId,
                FormDayOfWeek,
                FormStartWeek,
                FormEndWeek,
                FormStartPeriod,
                FormEndPeriod,
                FormSessionId);
            if (studentConflicts.Any())
            {
                MessageType = "danger";
                MessageText = ScheduleConflictHelper.BuildStudentConflictMessage(
                    studentConflicts,
                    "该调整会与已选学生的现有课表冲突：");
                return;
            }

            CurrentSession.CourseID = FormCourseId;
            CurrentSession.StartWeek = FormStartWeek;
            CurrentSession.EndWeek = FormEndWeek;
            CurrentSession.DayOfWeek = FormDayOfWeek;
            CurrentSession.StartPeriod = FormStartPeriod;
            CurrentSession.EndPeriod = FormEndPeriod;
            CurrentSession.Classroom = FormClassroom;
            db.Entry(CurrentSession).State = EntityState.Modified;
            db.SaveChanges();

            var updatedCourse = db.Courses.Find(FormCourseId);
            var courseName = updatedCourse == null ? "\u8BFE\u7A0B" : updatedCourse.CourseName;
            var msg = "课程调整成功！" + courseName + " 已调整为：第" + FormStartWeek + "-" + FormEndWeek + "周，星期" + DayName(FormDayOfWeek) + "第" + FormStartPeriod + "-" + FormEndPeriod + "节，" + FormClassroom + "教室。";
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
    <title>调整课程安排</title>
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
                    <h2>调整课程安排</h2>
                    <hr />

                    <% if (!string.IsNullOrEmpty(MessageText)) { %>
                        <div class="alert alert-<%= MessageType %>"><%= MessageText %></div>
                    <% } %>

                    <% if (CurrentSession != null) { %>
                        <div class="alert alert-info">
                            <p><strong>当前课程：</strong><%= CurrentSession.Courses == null ? "-" : CurrentSession.Courses.CourseName %></p>
                            <p><strong>当前安排：</strong>第 <%= CurrentSession.StartWeek %>-<%= CurrentSession.EndWeek %> 周，星期<%= DayName(CurrentSession.DayOfWeek) %>，第 <%= CurrentSession.StartPeriod %>-<%= CurrentSession.EndPeriod %> 节，<%= CurrentSession.Classroom %></p>
                        </div>

                        <form method="post" class="form-horizontal" style="max-width: 880px;">
                            <input type="hidden" name="SessionID" value="<%= FormSessionId %>" />
                            <input type="hidden" name="CourseID" value="<%= FormCourseId %>" />

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
                                    <button type="submit" class="btn btn-success">确认调整</button>
                                    <a class="btn btn-default" href="Timetable.aspx">取消</a>
                                </div>
                            </div>
                        </form>

                        <% if (HolidayDescriptions.Any()) { %>
                            <div class="panel panel-info" style="margin-top:20px;">
                                <div class="panel-heading"><h4>本学期法定假日</h4></div>
                                <div class="panel-body">
                                    <% foreach (var holiday in HolidayDescriptions) { %>
                                        <span class="label label-info" style="margin-right:8px;display:inline-block;margin-bottom:5px;">第<%= holiday.Key %>周：<%= holiday.Value %></span>
                                    <% } %>
                                </div>
                            </div>
                        <% } %>
                    <% } else { %>
                        <a class="btn btn-default" href="Timetable.aspx">返回课表</a>
                    <% } %>
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

