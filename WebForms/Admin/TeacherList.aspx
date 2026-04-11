<%@ Page Language="C#" AutoEventWireup="true" CodePage="65001" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected string SearchString = string.Empty;
    protected string FlashMessage = string.Empty;
    protected List<Teachers> TeachersList = new List<Teachers>();

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "教师列表";
        if (!EnsureAdminRole()) return;

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
            var query = db.Teachers.Include("Users").AsQueryable();
            if (!string.IsNullOrWhiteSpace(SearchString)) query = query.Where(t => t.TeacherName.Contains(SearchString) || t.TeacherID.Contains(SearchString));
            TeachersList = query.OrderBy(t => t.TeacherID).ToList();
        }
    }

    protected void ResetPassword_Click(object sender, EventArgs e)
    {
        var userIdValue = Request.Form["ResetUserID"];
        int userId;
        if (!int.TryParse(userIdValue, out userId) || userId <= 0) return;

        using (var db = new StudentManagementDBEntities())
        {
            var userToReset = db.Users.Find(userId);
            if (userToReset == null) return;
            userToReset.Password = StudentInformationSystem.Helpers.PasswordSecurity.HashPassword("Hzd@123456");
            db.Entry(userToReset).State = EntityState.Modified;
            db.SaveChanges();
            Session["AdminFlashMessage"] = "\u7528\u6237 " + (userToReset.Username ?? "") + " \u7684\u5BC6\u7801\u5DF2\u6210\u529F\u91CD\u7F6E\u4E3A \"Hzd@123456\"\u3002";
        }

        var target = "TeacherList.aspx" + BuildQueryString(new KeyValuePair<string, string>("searchString", SearchString));
        Response.Redirect(target, true);
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->
<h2>教师列表</h2>
<% if (!string.IsNullOrEmpty(FlashMessage)) { %><div class="alert alert-success"><%= H(FlashMessage) %></div><% } %>
<form method="get" class="form-inline"><div class="form-group"><label>查找教师：</label><input type="text" name="searchString" value="<%= H(SearchString) %>" class="form-control" placeholder="输入姓名或工号" /></div> <button type="submit" class="btn btn-default">搜 索</button></form>
<br />
<p><a class="btn btn-primary" href="AddTeacher.aspx">添加新教师</a></p>
<div class="table-responsive">
    <table class="table table-striped table-bordered">
        <thead><tr><th>教师姓名</th><th>职称</th><th>登录账号</th><th>操作</th></tr></thead>
        <tbody>
            <% if (TeachersList.Any()) { foreach (var item in TeachersList) { %>
            <tr>
                <td><%= H(item.TeacherName) %></td>
                <td><%= H(item.Title) %></td>
                <td><%= item.Users == null ? "-" : H(item.Users.Username) %></td>
                <td>
                    <a href='EditTeacher.aspx?id=<%= Server.UrlEncode(item.TeacherID) %>'>编辑</a> |
                    <a href='DetailsTeacher.aspx?id=<%= Server.UrlEncode(item.TeacherID) %>'>详情</a> |
                    <a href='DeleteTeacher.aspx?id=<%= Server.UrlEncode(item.TeacherID) %>'>删除</a> |
                    <form method="post" style="display:inline;" onsubmit='return confirm("您确定要将用户 <%= H(item.Users == null ? item.TeacherID : item.Users.Username) %> 的密码重置为 Hzd@123456 吗？");'>
                        <input type="hidden" name="ResetUserID" value="<%= item.UserID %>" />
                        <input type="hidden" name="searchString" value="<%= H(SearchString) %>" />
                        <button type="submit" class="btn btn-link" style="padding:0;border:0;vertical-align:baseline;">重置密码</button>
                    </form>
                </td>
            </tr>
            <% } } else { %><tr><td colspan="4" class="text-center text-muted">暂无教师记录。</td></tr><% } %>
        </tbody>
    </table>
</div>
<!--#include file="_AdminLayoutBottom.inc" -->
