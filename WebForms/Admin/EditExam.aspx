<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.Data.Entity" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Exams CurrentExam;
    protected List<Courses> CourseOptions = new List<Courses>();
    protected string MessageText = string.Empty;

    protected int FormExamID = 0;
    protected string FormCourseID = string.Empty;
    protected string FormStartTime = string.Empty;
    protected string FormEndTime = string.Empty;
    protected string FormLocation = string.Empty;
    protected string FormDetails = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "�༭������Ϣ";
        if (!EnsureAdminRole())
        {
            return;
        }

        if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
        {
            int.TryParse(Request.Form["ExamID"], out FormExamID);
            FormCourseID = (Request.Form["CourseID"] ?? string.Empty).Trim();
            FormStartTime = (Request.Form["StartTime"] ?? string.Empty).Trim();
            FormEndTime = (Request.Form["EndTime"] ?? string.Empty).Trim();
            FormLocation = (Request.Form["Location"] ?? string.Empty).Trim();
            FormDetails = (Request.Form["Details"] ?? string.Empty).Trim();
            SaveExam();
        }
        else
        {
            int id;
            if (!int.TryParse(Request.QueryString["id"], out id) || id <= 0)
            {
                MessageText = "���Բ�����Ч��";
            }
            else
            {
                using (var db = new StudentManagementDBEntities())
                {
                    CurrentExam = db.Exams.Include("Courses").FirstOrDefault(ei => ei.ExamID == id);
                }

                if (CurrentExam == null)
                {
                    MessageText = "���Լ�¼�����ڡ�";
                }
                else
                {
                    FormExamID = CurrentExam.ExamID;
                    FormCourseID = CurrentExam.CourseID.ToString();
                    FormStartTime = CurrentExam.StartTime.ToString("yyyy-MM-ddTHH:mm");
                    FormEndTime = CurrentExam.EndTime.ToString("yyyy-MM-ddTHH:mm");
                    FormLocation = CurrentExam.Location;
                    FormDetails = CurrentExam.Details;
                }
            }
        }

        using (var db = new StudentManagementDBEntities())
        {
            CourseOptions = db.Courses.OrderBy(c => c.CourseName).ToList();
        }
    }

    private void SaveExam()
    {
        int courseId;
        DateTime startTime;
        DateTime endTime;
        if (FormExamID <= 0 || !int.TryParse(FormCourseID, out courseId) || !DateTime.TryParse(FormStartTime, out startTime) || !DateTime.TryParse(FormEndTime, out endTime) || endTime <= startTime || string.IsNullOrWhiteSpace(FormLocation))
        {
            MessageText = "����ȷ��д�γ̡�����ʱ��Ϳ��Եص㡣";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            var exam = db.Exams.Find(FormExamID);
            if (exam == null)
            {
                MessageText = "���Լ�¼�����ڡ�";
                return;
            }

            var course = db.Courses.Find(courseId);
            var teacherConflicts = GetTeacherExamConflicts(
                db,
                course == null ? null : course.TeacherID,
                startTime,
                endTime,
                FormExamID);
            if (teacherConflicts.Any())
            {
                MessageText = BuildTeacherExamConflictMessage(
                    teacherConflicts,
                    "����ʱ���ͻ���ý�ʦ�ڸ�ʱ���������¿��԰��ţ�");
                return;
            }

            var studentConflicts = GetStudentExamConflictsForCourse(
                db,
                courseId,
                startTime,
                endTime,
                FormExamID);
            if (studentConflicts.Any())
            {
                MessageText = BuildStudentExamConflictMessage(
                    studentConflicts,
                    "����ʱ���ͻ������ѧ���ڸ�ʱ�������������ԣ�");
                return;
            }

            exam.CourseID = courseId;
            exam.StartTime = startTime;
            exam.EndTime = endTime;
            exam.Location = FormLocation;
            exam.Details = FormDetails;
            db.Entry(exam).State = EntityState.Modified;
            db.SaveChanges();

            Response.Redirect("ExamList.aspx", true);
        }
    }

    private List<Exams> GetTeacherExamConflicts(StudentManagementDBEntities db, string teacherId, DateTime startTime, DateTime endTime, int? excludeExamId = null)
    {
        if (string.IsNullOrWhiteSpace(teacherId))
        {
            return new List<Exams>();
        }

        var query = db.Exams
            .Include("Courses")
            .Where(e => e.StartTime < endTime && e.EndTime > startTime && e.Courses != null && e.Courses.TeacherID == teacherId);

        if (excludeExamId.HasValue)
        {
            int examId = excludeExamId.Value;
            query = query.Where(e => e.ExamID != examId);
        }

        return query.OrderBy(e => e.Courses.CourseName).ToList();
    }

    private List<string> GetStudentExamConflictsForCourse(StudentManagementDBEntities db, int courseId, DateTime startTime, DateTime endTime, int? excludeExamId = null)
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
                && sc.Courses.Exams.Any(e => e.StartTime < endTime && e.EndTime > startTime && (!excludeExamId.HasValue || e.ExamID != excludeExamId.Value)))
            .Select(sc => sc.StudentID + " " + sc.Students.StudentName + " -> " + sc.Courses.CourseName)
            .Distinct();

        return query.OrderBy(x => x).ToList();
    }

    private string BuildTeacherExamConflictMessage(IEnumerable<Exams> conflicts, string prefix)
    {
        return prefix + " " + string.Join("��", conflicts.Select(e => (e.Courses == null ? "δ֪�γ�" : e.Courses.CourseName) + "��" + e.StartTime.ToString("yyyy-MM-dd HH:mm") + " - " + e.EndTime.ToString("HH:mm") + "��"));
    }

    private string BuildStudentExamConflictMessage(IEnumerable<string> conflicts, string prefix)
    {
        return prefix + " " + string.Join("��", conflicts);
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>�༭������Ϣ</h2>

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } else { %>
    <form method="post" class="form-horizontal" style="max-width:900px;">
        <input type="hidden" name="ExamID" value="<%= FormExamID %>" />

        <div class="form-group">
            <label class="control-label col-md-2">���Կ�Ŀ</label>
            <div class="col-md-10">
                <select class="form-control" name="CourseID" required>
                    <% foreach (var c in CourseOptions) { %>
                        <option value="<%= c.CourseID %>" <%= FormCourseID == c.CourseID.ToString() ? "selected" : "" %>><%= H(c.CourseName) %></option>
                    <% } %>
                </select>
            </div>
        </div>

        <div class="form-group">
            <label class="control-label col-md-2">����ʱ��</label>
            <div class="col-md-10">
                <input class="form-control" type="datetime-local" name="StartTime" value="<%= H(FormStartTime) %>" required />
        </div>
    </div>

    <div class="form-group">
        <label class="control-label col-md-2">考试结束时间</label>
        <div class="col-md-10">
            <input class="form-control" type="datetime-local" name="EndTime" value="<%= H(FormEndTime) %>" required />
            </div>
        </div>

        <div class="form-group">
            <label class="control-label col-md-2">���Եص�</label>
            <div class="col-md-10">
                <input class="form-control" name="Location" value="<%= H(FormLocation) %>" required />
            </div>
        </div>

        <div class="form-group">
            <label class="control-label col-md-2">��ע</label>
            <div class="col-md-10">
                <input class="form-control" name="Details" value="<%= H(FormDetails) %>" />
            </div>
        </div>

        <div class="form-group">
            <div class="col-md-offset-2 col-md-10">
                <button type="submit" class="btn btn-success">�� ��</button>
                <a class="btn btn-default" href="ExamList.aspx">�����б�</a>
            </div>
        </div>
    </form>
<% } %>

<!--#include file="_AdminLayoutBottom.inc" -->
