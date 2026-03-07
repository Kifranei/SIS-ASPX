<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Students CurrentStudent;
    protected string MessageText = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "删除学生";
        if (!EnsureAdminRole())
        {
            return;
        }

        var id = (Request.QueryString["id"] ?? Request.Form["StudentID"] ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(id))
        {
            MessageText = "缺少学生ID参数。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            CurrentStudent = db.Students.Include("Classes").FirstOrDefault(s => s.StudentID == id);
            if (CurrentStudent == null)
            {
                MessageText = "学生不存在。";
                return;
            }

            if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
            {
                var user = db.Users.Find(CurrentStudent.UserID);

                var enrollments = db.StudentCourses.Where(sc => sc.StudentID == CurrentStudent.StudentID).ToList();
                if (enrollments.Any())
                {
                    db.StudentCourses.RemoveRange(enrollments);
                }

                var passkeys = db.Passkeys.Where(p => p.UserId == CurrentStudent.UserID).ToList();
                if (passkeys.Any())
                {
                    db.Passkeys.RemoveRange(passkeys);
                }

                db.Students.Remove(CurrentStudent);
                if (user != null)
                {
                    db.Users.Remove(user);
                }

                db.SaveChanges();
                Response.Redirect("StudentList.aspx", true);
            }
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>删除学生</h2>

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } else { %>
    <h3 class="text-danger">您确定要删除这位学生吗？此操作不可恢复。</h3>
    <div>
        <h4><%= H(CurrentStudent.StudentName) %></h4>
        <hr />
        <dl class="dl-horizontal">
            <dt>学号</dt>
            <dd><%= H(CurrentStudent.StudentID) %></dd>

            <dt>姓名</dt>
            <dd><%= H(CurrentStudent.StudentName) %></dd>

            <dt>班级</dt>
            <dd><%= CurrentStudent.Classes == null ? "-" : H(CurrentStudent.Classes.ClassName) %></dd>
        </dl>

        <form method="post" class="form-actions no-color">
            <input type="hidden" name="StudentID" value="<%= H(CurrentStudent.StudentID) %>" />
            <button type="submit" class="btn btn-danger">确认删除</button>
            <a class="btn btn-default" href="StudentList.aspx">返回列表</a>
        </form>
    </div>
<% } %>

<!--#include file="_AdminLayoutBottom.inc" -->


