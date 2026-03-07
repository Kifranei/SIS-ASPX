<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Teachers CurrentTeacher;
    protected string MessageText = string.Empty;

    protected string FormTeacherID = string.Empty;
    protected string FormTeacherName = string.Empty;
    protected string FormTitle = string.Empty;
    protected int FormUserID = 0;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "编辑教师信息";
        if (!EnsureAdminRole())
        {
            return;
        }

        if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
        {
            FormTeacherID = (Request.Form["TeacherID"] ?? string.Empty).Trim();
            FormTeacherName = (Request.Form["TeacherName"] ?? string.Empty).Trim();
            FormTitle = (Request.Form["Title"] ?? string.Empty).Trim();
            int uid;
            if (int.TryParse(Request.Form["UserID"], out uid))
            {
                FormUserID = uid;
            }

            SaveTeacher();
        }
        else
        {
            var id = (Request.QueryString["id"] ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(id))
            {
                MessageText = "缺少教师ID参数。";
            }
            else
            {
                using (var db = new StudentManagementDBEntities())
                {
                    CurrentTeacher = db.Teachers.Find(id);
                }

                if (CurrentTeacher == null)
                {
                    MessageText = "教师不存在。";
                }
                else
                {
                    FormTeacherID = CurrentTeacher.TeacherID;
                    FormTeacherName = CurrentTeacher.TeacherName;
                    FormTitle = CurrentTeacher.Title;
                    FormUserID = CurrentTeacher.UserID;
                }
            }
        }
    }

    private void SaveTeacher()
    {
        if (string.IsNullOrWhiteSpace(FormTeacherID) || string.IsNullOrWhiteSpace(FormTeacherName))
        {
            MessageText = "教师工号和姓名不能为空。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            var teacher = db.Teachers.Find(FormTeacherID);
            if (teacher == null)
            {
                MessageText = "教师不存在。";
                return;
            }

            teacher.TeacherName = FormTeacherName;
            teacher.Title = FormTitle;
            if (FormUserID > 0)
            {
                teacher.UserID = FormUserID;
            }

            db.Entry(teacher).State = EntityState.Modified;
            db.SaveChanges();

            Response.Redirect("TeacherList.aspx", true);
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>编辑教师信息</h2>
<% if (!string.IsNullOrWhiteSpace(FormTeacherName)) { %>
    <h4><%= H(FormTeacherName) %></h4>
<% } %>
<hr />

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } else { %>
    <form method="post" class="form-horizontal" style="max-width:900px;">
        <input type="hidden" name="TeacherID" value="<%= H(FormTeacherID) %>" />
        <input type="hidden" name="UserID" value="<%= FormUserID %>" />

        <div class="form-group">
            <label class="control-label col-md-2">教师工号 (不可修改)</label>
            <div class="col-md-10">
                <input class="form-control" value="<%= H(FormTeacherID) %>" readonly />
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
                <button type="submit" class="btn btn-success">保 存</button>
                <a class="btn btn-default" href="TeacherList.aspx">返回列表</a>
            </div>
        </div>
    </form>
<% } %>

<!--#include file="_AdminLayoutBottom.inc" -->
