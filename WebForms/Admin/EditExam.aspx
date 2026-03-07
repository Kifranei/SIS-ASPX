<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Exams CurrentExam;
    protected List<Courses> CourseOptions = new List<Courses>();
    protected string MessageText = string.Empty;

    protected int FormExamID = 0;
    protected string FormCourseID = string.Empty;
    protected string FormExamTime = string.Empty;
    protected string FormLocation = string.Empty;
    protected string FormDetails = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "编辑考试信息";
        if (!EnsureAdminRole())
        {
            return;
        }

        if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
        {
            int.TryParse(Request.Form["ExamID"], out FormExamID);
            FormCourseID = (Request.Form["CourseID"] ?? string.Empty).Trim();
            FormExamTime = (Request.Form["ExamTime"] ?? string.Empty).Trim();
            FormLocation = (Request.Form["Location"] ?? string.Empty).Trim();
            FormDetails = (Request.Form["Details"] ?? string.Empty).Trim();
            SaveExam();
        }
        else
        {
            int id;
            if (!int.TryParse(Request.QueryString["id"], out id) || id <= 0)
            {
                MessageText = "考试参数无效。";
            }
            else
            {
                using (var db = new StudentManagementDBEntities())
                {
                    CurrentExam = db.Exams.Include("Courses").FirstOrDefault(ei => ei.ExamID == id);
                }

                if (CurrentExam == null)
                {
                    MessageText = "考试记录不存在。";
                }
                else
                {
                    FormExamID = CurrentExam.ExamID;
                    FormCourseID = CurrentExam.CourseID.ToString();
                    FormExamTime = CurrentExam.ExamTime.ToString("yyyy-MM-ddTHH:mm");
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
        DateTime examTime;
        if (FormExamID <= 0 || !int.TryParse(FormCourseID, out courseId) || !DateTime.TryParse(FormExamTime, out examTime) || string.IsNullOrWhiteSpace(FormLocation))
        {
            MessageText = "请正确填写课程、考试时间和考试地点。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            var exam = db.Exams.Find(FormExamID);
            if (exam == null)
            {
                MessageText = "考试记录不存在。";
                return;
            }

            exam.CourseID = courseId;
            exam.ExamTime = examTime;
            exam.Location = FormLocation;
            exam.Details = FormDetails;
            db.Entry(exam).State = EntityState.Modified;
            db.SaveChanges();

            Response.Redirect("ExamList.aspx", true);
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>编辑考试信息</h2>

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } else { %>
    <form method="post" class="form-horizontal" style="max-width:900px;">
        <input type="hidden" name="ExamID" value="<%= FormExamID %>" />

        <div class="form-group">
            <label class="control-label col-md-2">考试科目</label>
            <div class="col-md-10">
                <select class="form-control" name="CourseID" required>
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
                <button type="submit" class="btn btn-success">保 存</button>
                <a class="btn btn-default" href="ExamList.aspx">返回列表</a>
            </div>
        </div>
    </form>
<% } %>

<!--#include file="_AdminLayoutBottom.inc" -->
