<%@ Page Language="C#" AutoEventWireup="true" CodePage="65001" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected string MessageText = string.Empty;
    protected string FormTeacherID = string.Empty;
    protected string FormTeacherName = string.Empty;
    protected string FormTitle = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "添加新教师";
        if (!EnsureAdminRole()) return;
        if (!Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase)) return;

        FormTeacherID = (Request.Form["TeacherID"] ?? string.Empty).Trim();
        FormTeacherName = (Request.Form["TeacherName"] ?? string.Empty).Trim();
        FormTitle = (Request.Form["Title"] ?? string.Empty).Trim();

        if (string.IsNullOrWhiteSpace(FormTeacherID) || string.IsNullOrWhiteSpace(FormTeacherName)) { MessageText = "\u6559\u5E08\u5DE5\u53F7\u548C\u59D3\u540D\u4E0D\u80FD\u4E3A\u7A7A\u3002"; return; }

        using (var db = new StudentManagementDBEntities())
        {
            if (db.Teachers.Any(t => t.TeacherID == FormTeacherID)) { MessageText = "\u8BE5\u6559\u5E08\u5DE5\u53F7\u5DF2\u5B58\u5728\u3002"; return; }
            if (db.Users.Any(u => u.Username == FormTeacherID)) { MessageText = "\u8BE5\u5DE5\u53F7\u5DF2\u5360\u7528\u767B\u5F55\u8D26\u53F7\u3002"; return; }

            var newUser = new Users { Username = FormTeacherID, Password = StudentInformationSystem.Helpers.PasswordSecurity.HashPassword("Hzd@123456"), Role = 1 };
            var teacher = new Teachers { TeacherID = FormTeacherID, TeacherName = FormTeacherName, Title = FormTitle, Users = newUser };
            db.Users.Add(newUser); db.Teachers.Add(teacher); db.SaveChanges();
            Session["AdminFlashMessage"] = "\u6559\u5E08 " + FormTeacherName + " \u6DFB\u52A0\u6210\u529F\uFF0C\u9ED8\u8BA4\u5BC6\u7801\u4E3A Hzd@123456\u3002";
            Response.Redirect("TeacherList.aspx", true);
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->
<h2>添加新教师</h2>
<% if (!string.IsNullOrEmpty(MessageText)) { %><div class="alert alert-danger"><%= H(MessageText) %></div><% } %>
<form method="post" class="form-horizontal" style="max-width:900px;">
    <h4>教师信息</h4><hr />
    <div class="form-group"><label class="control-label col-md-2">教师工号</label><div class="col-md-10"><input class="form-control" name="TeacherID" value="<%= H(FormTeacherID) %>" required /></div></div>
    <div class="form-group"><label class="control-label col-md-2">姓名</label><div class="col-md-10"><input class="form-control" name="TeacherName" value="<%= H(FormTeacherName) %>" required /></div></div>
    <div class="form-group"><label class="control-label col-md-2">职称</label><div class="col-md-10"><input class="form-control" name="Title" value="<%= H(FormTitle) %>" /></div></div>
    <div class="form-group"><div class="col-md-offset-2 col-md-10"><button type="submit" class="btn btn-success">创建</button> <a class="btn btn-default" href="TeacherList.aspx">返回列表</a></div></div>
</form>
<!--#include file="_AdminLayoutBottom.inc" -->
