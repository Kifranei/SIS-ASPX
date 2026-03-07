<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected ClassSessions CurrentSession;
    protected string MessageText = string.Empty;
    protected List<int> HolidayWeeks = new List<int>();

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "删除课程安排";
        if (!EnsureAdminRole())
        {
            return;
        }

        int sessionId;
        if (!int.TryParse(Request.QueryString["sessionId"] ?? Request.Form["SessionID"], out sessionId) || sessionId <= 0)
        {
            MessageText = "课程安排参数无效。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            CurrentSession = db.ClassSessions.Include("Courses.Teachers").FirstOrDefault(cs => cs.SessionID == sessionId);
            if (CurrentSession == null)
            {
                MessageText = "课程安排不存在。";
                return;
            }

            if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
            {
                var courseId = CurrentSession.CourseID;
                var courseName = CurrentSession.Courses == null ? "课程" : CurrentSession.Courses.CourseName;
                var info = "第" + CurrentSession.StartWeek + "-" + CurrentSession.EndWeek + "周，" + DayName(CurrentSession.DayOfWeek) + "第" + CurrentSession.StartPeriod + "-" + CurrentSession.EndPeriod + "节，" + CurrentSession.Classroom + "教室";

                db.ClassSessions.Remove(CurrentSession);
                db.SaveChanges();

                Session["AdminFlashMessage"] = "课程安排删除成功！已删除 " + courseName + " 的安排：" + info;
                Response.Redirect("CourseSchedule.aspx?courseId=" + courseId, true);
            }
        }

        HolidayWeeks = HolidayHelper.GetCurrentSemesterHolidayWeeks();
    }

    protected bool HasHolidayConflict()
    {
        if (CurrentSession == null)
        {
            return false;
        }

        for (int week = CurrentSession.StartWeek; week <= CurrentSession.EndWeek; week++)
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

<h2>删除课程安排</h2>
<hr />

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } else { %>
    <div class="alert alert-danger">
        <h4><span class="glyphicon glyphicon-warning-sign"></span> 确认删除</h4>
        <p>您确定要删除以下课程安排吗？此操作无法撤销，且会影响相关教师和学生的课表。</p>
    </div>

    <div class="panel panel-default">
        <div class="panel-heading"><h3 class="panel-title">课程安排详情</h3></div>
        <div class="panel-body">
            <dl class="dl-horizontal">
                <dt>课程名称：</dt>
                <dd><strong><%= CurrentSession.Courses == null ? "-" : H(CurrentSession.Courses.CourseName) %></strong></dd>

                <dt>任课教师：</dt>
                <dd><%= (CurrentSession.Courses != null && CurrentSession.Courses.Teachers != null) ? H(CurrentSession.Courses.Teachers.TeacherName) : "未分配教师" %></dd>

                <dt>课程类型：</dt>
                <dd><span class="label label-info"><%= CurrentSession.Courses == null ? "-" : H(CourseTypeText(CurrentSession.Courses.CourseType)) %></span></dd>

                <dt>周次范围：</dt>
                <dd>第 <%= CurrentSession.StartWeek %> - <%= CurrentSession.EndWeek %> 周</dd>

                <dt>上课时间：</dt>
                <dd><%= H(DayName(CurrentSession.DayOfWeek)) %> 第 <%= CurrentSession.StartPeriod %> - <%= CurrentSession.EndPeriod %> 节</dd>

                <dt>教室：</dt>
                <dd><%= H(CurrentSession.Classroom) %></dd>

                <dt>假日状态：</dt>
                <dd>
                    <% if (HasHolidayConflict()) { %>
                        <span class="label label-warning">包含假日周次</span>
                    <% } else { %>
                        <span class="label label-success">无假日冲突</span>
                    <% } %>
                </dd>
            </dl>
        </div>
    </div>

    <form method="post" class="form-actions">
        <input type="hidden" name="SessionID" value="<%= CurrentSession.SessionID %>" />
        <button type="submit" class="btn btn-danger" onclick="return confirm('您确定要删除这个课程安排吗？此操作无法撤销！');">确认删除</button>
        <a class="btn btn-default" href='CourseSchedule.aspx?courseId=<%= CurrentSession.CourseID %>'>取消</a>
    </form>
<% } %>

<style>
    .dl-horizontal dt { text-align: left; width: 100px; }
    .dl-horizontal dd { margin-left: 120px; }
    .form-actions { padding-top: 20px; border-top: 1px solid #e5e5e5; }
</style>

<!--#include file="_AdminLayoutBottom.inc" -->
