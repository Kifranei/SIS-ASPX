<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Courses CurrentCourse;
    protected List<ClassSessions> SessionList = new List<ClassSessions>();
    protected List<int> HolidayWeeks = new List<int>();
    protected Dictionary<int, string> HolidayDescriptions = new Dictionary<int, string>();
    protected string FlashMessage = string.Empty;
    protected string MessageText = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "课程安排管理";
        if (!EnsureAdminRole())
        {
            return;
        }

        FlashMessage = (Session["AdminFlashMessage"] as string) ?? string.Empty;
        Session.Remove("AdminFlashMessage");

        int courseId;
        if (!int.TryParse(Request.QueryString["courseId"], out courseId) || courseId <= 0)
        {
            MessageText = "课程参数无效。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            CurrentCourse = db.Courses.Include("Teachers").FirstOrDefault(c => c.CourseID == courseId);
            if (CurrentCourse == null)
            {
                MessageText = "课程不存在。";
                return;
            }

            SessionList = db.ClassSessions.Include("Courses")
                .Where(cs => cs.CourseID == courseId)
                .OrderBy(cs => cs.StartWeek)
                .ThenBy(cs => cs.DayOfWeek)
                .ThenBy(cs => cs.StartPeriod)
                .ToList();
        }

        HolidayWeeks = HolidayHelper.GetCurrentSemesterHolidayWeeks();
        HolidayDescriptions = HolidayHelper.GetHolidayWeekDescriptions();
    }

    protected string SessionTimeText(ClassSessions session)
    {
        var start = GetPeriodTime(session.StartPeriod);
        var end = GetPeriodTime(session.EndPeriod);
        var startText = string.IsNullOrWhiteSpace(start) ? "" : start.Split('-')[0];
        var endText = string.IsNullOrWhiteSpace(end) ? "" : end.Split('-')[1];
        return DayName(session.DayOfWeek) + " 第 " + session.StartPeriod + " - " + session.EndPeriod + " 节" + (string.IsNullOrWhiteSpace(startText) ? "" : " (" + startText + " - " + endText + ")");
    }

    protected string HolidayStatus(ClassSessions session)
    {
        var weeks = new List<int>();
        for (int week = session.StartWeek; week <= session.EndWeek; week++)
        {
            if (HolidayWeeks.Contains(week))
            {
                weeks.Add(week);
            }
        }

        if (!weeks.Any())
        {
            return "<span class='label label-success'><span class='glyphicon glyphicon-ok'></span> 正常</span>";
        }

        return "<span class='label label-warning' title='包含假日周次：第" + string.Join("、", weeks) + "周'><span class='glyphicon glyphicon-calendar'></span> 含假日</span>";
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } else { %>
    <% if (!string.IsNullOrEmpty(FlashMessage)) { %>
        <div class="alert alert-success"><strong><span class="glyphicon glyphicon-ok-circle"></span> 成功！</strong> <%= H(FlashMessage) %></div>
    <% } %>

    <div style="display:flex;justify-content:space-between;align-items:center;">
        <h2>课程安排管理</h2>
        <div>
            <a class="btn btn-primary" href='AddCourseSchedule.aspx?courseId=<%= CurrentCourse.CourseID %>'>添加新安排</a>
            <a class="btn btn-default" href="CourseList.aspx">返回课程列表</a>
        </div>
    </div>
    <hr />

    <div class="panel panel-info">
        <div class="panel-heading"><h4><span class="glyphicon glyphicon-info-sign"></span> 课程信息</h4></div>
        <div class="panel-body">
            <div class="row">
                <div class="col-md-6">
                    <p><strong>课程名称：</strong><%= H(CurrentCourse.CourseName) %></p>
                    <p><strong>学分：</strong><%= CurrentCourse.Credits %> 学分</p>
                </div>
                <div class="col-md-6">
                    <p><strong>任课教师：</strong><%= CurrentCourse.Teachers == null ? "<span class='text-danger'>未分配教师</span>" : H(CurrentCourse.Teachers.TeacherName) %></p>
                    <p><strong>课程类型：</strong><span class="label label-info"><%= H(CourseTypeText(CurrentCourse.CourseType)) %></span></p>
                </div>
            </div>
        </div>
    </div>

    <% if (HolidayDescriptions.Any()) { %>
        <div class="alert alert-info">
            <h5><span class="glyphicon glyphicon-calendar"></span> 本学期法定假日提醒</h5>
            <p>以下周次为法定假日，相应的课程安排不会在课表中显示：</p>
            <p>
                <% foreach (var holiday in HolidayDescriptions) { %>
                    <span class="label label-warning" style="margin-right:8px;">第<%= holiday.Key %>周：<%= H(holiday.Value) %></span>
                <% } %>
            </p>
        </div>
    <% } %>

    <% if (SessionList.Any()) { %>
        <div class="table-responsive">
            <table class="table table-striped table-hover">
                <thead>
                    <tr>
                        <th>周次范围</th>
                        <th>上课时间</th>
                        <th>教室</th>
                        <th>假日状态</th>
                        <th>操作</th>
                    </tr>
                </thead>
                <tbody>
                    <% foreach (var session in SessionList) { %>
                        <tr>
                            <td><span class="label label-info">第 <%= session.StartWeek %> - <%= session.EndWeek %> 周</span></td>
                            <td><%= H(SessionTimeText(session)) %></td>
                            <td><span class="label label-default"><%= H(session.Classroom) %></span></td>
                            <td><%= HolidayStatus(session) %></td>
                            <td>
                                <div class="btn-group btn-group-sm">
                                    <a class="btn btn-warning" href='EditCourseSchedule.aspx?sessionId=<%= session.SessionID %>'>编辑</a>
                                    <a class="btn btn-danger" href='DeleteCourseSchedule.aspx?sessionId=<%= session.SessionID %>'>删除</a>
                                </div>
                            </td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
        </div>

        <div class="well well-sm">
            <p class="text-muted"><span class="glyphicon glyphicon-info-sign"></span> <strong>统计信息：</strong>该课程总共有 <strong><%= SessionList.Count %></strong> 个时间安排。</p>
        </div>
    <% } else { %>
        <div class="well text-center">
            <h4><span class="glyphicon glyphicon-info-sign text-muted"></span> 暂无课程安排</h4>
            <% if (CurrentCourse.Teachers == null) { %>
                <p class="text-danger">该课程尚未分配教师，无法添加课程安排。请先为课程分配教师。</p>
                <a class="btn btn-warning btn-lg" href='EditCourse.aspx?id=<%= CurrentCourse.CourseID %>'>编辑课程</a>
            <% } else { %>
                <p class="text-muted">该课程还没有添加任何时间安排。现在就开始创建第一个课程安排吧！</p>
                <a class="btn btn-primary btn-lg" href='AddCourseSchedule.aspx?courseId=<%= CurrentCourse.CourseID %>'>立即添加</a>
            <% } %>
        </div>
    <% } %>
<% } %>

<style>
    .label { font-size: 85%; padding: 0.3em 0.6em; }
    .btn-group-sm > .btn { padding: 5px 10px; font-size: 12px; }
    .table > tbody > tr:hover { background-color: #f5f5f5; }
    .well-sm { padding: 9px; border-radius: 3px; }
</style>

<!--#include file="_AdminLayoutBottom.inc" -->
