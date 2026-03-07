<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected List<Classes> ClassOptions = new List<Classes>();
    protected string MessageText = string.Empty;

    protected string FormStudentID = string.Empty;
    protected string FormStudentName = string.Empty;
    protected string FormGender = string.Empty;
    protected int? FormClassID = null;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "添加新学生";
        if (!EnsureAdminRole())
        {
            return;
        }

        int classIdFromQuery;
        if (int.TryParse(Request.QueryString["classId"], out classIdFromQuery))
        {
            FormClassID = classIdFromQuery;
        }

        if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
        {
            FormStudentID = (Request.Form["StudentID"] ?? string.Empty).Trim();
            FormStudentName = (Request.Form["StudentName"] ?? string.Empty).Trim();
            FormGender = NormalizeGender(Request.Form["Gender"]);
            int classId;
            if (int.TryParse(Request.Form["ClassID"], out classId))
            {
                FormClassID = classId;
            }

            SaveStudent();
        }

        using (var db = new StudentManagementDBEntities())
        {
            ClassOptions = db.Classes.OrderBy(c => c.ClassName).ToList();
        }
    }

    private void SaveStudent()
    {
        if (string.IsNullOrWhiteSpace(FormStudentID) || string.IsNullOrWhiteSpace(FormStudentName))
        {
            MessageText = "学号和姓名不能为空。";
            return;
        }

        if (!IsValidGender(FormGender))
        {
            MessageText = "性别只能选择“男”或“女”。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            if (db.Students.Any(s => s.StudentID == FormStudentID))
            {
                MessageText = "该学号已存在。";
                return;
            }

            if (db.Users.Any(u => u.Username == FormStudentID))
            {
                MessageText = "该学号已占用登录账号。";
                return;
            }

            var newUser = new Users
            {
                Username = FormStudentID,
                Password = "Hzd@123456",
                Role = 2
            };

            var student = new Students
            {
                StudentID = FormStudentID,
                StudentName = FormStudentName,
                Gender = FormGender,
                ClassID = FormClassID,
                Users = newUser
            };

            db.Users.Add(newUser);
            db.Students.Add(student);
            db.SaveChanges();

            Session["AdminFlashMessage"] = "学生 " + FormStudentName + " 添加成功！默认密码为：Hzd@123456";
            Response.Redirect("StudentList.aspx", true);
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>添加新学生</h2>

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } %>

<form method="post" class="form-horizontal" style="max-width:900px;">
    <h4>学生信息</h4>
    <hr />

    <div class="form-group">
        <label class="control-label col-md-2">学生学号</label>
        <div class="col-md-10">
            <input class="form-control" name="StudentID" value="<%= H(FormStudentID) %>" required />
        </div>
    </div>

    <div class="form-group">
        <label class="control-label col-md-2">姓名</label>
        <div class="col-md-10">
            <input class="form-control" name="StudentName" value="<%= H(FormStudentName) %>" required />
        </div>
    </div>

    <div class="form-group">
        <label class="control-label col-md-2">性别</label>
        <div class="col-md-10">
            <select class="form-control" name="Gender" required>
                <option value="">--请选择性别--</option>
                <option value="男" <%= FormGender == "男" ? "selected" : "" %>>男</option>
                <option value="女" <%= FormGender == "女" ? "selected" : "" %>>女</option>
            </select>
        </div>
    </div>

    <div class="form-group">
        <label class="control-label col-md-2">班级</label>
        <div class="col-md-10">
            <select class="form-control" name="ClassID">
                <option value="">--请选择班级--</option>
                <% foreach (var cls in ClassOptions) { %>
                    <option value="<%= cls.ClassID %>" <%= FormClassID.HasValue && FormClassID.Value == cls.ClassID ? "selected" : "" %>><%= H(cls.ClassName) %></option>
                <% } %>
            </select>
        </div>
    </div>

    <div class="form-group">
        <div class="col-md-offset-2 col-md-10">
            <button type="submit" class="btn btn-success">创建</button>
            <a class="btn btn-default" href="StudentList.aspx">返回列表</a>
        </div>
    </div>
</form>

<!--#include file="_AdminLayoutBottom.inc" -->


