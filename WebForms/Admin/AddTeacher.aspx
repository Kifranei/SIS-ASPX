<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected string MessageText = string.Empty;
    protected string FormTeacherID = string.Empty;
    protected string FormTeacherName = string.Empty;
    protected string FormTitle = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "添加新教师";
        if (!EnsureAdminRole())
        {
            return;
        }

        if (!Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        FormTeacherID = (Request.Form["TeacherID"] ?? string.Empty).Trim();
        FormTeacherName = (Request.Form["TeacherName"] ?? string.Empty).Trim();
        FormTitle = (Request.Form["Title"] ?? string.Empty).Trim();

        if (string.IsNullOrWhiteSpace(FormTeacherID) || string.IsNullOrWhiteSpace(FormTeacherName))
        {
            MessageText = "教师工号和姓名不能为空。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            if (db.Teachers.Any(t => t.TeacherID == FormTeacherID))
            {
                MessageText = "该教师工号已存在。";
                return;
            }

            if (db.Users.Any(u => u.Username == FormTeacherID))
            {
                MessageText = "该工号已占用登录账号。";
                return;
            }

            var newUser = new Users
            {
                Username = FormTeacherID,
                Password = "Hzd@123456",
                Role = 1
            };

            var teacher = new Teachers
            {
                TeacherID = FormTeacherID,
                TeacherName = FormTeacherName,
                Title = FormTitle,
                Users = newUser
            };

            db.Users.Add(newUser);
            db.Teachers.Add(teacher);
            db.SaveChanges();

            Session["AdminFlashMessage"] = "教师 " + FormTeacherName + " 添加成功！默认密码为：Hzd@123456";
            Response.Redirect("TeacherList.aspx", true);
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>添加新教师</h2>

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } %>

<form method="post" class="form-horizontal" style="max-width:900px;">
    <h4>教师信息</h4>
    <hr />

    <div class="form-group">
        <label class="control-label col-md-2">教师工号</label>
        <div class="col-md-10">
            <input class="form-control" name="TeacherID" value="<%= H(FormTeacherID) %>" required />
        </div>
    </div>

    <div class="form-group">
        <label class="control-label col-md-2">姓名</label>
        <div class="col-md-10">
            <input class="form-control" name="TeacherName" value="<%= H(FormTeacherName) %>" required />
        </div>
    </div>

    <div class="form-group">
        <label class="control-label col-md-2">职称</label>
        <div class="col-md-10">
            <input class="form-control" name="Title" value="<%= H(FormTitle) %>" />
        </div>
    </div>

    <div class="form-group">
        <div class="col-md-offset-2 col-md-10">
            <button type="submit" class="btn btn-success">创建</button>
            <a class="btn btn-default" href="TeacherList.aspx">返回列表</a>
        </div>
    </div>
</form>

<!--#include file="_AdminLayoutBottom.inc" -->
