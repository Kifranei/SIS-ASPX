<%@ Page CodePage="65001" Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected string MessageText = string.Empty;
    protected List<Teachers> TeacherOptions = new List<Teachers>();

    protected string FormCourseName = string.Empty;
    protected string FormCredits = string.Empty;
    protected string FormTeacherID = string.Empty;
    protected string FormCourseType = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "添加新课程";
        if (!EnsureAdminRole())
        {
            return;
        }

        if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
        {
            FormCourseName = (Request.Form["CourseName"] ?? string.Empty).Trim();
            FormCredits = (Request.Form["Credits"] ?? string.Empty).Trim();
            FormTeacherID = (Request.Form["TeacherID"] ?? string.Empty).Trim();
            FormCourseType = (Request.Form["CourseType"] ?? string.Empty).Trim();
            SaveCourse();
        }

        using (var db = new StudentManagementDBEntities())
        {
            TeacherOptions = db.Teachers.OrderBy(t => t.TeacherName).ToList();
        }
    }

    private void SaveCourse()
    {
        if (string.IsNullOrWhiteSpace(FormCourseName))
        {
            MessageText = "课程名称不能为空。";
            return;
        }

        double credits;
        if (!double.TryParse(FormCredits, out credits))
        {
            MessageText = "学分格式不正确。";
            return;
        }

        int courseType;
        if (!int.TryParse(FormCourseType, out courseType))
        {
            MessageText = "请选择课程类别。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            var course = new Courses
            {
                CourseName = FormCourseName,
                Credits = credits,
                TeacherID = string.IsNullOrWhiteSpace(FormTeacherID) ? null : FormTeacherID,
                CourseType = courseType
            };

            db.Courses.Add(course);
            db.SaveChanges();
            Response.Redirect("CourseList.aspx", true);
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>添加新课程</h2>

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } %>

<form method="post" class="form-horizontal" style="max-width:900px;">
    <h4>课程信息</h4>
    <hr />

    <div class="form-group">
        <label class="control-label col-md-2">课程名称</label>
        <div class="col-md-10">
            <input class="form-control" name="CourseName" value="<%= H(FormCourseName) %>" required />
        </div>
    </div>

    <div class="form-group">
        <label class="control-label col-md-2">学分</label>
        <div class="col-md-10">
            <input class="form-control" name="Credits" value="<%= H(FormCredits) %>" required />
        </div>
    </div>

    <div class="form-group">
        <label class="control-label col-md-2">授课教师</label>
        <div class="col-md-10">
            <select class="form-control" name="TeacherID">
                <option value="">--请选择教师--</option>
                <% foreach (var t in TeacherOptions) { %>
                    <option value="<%= H(t.TeacherID) %>" <%= string.Equals(FormTeacherID, t.TeacherID, StringComparison.OrdinalIgnoreCase) ? "selected" : "" %>><%= H(t.TeacherName) %></option>
                <% } %>
            </select>
        </div>
    </div>

    <div class="form-group">
        <label class="control-label col-md-2">课程类别</label>
        <div class="col-md-10">
            <select class="form-control" name="CourseType" required>
                <option value="">--请选择类别--</option>
                <option value="1" <%= FormCourseType == "1" ? "selected" : "" %>>专业必修</option>
                <option value="2" <%= FormCourseType == "2" ? "selected" : "" %>>公共必修</option>
                <option value="3" <%= FormCourseType == "3" ? "selected" : "" %>>专业选修</option>
                <option value="4" <%= FormCourseType == "4" ? "selected" : "" %>>公共选修</option>
                <option value="5" <%= FormCourseType == "5" ? "selected" : "" %>>体育选修</option>
            </select>
        </div>
    </div>

    <div class="form-group">
        <div class="col-md-offset-2 col-md-10">
            <button type="submit" class="btn btn-success">创建</button>
            <a class="btn btn-default" href="CourseList.aspx">返回列表</a>
        </div>
    </div>
</form>

<!--#include file="_AdminLayoutBottom.inc" -->
