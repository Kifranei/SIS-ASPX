<%@ Page Language="C#" AutoEventWireup="true" CodePage="65001" %>
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
        if (!EnsureAdminRole()) return;

        int classIdFromQuery;
        if (int.TryParse(Request.QueryString["classId"], out classIdFromQuery)) FormClassID = classIdFromQuery;

        if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
        {
            FormStudentID = (Request.Form["StudentID"] ?? string.Empty).Trim();
            FormStudentName = (Request.Form["StudentName"] ?? string.Empty).Trim();
            FormGender = NormalizeGender(Request.Form["Gender"]);
            int classId;
            if (int.TryParse(Request.Form["ClassID"], out classId)) FormClassID = classId;
            SaveStudent();
        }

        using (var db = new StudentManagementDBEntities())
        {
            ClassOptions = db.Classes.OrderBy(c => c.ClassName).ToList();
        }
    }

    private void SaveStudent()
    {
        if (string.IsNullOrWhiteSpace(FormStudentID) || string.IsNullOrWhiteSpace(FormStudentName)) { MessageText = "\u5B66\u53F7\u548C\u59D3\u540D\u4E0D\u80FD\u4E3A\u7A7A\u3002"; return; }
        if (!IsValidGender(FormGender)) { MessageText = "\u6027\u522B\u53EA\u80FD\u9009\u62E9\u201C\u7537\u201D\u6216\u201C\u5973\u201D\u3002"; return; }

        using (var db = new StudentManagementDBEntities())
        {
            if (db.Students.Any(s => s.StudentID == FormStudentID)) { MessageText = "\u8BE5\u5B66\u53F7\u5DF2\u5B58\u5728\u3002"; return; }
            if (db.Users.Any(u => u.Username == FormStudentID)) { MessageText = "\u8BE5\u5B66\u53F7\u5DF2\u5360\u7528\u767B\u5F55\u8D26\u53F7\u3002"; return; }

            var newUser = new Users { Username = FormStudentID, Password = StudentInformationSystem.Helpers.PasswordSecurity.HashPassword("Hzd@123456"), Role = 2 };
            var student = new Students { StudentID = FormStudentID, StudentName = FormStudentName, Gender = FormGender, ClassID = FormClassID, Users = newUser };
            db.Users.Add(newUser); db.Students.Add(student); db.SaveChanges();
            Session["AdminFlashMessage"] = "\u5B66\u751F " + FormStudentName + " \u6DFB\u52A0\u6210\u529F\uFF0C\u9ED8\u8BA4\u5BC6\u7801\u4E3A Hzd@123456\u3002";
            Response.Redirect("StudentList.aspx", true);
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->
<h2>添加新学生</h2>
<% if (!string.IsNullOrEmpty(MessageText)) { %><div class="alert alert-danger"><%= H(MessageText) %></div><% } %>
<form method="post" class="form-horizontal" style="max-width:900px;">
    <h4>学生信息</h4><hr />
    <div class="form-group"><label class="control-label col-md-2">学生学号</label><div class="col-md-10"><input class="form-control" name="StudentID" value="<%= H(FormStudentID) %>" required /></div></div>
    <div class="form-group"><label class="control-label col-md-2">姓名</label><div class="col-md-10"><input class="form-control" name="StudentName" value="<%= H(FormStudentName) %>" required /></div></div>
    <div class="form-group"><label class="control-label col-md-2">性别</label><div class="col-md-10"><select class="form-control" name="Gender" required><option value="">--请选择性别--</option><option value="男" <%= FormGender == "男" ? "selected" : "" %>>男</option><option value="女" <%= FormGender == "女" ? "selected" : "" %>>女</option></select></div></div>
    <div class="form-group"><label class="control-label col-md-2">班级</label><div class="col-md-10"><select class="form-control" name="ClassID"><option value="">--请选择班级--</option><% foreach (var cls in ClassOptions) { %><option value="<%= cls.ClassID %>" <%= FormClassID.HasValue && FormClassID.Value == cls.ClassID ? "selected" : "" %>><%= H(cls.ClassName) %></option><% } %></select></div></div>
    <div class="form-group"><div class="col-md-offset-2 col-md-10"><button type="submit" class="btn btn-success">创建</button> <a class="btn btn-default" href="StudentList.aspx">返回列表</a></div></div>
</form>
<!--#include file="_AdminLayoutBottom.inc" -->
