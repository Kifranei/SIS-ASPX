<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected string SearchString = string.Empty;
    protected string FlashMessage = string.Empty;
    protected List<Students> StudentsList = new List<Students>();

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "学生列表";
        if (!EnsureAdminRole())
        {
            return;
        }

        if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase) && !string.IsNullOrWhiteSpace(Request.Form["ResetUserID"]))
        {
            SearchString = (Request.Form["searchString"] ?? string.Empty).Trim();
            ResetPassword_Click(null, EventArgs.Empty);
            return;
        }

        SearchString = (Request.QueryString["searchString"] ?? string.Empty).Trim();
        FlashMessage = (Session["AdminFlashMessage"] as string) ?? string.Empty;
        Session.Remove("AdminFlashMessage");

        using (var db = new StudentManagementDBEntities())
        {
            var query = db.Students.Include("Classes").Include("Users").AsQueryable();
            if (!string.IsNullOrWhiteSpace(SearchString))
            {
                query = query.Where(s => s.StudentName.Contains(SearchString) || s.StudentID.Contains(SearchString));
            }

            StudentsList = query.OrderBy(s => s.StudentID).ToList();
        }
    }

    protected void ResetPassword_Click(object sender, EventArgs e)
    {
        var userIdValue = Request.Form["ResetUserID"];
        int userId;
        if (!int.TryParse(userIdValue, out userId) || userId <= 0)
        {
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            var userToReset = db.Users.Find(userId);
            if (userToReset == null)
            {
                return;
            }

            userToReset.Password = "Hzd@123456";
            db.Entry(userToReset).State = EntityState.Modified;
            db.SaveChanges();

            Session["AdminFlashMessage"] = "用户 " + (userToReset.Username ?? "") + " 的密码已成功重置为 \"Hzd@123456\"。";
        }

        var target = "StudentList.aspx" + BuildQueryString(new KeyValuePair<string, string>("searchString", SearchString));
        Response.Redirect(target, true);
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>学生列表</h2>

<% if (!string.IsNullOrEmpty(FlashMessage)) { %>
    <div class="alert alert-success"><%= H(FlashMessage) %></div>
<% } %>

<form method="get" class="form-inline">
    <div class="form-group">
        <label>查找学生:</label>
        <input type="text" name="searchString" value="<%= H(SearchString) %>" class="form-control" placeholder="输入姓名或学号" />
    </div>
    <button type="submit" class="btn btn-default">搜 索</button>
</form>
<br />
<p><a class="btn btn-primary" href="AddStudent.aspx">添加新学生</a></p>

<div class="table-responsive">
    <table class="table table-striped table-bordered">
        <thead>
            <tr>
                <th>学生姓名</th>
                <th>性别</th>
                <th>班级</th>
                <th>登录账号</th>
                <th>操作</th>
            </tr>
        </thead>
        <tbody>
            <% if (StudentsList.Any()) { %>
                <% foreach (var item in StudentsList) { %>
                    <tr>
                        <td><%= H(item.StudentName) %></td>
                        <td><%= H(item.Gender) %></td>
                        <td><%= item.Classes == null ? "-" : H(item.Classes.ClassName) %></td>
                        <td><%= item.Users == null ? "-" : H(item.Users.Username) %></td>
                        <td>
                            <a href='Edit.aspx?id=<%= Server.UrlEncode(item.StudentID) %>'>编辑</a> |
                            <a href='Details.aspx?id=<%= Server.UrlEncode(item.StudentID) %>'>详情</a> |
                            <a href='Delete.aspx?id=<%= Server.UrlEncode(item.StudentID) %>'>删除</a> |
                            <form method="post" style="display:inline;" onsubmit='return confirm("您确定要将用户 <%= H(item.Users == null ? item.StudentID : item.Users.Username) %> 的密码重置为 Hzd@123456 吗？");'>
                                <input type="hidden" name="ResetUserID" value="<%= item.UserID %>" />
                                <input type="hidden" name="searchString" value="<%= H(SearchString) %>" />
                                <button type="submit" class="btn btn-link" style="padding:0;border:0;vertical-align:baseline;">重置密码</button>
                            </form>
                        </td>
                    </tr>
                <% } %>
            <% } else { %>
                <tr><td colspan="5" class="text-center text-muted">暂无学生记录。</td></tr>
            <% } %>
        </tbody>
    </table>
</div>

<!--#include file="_AdminLayoutBottom.inc" -->
