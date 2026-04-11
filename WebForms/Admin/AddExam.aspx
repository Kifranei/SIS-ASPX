<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.Data.Entity" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected string MessageText = string.Empty;
    protected List<Courses> CourseOptions = new List<Courses>();

    protected string FormCourseID = string.Empty;
    protected string FormExamTime = string.Empty;
    protected string FormLocation = string.Empty;
    protected string FormDetails = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "添加新考试";
        if (!EnsureAdminRole())
        {
            return;
        }

        if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
        {
            FormCourseID = (Request.Form["CourseID"] ?? string.Empty).Trim();
            FormExamTime = (Request.Form["ExamTime"] ?? string.Empty).Trim();
            FormLocation = (Request.Form["Location"] ?? string.Empty).Trim();
            FormDetails = (Request.Form["Details"] ?? string.Empty).Trim();
            SaveExam();
        }

        using (var db = new StudentManagementDBEntities())
        {
            CourseOptions = db.Courses.OrderBy(c => c.CourseName).ToList();
        }
    }

    private void SaveExam()
    {
        int courseId;
        DateTime examTime;
        if (!int.TryParse(FormCourseID, out courseId) || !DateTime.TryParse(FormExamTime, out examTime) || string.IsNullOrWhiteSpace(FormLocation))
        {
            MessageText = "请正确填写课程、考试时间和考试地点。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            var course = db.Courses.Find(courseId);
            if (course == null)
            {
                MessageText = "课程不存在。";
                return;
            }

            var examTeacherConflicts = GetTeacherExamConflicts(
                db,
                course == null ? null : course.TeacherID,
                examTime);
            if (examTeacherConflicts.Any())
            {
                MessageText = BuildTeacherExamConflictMessage(
                    examTeacherConflicts,
                    "考试时间冲突！该教师在该时段已有以下考试安排：");
                return;
            }

            var studentConflicts = GetStudentExamConflictsForCourse(
                db,
                courseId,
                examTime);
            if (studentConflicts.Any())
            {
                MessageText = BuildStudentExamConflictMessage(
                    studentConflicts,
                    "考试时间冲突！以下学生在该时段已有其他考试：");
                return;
            }

            var exam = new Exams
            {
                CourseID = courseId,
                ExamTime = examTime,
                Location = FormLocation,
                Details = FormDetails
            };
            db.Exams.Add(exam);
            db.SaveChanges();
            Response.Redirect("ExamList.aspx", true);
        }
    }

    private List<Exams> GetTeacherExamConflicts(StudentManagementDBEntities db, string teacherId, DateTime examTime, int? excludeExamId = null)
    {
        if (string.IsNullOrWhiteSpace(teacherId))
        {
            return new List<Exams>();
        }

        var query = db.Exams
            .Include("Courses")
            .Where(e => e.ExamTime == examTime && e.Courses != null && e.Courses.TeacherID == teacherId);

        if (excludeExamId.HasValue)
        {
            int examId = excludeExamId.Value;
            query = query.Where(e => e.ExamID != examId);
        }

        return query.OrderBy(e => e.Courses.CourseName).ToList();
    }

    private List<string> GetStudentExamConflictsForCourse(StudentManagementDBEntities db, int courseId, DateTime examTime, int? excludeExamId = null)
    {
        var studentIds = db.StudentCourses
            .Where(sc => sc.CourseID == courseId)
            .Select(sc => sc.StudentID)
            .Distinct()
            .ToList();

        if (!studentIds.Any())
        {
            return new List<string>();
        }

        var query = db.StudentCourses
            .Where(sc => studentIds.Contains(sc.StudentID)
                && sc.CourseID != courseId
                && sc.Courses.Exams.Any(e => e.ExamTime == examTime && (!excludeExamId.HasValue || e.ExamID != excludeExamId.Value)))
            .Select(sc => sc.StudentID + " " + sc.Students.StudentName + " -> " + sc.Courses.CourseName)
            .Distinct();

        return query.OrderBy(x => x).ToList();
    }

    private string BuildTeacherExamConflictMessage(IEnumerable<Exams> conflicts, string prefix)
    {
        return prefix + " " + string.Join("；", conflicts.Select(e => (e.Courses == null ? "未知课程" : e.Courses.CourseName) + "（" + e.ExamTime.ToString("yyyy-MM-dd HH:mm") + "）"));
    }

    private string BuildStudentExamConflictMessage(IEnumerable<string> conflicts, string prefix)
    {
        return prefix + " " + string.Join("；", conflicts);
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>添加新考试</h2>

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } %>

<form method="post" class="form-horizontal" style="max-width:900px;">
    <h4>考试信息</h4>
    <hr />

    <div class="form-group">
        <label class="control-label col-md-2">课程名称</label>
        <div class="col-md-10">
            <select class="form-control" name="CourseID" required>
                <option value="">--请选择课程--</option>
                <% foreach (var c in CourseOptions) { %>
                    <option value="<%= c.CourseID %>" <%= FormCourseID == c.CourseID.ToString() ? "selected" : "" %>><%= H(c.CourseName) %></option>
                <% } %>
            </select>
        </div>
    </div>

    <div class="form-group">
        <label class="control-label col-md-2">考试时间</label>
        <div class="col-md-10">
            <input class="form-control" type="datetime-local" name="ExamTime" value="<%= H(FormExamTime) %>" required />
        </div>
    </div>

    <div class="form-group">
        <label class="control-label col-md-2">考试地点</label>
        <div class="col-md-10">
            <input class="form-control" name="Location" value="<%= H(FormLocation) %>" required />
        </div>
    </div>

    <div class="form-group">
        <label class="control-label col-md-2">备注</label>
        <div class="col-md-10">
            <input class="form-control" name="Details" value="<%= H(FormDetails) %>" />
        </div>
    </div>

    <div class="form-group">
        <div class="col-md-offset-2 col-md-10">
            <button type="submit" class="btn btn-success">创建</button>
            <a class="btn btn-default" href="ExamList.aspx">返回列表</a>
        </div>
    </div>
</form>

<!--#include file="_AdminLayoutBottom.inc" -->
