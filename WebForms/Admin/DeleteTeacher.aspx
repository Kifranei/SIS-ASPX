<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Teachers CurrentTeacher;
    protected string MessageText = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "删除教师";
        if (!EnsureAdminRole())
        {
            return;
        }

        var id = (Request.QueryString["id"] ?? Request.Form["TeacherID"] ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(id))
        {
            MessageText = "缺少教师ID参数。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            CurrentTeacher = db.Teachers.Include("Courses").FirstOrDefault(t => t.TeacherID == id);
            if (CurrentTeacher == null)
            {
                MessageText = "教师不存在。";
                return;
            }

            if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
            {
                foreach (var course in CurrentTeacher.Courses.ToList())
                {
                    course.TeacherID = null;
                }

                var user = db.Users.Find(CurrentTeacher.UserID);
                db.Teachers.Remove(CurrentTeacher);
                if (user != null)
                {
                    db.Users.Remove(user);
                }

                db.SaveChanges();
                Response.Redirect("TeacherList.aspx", true);
            }
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>删除教师</h2>

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } else { %>
    <h3 class="text-danger">您确定要删除这位教师吗？其登录账号也将一并移除。</h3>
    <div>
        <h4><%= H(CurrentTeacher.TeacherName) %></h4>
        <hr />
        <dl class="dl-horizontal">
            <dt>教师工号</dt>
            <dd><%= H(CurrentTeacher.TeacherID) %></dd>

            <dt>姓名</dt>
            <dd><%= H(CurrentTeacher.TeacherName) %></dd>

            <dt>职称</dt>
            <dd><%= H(CurrentTeacher.Title) %></dd>
        </dl>

        <form method="post" class="form-actions no-color">
            <input type="hidden" name="TeacherID" value="<%= H(CurrentTeacher.TeacherID) %>" />
            <button type="submit" class="btn btn-danger">确认删除</button>
            <a class="btn btn-default" href="TeacherList.aspx">返回列表</a>
        </form>
    </div>
<% } %>

<!--#include file="_AdminLayoutBottom.inc" -->
