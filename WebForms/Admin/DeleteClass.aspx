<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Classes CurrentClass;
    protected string MessageText = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "删除班级";
        if (!EnsureAdminRole())
        {
            return;
        }

        int id;
        if (!int.TryParse(Request.QueryString["id"] ?? Request.Form["ClassID"], out id) || id <= 0)
        {
            MessageText = "班级参数无效。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            CurrentClass = db.Classes.Find(id);
            if (CurrentClass == null)
            {
                MessageText = "班级不存在。";
                return;
            }

            if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
            {
                var hasStudents = db.Students.Any(s => s.ClassID == id);
                if (hasStudents)
                {
                    Session["AdminFlashError"] = "删除失败！该班级下仍有学生，请先转移或删除学生。";
                    Response.Redirect("ClassList.aspx", true);
                    return;
                }

                db.Classes.Remove(CurrentClass);
                db.SaveChanges();
                Session["AdminFlashMessage"] = "班级删除成功！";
                Response.Redirect("ClassList.aspx", true);
            }
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>删除班级</h2>

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } else { %>
    <h3>您确定要删除这个班级吗？</h3>
    <div>
        <h4><%= H(CurrentClass.ClassName) %></h4>
        <hr />
        <dl class="dl-horizontal">
            <dt>班级名称</dt>
            <dd><%= H(CurrentClass.ClassName) %></dd>

            <dt>专业</dt>
            <dd><%= H(CurrentClass.Major) %></dd>

            <dt>学年</dt>
            <dd><%= CurrentClass.AcademicYear.HasValue ? CurrentClass.AcademicYear.Value.ToString() : "-" %></dd>

            <dt>班号</dt>
            <dd><%= CurrentClass.ClassNumber.HasValue ? CurrentClass.ClassNumber.Value.ToString() : "-" %></dd>
        </dl>

        <form method="post" class="form-actions no-color">
            <input type="hidden" name="ClassID" value="<%= CurrentClass.ClassID %>" />
            <button type="submit" class="btn btn-danger">确认删除</button>
            <a class="btn btn-default" href="ClassList.aspx">返回列表</a>
        </form>
    </div>
<% } %>

<!--#include file="_AdminLayoutBottom.inc" -->
