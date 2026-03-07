<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Courses CurrentCourse;
    protected Dictionary<int, string> HolidayDescriptions = new Dictionary<int, string>();
    protected List<int> HolidayWeeks = new List<int>();
    protected string MessageText = string.Empty;

    protected int FormCourseID = 0;
    protected string FormStartWeek = string.Empty;
    protected string FormEndWeek = string.Empty;
    protected string FormDayOfWeek = string.Empty;
    protected string FormStartPeriod = string.Empty;
    protected string FormEndPeriod = string.Empty;
    protected string FormClassroom = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "添加课程安排";
        if (!EnsureAdminRole())
        {
            return;
        }

        HolidayDescriptions = HolidayHelper.GetHolidayWeekDescriptions();
        HolidayWeeks = HolidayHelper.GetCurrentSemesterHolidayWeeks();

        if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
        {
            int.TryParse(Request.Form["CourseID"], out FormCourseID);
            FormStartWeek = (Request.Form["StartWeek"] ?? string.Empty).Trim();
            FormEndWeek = (Request.Form["EndWeek"] ?? string.Empty).Trim();
            FormDayOfWeek = (Request.Form["DayOfWeek"] ?? string.Empty).Trim();
            FormStartPeriod = (Request.Form["StartPeriod"] ?? string.Empty).Trim();
            FormEndPeriod = (Request.Form["EndPeriod"] ?? string.Empty).Trim();
            FormClassroom = (Request.Form["Classroom"] ?? string.Empty).Trim();

            LoadCourse();
            if (CurrentCourse != null)
            {
                SaveSession();
            }
            return;
        }

        int courseId;
        if (!int.TryParse(Request.QueryString["courseId"], out courseId) || courseId <= 0)
        {
            MessageText = "课程参数无效。";
            return;
        }

        FormCourseID = courseId;
        LoadCourse();
    }

    private void LoadCourse()
    {
        using (var db = new StudentManagementDBEntities())
        {
            CurrentCourse = db.Courses.Include("Teachers").FirstOrDefault(c => c.CourseID == FormCourseID);
        }

        if (CurrentCourse == null)
        {
            MessageText = "课程不存在。";
        }
    }

    private void SaveSession()
    {
        int startWeek, endWeek, dayOfWeek, startPeriod, endPeriod;
        if (!int.TryParse(FormStartWeek, out startWeek) || !int.TryParse(FormEndWeek, out endWeek) ||
            !int.TryParse(FormDayOfWeek, out dayOfWeek) || !int.TryParse(FormStartPeriod, out startPeriod) ||
            !int.TryParse(FormEndPeriod, out endPeriod) || string.IsNullOrWhiteSpace(FormClassroom))
        {
            MessageText = "请完整并正确填写课程安排信息。";
            return;
        }

        if (startWeek > endWeek)
        {
            MessageText = "结束周数不能小于开始周数。";
            return;
        }

        if (startPeriod > endPeriod)
        {
            MessageText = "结束节次不能小于开始节次。";
            return;
        }

        if (CurrentCourse.TeacherID == null)
        {
            MessageText = "该课程尚未分配教师，无法添加课程安排。请先为课程分配教师。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            var conflictingSessions = db.ClassSessions.Include("Courses")
                .Where(cs => cs.Courses.TeacherID == CurrentCourse.TeacherID &&
                             cs.DayOfWeek == dayOfWeek &&
                             !(endWeek < cs.StartWeek || startWeek > cs.EndWeek) &&
                             !(endPeriod < cs.StartPeriod || startPeriod > cs.EndPeriod))
                .ToList();

            if (conflictingSessions.Any())
            {
                var desc = string.Join("; ", conflictingSessions.Select(cs =>
                    (cs.Courses == null ? "未知课程" : cs.Courses.CourseName) + "(第" + cs.StartWeek + "-" + cs.EndWeek + "周, 第" + cs.StartPeriod + "-" + cs.EndPeriod + "节)"));
                MessageText = "时间冲突！该教师在此时间段已有以下课程安排：" + desc;
                return;
            }

            var session = new ClassSessions
            {
                CourseID = FormCourseID,
                StartWeek = startWeek,
                EndWeek = endWeek,
                DayOfWeek = dayOfWeek,
                StartPeriod = startPeriod,
                EndPeriod = endPeriod,
                Classroom = FormClassroom
            };

            db.ClassSessions.Add(session);
            db.SaveChanges();

            Session["AdminFlashMessage"] = "课程安排添加成功！" + CurrentCourse.CourseName + " - 第" + startWeek + "-" + endWeek + "周，" + DayName(dayOfWeek) + "第" + startPeriod + "-" + endPeriod + "节，" + FormClassroom + "教室。";
            Response.Redirect("CourseSchedule.aspx?courseId=" + FormCourseID, true);
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>添加课程安排</h2>
<hr />

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } %>

<% if (CurrentCourse != null) { %>
    <div class="alert alert-info">
        <h4><span class="glyphicon glyphicon-info-sign"></span> 当前课程信息</h4>
        <div class="row">
            <div class="col-md-6">
                <p><strong>课程名称：</strong><%= H(CurrentCourse.CourseName) %></p>
                <p><strong>学分：</strong><%= CurrentCourse.Credits %> 学分</p>
            </div>
            <div class="col-md-6">
                <p><strong>任课教师：</strong>
                    <% if (CurrentCourse.Teachers != null) { %>
                        <%= H(CurrentCourse.Teachers.TeacherName) %>
                    <% } else { %>
                        <span class="text-danger">未分配教师</span>
                    <% } %>
                </p>
                <p><strong>课程类型：</strong><span class="label label-info"><%= H(CourseTypeText(CurrentCourse.CourseType)) %></span></p>
            </div>
        </div>
    </div>

    <% if (HolidayDescriptions.Any()) { %>
        <div class="alert alert-warning">
            <h5><span class="glyphicon glyphicon-calendar"></span> 本学期法定假日提醒</h5>
            <p>以下周次为法定假日，课程安排将自动跳过这些周次：</p>
            <p>
                <% foreach (var holiday in HolidayDescriptions) { %>
                    <span class="label label-warning" style="margin-right:8px;">第<%= holiday.Key %>周：<%= H(holiday.Value) %></span>
                <% } %>
            </p>
        </div>
    <% } %>

    <form method="post" class="form-horizontal" style="max-width:900px;">
        <input type="hidden" name="CourseID" value="<%= FormCourseID %>" />

        <div class="form-group">
            <label class="control-label col-md-2">开始周数</label>
            <div class="col-md-10">
                <input class="form-control" type="number" min="1" max="21" name="StartWeek" value="<%= H(FormStartWeek) %>" placeholder="例如：1" required />
                <small class="text-muted">输入这个时间安排的开始周数（1-21）</small>
            </div>
        </div>

        <div class="form-group">
            <label class="control-label col-md-2">结束周数</label>
            <div class="col-md-10">
                <input class="form-control" type="number" min="1" max="21" name="EndWeek" value="<%= H(FormEndWeek) %>" placeholder="例如：4" required />
                <small class="text-muted">结束周数应大于或等于开始周数</small>
            </div>
        </div>

        <div class="form-group">
            <label class="control-label col-md-2">星期几</label>
            <div class="col-md-10">
                <select class="form-control" name="DayOfWeek" required>
                    <option value="">--请选择星期--</option>
                    <option value="1" <%= FormDayOfWeek == "1" ? "selected" : "" %>>星期一</option>
                    <option value="2" <%= FormDayOfWeek == "2" ? "selected" : "" %>>星期二</option>
                    <option value="3" <%= FormDayOfWeek == "3" ? "selected" : "" %>>星期三</option>
                    <option value="4" <%= FormDayOfWeek == "4" ? "selected" : "" %>>星期四</option>
                    <option value="5" <%= FormDayOfWeek == "5" ? "selected" : "" %>>星期五</option>
                    <option value="6" <%= FormDayOfWeek == "6" ? "selected" : "" %>>星期六</option>
                    <option value="7" <%= FormDayOfWeek == "7" ? "selected" : "" %>>星期日</option>
                </select>
            </div>
        </div>

        <div class="form-group">
            <label class="control-label col-md-2">开始节次</label>
            <div class="col-md-10">
                <select class="form-control" name="StartPeriod" required>
                    <option value="">--请选择开始节次--</option>
                    <% for (int i = 1; i <= 12; i++) { %>
                        <option value="<%= i %>" <%= FormStartPeriod == i.ToString() ? "selected" : "" %>>第 <%= i %> 节</option>
                    <% } %>
                </select>
            </div>
        </div>

        <div class="form-group">
            <label class="control-label col-md-2">结束节次</label>
            <div class="col-md-10">
                <select class="form-control" name="EndPeriod" required>
                    <option value="">--请选择结束节次--</option>
                    <% for (int i = 1; i <= 12; i++) { %>
                        <option value="<%= i %>" <%= FormEndPeriod == i.ToString() ? "selected" : "" %>>第 <%= i %> 节</option>
                    <% } %>
                </select>
            </div>
        </div>

        <div class="form-group">
            <label class="control-label col-md-2">教室</label>
            <div class="col-md-10">
                <input class="form-control" name="Classroom" value="<%= H(FormClassroom) %>" placeholder="例如：310、308、实验室A等" required />
            </div>
        </div>

        <div class="form-group">
            <div class="col-md-offset-2 col-md-10">
                <button type="submit" class="btn btn-primary">添加课程安排</button>
                <a class="btn btn-default" href='CourseSchedule.aspx?courseId=<%= CurrentCourse.CourseID %>'>返回课程安排</a>
            </div>
        </div>
    </form>
<% } %>

<!--#include file="_AdminLayoutBottom.inc" -->
