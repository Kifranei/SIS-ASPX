<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Courses CurrentCourse;
    protected ClassSessions CurrentSession;
    protected Dictionary<int, string> HolidayDescriptions = new Dictionary<int, string>();
    protected List<int> HolidayWeeks = new List<int>();
    protected string MessageText = string.Empty;

    protected int FormSessionID = 0;
    protected int FormCourseID = 0;
    protected string FormStartWeek = string.Empty;
    protected string FormEndWeek = string.Empty;
    protected string FormDayOfWeek = string.Empty;
    protected string FormStartPeriod = string.Empty;
    protected string FormEndPeriod = string.Empty;
    protected string FormClassroom = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "编辑课程安排";
        if (!EnsureAdminRole())
        {
            return;
        }

        HolidayDescriptions = HolidayHelper.GetHolidayWeekDescriptions();
        HolidayWeeks = HolidayHelper.GetCurrentSemesterHolidayWeeks();

        if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
        {
            int.TryParse(Request.Form["SessionID"], out FormSessionID);
            int.TryParse(Request.Form["CourseID"], out FormCourseID);
            FormStartWeek = (Request.Form["StartWeek"] ?? string.Empty).Trim();
            FormEndWeek = (Request.Form["EndWeek"] ?? string.Empty).Trim();
            FormDayOfWeek = (Request.Form["DayOfWeek"] ?? string.Empty).Trim();
            FormStartPeriod = (Request.Form["StartPeriod"] ?? string.Empty).Trim();
            FormEndPeriod = (Request.Form["EndPeriod"] ?? string.Empty).Trim();
            FormClassroom = (Request.Form["Classroom"] ?? string.Empty).Trim();

            LoadSessionAndCourse();
            if (CurrentSession != null && CurrentCourse != null)
            {
                SaveSession();
            }
            return;
        }

        int sessionId;
        if (!int.TryParse(Request.QueryString["sessionId"], out sessionId) || sessionId <= 0)
        {
            MessageText = "课程安排参数无效。";
            return;
        }

        FormSessionID = sessionId;
        LoadSessionAndCourse();

        if (CurrentSession != null)
        {
            FormCourseID = CurrentSession.CourseID;
            FormStartWeek = CurrentSession.StartWeek.ToString();
            FormEndWeek = CurrentSession.EndWeek.ToString();
            FormDayOfWeek = CurrentSession.DayOfWeek.ToString();
            FormStartPeriod = CurrentSession.StartPeriod.ToString();
            FormEndPeriod = CurrentSession.EndPeriod.ToString();
            FormClassroom = CurrentSession.Classroom;
        }
    }

    private void LoadSessionAndCourse()
    {
        using (var db = new StudentManagementDBEntities())
        {
            CurrentSession = db.ClassSessions.Include("Courses").FirstOrDefault(cs => cs.SessionID == FormSessionID);
            if (CurrentSession == null)
            {
                MessageText = "课程安排不存在。";
                return;
            }

            if (FormCourseID <= 0)
            {
                FormCourseID = CurrentSession.CourseID;
            }

            CurrentCourse = db.Courses.Include("Teachers").FirstOrDefault(c => c.CourseID == FormCourseID);
            if (CurrentCourse == null)
            {
                MessageText = "课程不存在。";
            }
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

        using (var db = new StudentManagementDBEntities())
        {
            var session = db.ClassSessions.Find(FormSessionID);
            if (session == null)
            {
                MessageText = "课程安排不存在。";
                return;
            }

            var course = db.Courses.Find(FormCourseID);
            if (course == null)
            {
                MessageText = "课程不存在。";
                return;
            }

            if (course.TeacherID != null)
            {
                var conflicts = ScheduleConflictHelper.GetTeacherSessionConflicts(
                    db,
                    course.TeacherID,
                    dayOfWeek,
                    startWeek,
                    endWeek,
                    startPeriod,
                    endPeriod,
                    FormSessionID);

                if (conflicts.Any())
                {
                    MessageText = ScheduleConflictHelper.BuildTeacherConflictMessage(
                        conflicts,
                        "时间冲突！该教师在此时间段已有以下课程安排：");
                    return;
                }

                var studentConflicts = ScheduleConflictHelper.GetConflictsForEnrolledStudentsWhenScheduling(
                    db,
                    FormCourseID,
                    dayOfWeek,
                    startWeek,
                    endWeek,
                    startPeriod,
                    endPeriod,
                    FormSessionID);
                if (studentConflicts.Any())
                {
                    MessageText = ScheduleConflictHelper.BuildStudentConflictMessage(
                        studentConflicts,
                        "该调整会与已选学生的现有课表冲突：");
                    return;
                }
            }

            session.CourseID = FormCourseID;
            session.StartWeek = startWeek;
            session.EndWeek = endWeek;
            session.DayOfWeek = dayOfWeek;
            session.StartPeriod = startPeriod;
            session.EndPeriod = endPeriod;
            session.Classroom = FormClassroom;

            db.Entry(session).State = EntityState.Modified;
            db.SaveChanges();

            Session["AdminFlashMessage"] = "课程安排修改成功！" + course.CourseName + " 已调整为：第" + startWeek + "-" + endWeek + "周，" + DayName(dayOfWeek) + "第" + startPeriod + "-" + endPeriod + "节，" + FormClassroom + "教室。";
            Response.Redirect("CourseSchedule.aspx?courseId=" + FormCourseID, true);
        }
    }

    protected bool HasHolidayConflict()
    {
        int startWeek, endWeek;
        if (!int.TryParse(FormStartWeek, out startWeek) || !int.TryParse(FormEndWeek, out endWeek))
        {
            return false;
        }

        for (int week = startWeek; week <= endWeek; week++)
        {
            if (HolidayWeeks.Contains(week))
            {
                return true;
            }
        }

        return false;
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>编辑课程安排</h2>
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
                <p><strong>任课教师：</strong><%= CurrentCourse.Teachers == null ? "未分配教师" : H(CurrentCourse.Teachers.TeacherName) %></p>
                <p><strong>课程类型：</strong><span class="label label-info"><%= H(CourseTypeText(CurrentCourse.CourseType)) %></span></p>
            </div>
        </div>
    </div>

    <% if (HasHolidayConflict()) { %>
        <div class="alert alert-warning">
            <h5><span class="glyphicon glyphicon-warning-sign"></span> 假日周次提醒</h5>
            <p>当前安排包含假日周次，假日周次课程不会在课表中显示。</p>
        </div>
    <% } %>

    <form method="post" class="form-horizontal" style="max-width:900px;">
        <input type="hidden" name="SessionID" value="<%= FormSessionID %>" />
        <input type="hidden" name="CourseID" value="<%= FormCourseID %>" />

        <div class="form-group">
            <label class="control-label col-md-2">开始周数</label>
            <div class="col-md-10">
                <input class="form-control" type="number" min="1" max="21" name="StartWeek" value="<%= H(FormStartWeek) %>" required />
            </div>
        </div>

        <div class="form-group">
            <label class="control-label col-md-2">结束周数</label>
            <div class="col-md-10">
                <input class="form-control" type="number" min="1" max="21" name="EndWeek" value="<%= H(FormEndWeek) %>" required />
            </div>
        </div>

        <div class="form-group">
            <label class="control-label col-md-2">星期几</label>
            <div class="col-md-10">
                <select class="form-control" name="DayOfWeek" required>
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
                    <% for (int i = 1; i <= 12; i++) { %>
                        <option value="<%= i %>" <%= FormEndPeriod == i.ToString() ? "selected" : "" %>>第 <%= i %> 节</option>
                    <% } %>
                </select>
            </div>
        </div>

        <div class="form-group">
            <label class="control-label col-md-2">教室</label>
            <div class="col-md-10">
                <input class="form-control" name="Classroom" value="<%= H(FormClassroom) %>" required />
            </div>
        </div>

        <div class="form-group">
            <div class="col-md-offset-2 col-md-10">
                <button type="submit" class="btn btn-success">保存修改</button>
                <a class="btn btn-default" href='CourseSchedule.aspx?courseId=<%= FormCourseID %>'>取消</a>
            </div>
        </div>
    </form>
<% } %>

<!--#include file="_AdminLayoutBottom.inc" -->
