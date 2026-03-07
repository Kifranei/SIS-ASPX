<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected string SearchString = string.Empty;
    protected string FlashMessage = string.Empty;
    protected string FlashError = string.Empty;
    protected List<Classes> ClassListData = new List<Classes>();

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "班级列表";
        if (!EnsureAdminRole())
        {
            return;
        }

        SearchString = (Request.QueryString["searchString"] ?? string.Empty).Trim();
        FlashMessage = (Session["AdminFlashMessage"] as string) ?? string.Empty;
        FlashError = (Session["AdminFlashError"] as string) ?? string.Empty;
        Session.Remove("AdminFlashMessage");
        Session.Remove("AdminFlashError");

        using (var db = new StudentManagementDBEntities())
        {
            var query = db.Classes.AsQueryable();
            if (!string.IsNullOrWhiteSpace(SearchString))
            {
                query = query.Where(c => c.Major.Contains(SearchString) || c.ClassName.Contains(SearchString) || c.AcademicYear.ToString().Contains(SearchString));
            }

            ClassListData = query.OrderBy(c => c.ClassName).ToList();
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<% if (!string.IsNullOrEmpty(FlashError)) { %>
    <div class="alert alert-danger"><%= H(FlashError) %></div>
<% } %>
<% if (!string.IsNullOrEmpty(FlashMessage)) { %>
    <div class="alert alert-success"><%= H(FlashMessage) %></div>
<% } %>

<h2>班级列表</h2>

<form method="get" class="form-inline">
    <div class="form-group">
        <label>查找班级:</label>
        <input type="text" name="searchString" value="<%= H(SearchString) %>" class="form-control" placeholder="输入专业/学年/班级名" />
    </div>
    <button type="submit" class="btn btn-default">搜 索</button>
</form>
<br />

<p><a class="btn btn-primary" href="AddClass.aspx">添加新班级</a></p>
<div class="table-responsive">
    <table class="table table-striped table-bordered">
        <thead>
            <tr>
                <th>班级名称</th>
                <th>专业</th>
                <th>学年</th>
                <th>班号</th>
                <th>操作</th>
            </tr>
        </thead>
        <tbody>
            <% if (ClassListData.Any()) { %>
                <% foreach (var item in ClassListData) { %>
                    <tr>
                        <td><%= H(item.ClassName) %></td>
                        <td><%= H(item.Major) %></td>
                        <td><%= item.AcademicYear.HasValue ? item.AcademicYear.Value.ToString() : "-" %></td>
                        <td><%= item.ClassNumber.HasValue ? item.ClassNumber.Value.ToString() : "-" %></td>
                        <td>
                            <a href='EditClass.aspx?id=<%= item.ClassID %>'>编辑</a> |
                            <a href='ClassDetails.aspx?id=<%= item.ClassID %>'>详情</a> |
                            <a href='DeleteClass.aspx?id=<%= item.ClassID %>'>删除</a>
                        </td>
                    </tr>
                <% } %>
            <% } else { %>
                <tr><td colspan="5" class="text-center text-muted">暂无班级记录。</td></tr>
            <% } %>
        </tbody>
    </table>
</div>

<!--#include file="_AdminLayoutBottom.inc" -->
