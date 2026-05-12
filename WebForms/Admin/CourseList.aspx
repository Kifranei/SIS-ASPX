<%@ Page CodePage="65001" Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected string SearchString = string.Empty;
    protected string FlashMessage = string.Empty;
    protected string FlashError = string.Empty;
    protected List<Courses> CourseListData = new List<Courses>();

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "课程列表";
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
            var query = db.Courses.Include("Teachers").AsQueryable();
            if (!string.IsNullOrWhiteSpace(SearchString))
            {
                query = query.Where(c => c.CourseName.Contains(SearchString) || (c.Teachers != null && c.Teachers.TeacherName.Contains(SearchString)));
            }

            CourseListData = query.OrderBy(c => c.CourseID).ToList();
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

<h2>课程列表</h2>

<form method="get" class="form-inline">
    <div class="form-group">
        <label>查找课程:</label>
        <input type="text" name="searchString" value="<%= H(SearchString) %>" class="form-control" placeholder="输入课程名或教师名" />
    </div>
    <button type="submit" class="btn btn-default">搜 索</button>
</form>
<br />
<p><a class="btn btn-primary" href="AddCourse.aspx">添加新课程</a></p>

<div class="table-responsive">
    <table class="table table-hover table-bordered">
        <thead>
            <tr>
                <th>课程名称</th>
                <th>学分</th>
                <th>任课教师</th>
                <th>课程类型</th>
                <th>课程安排</th>
                <th>操作</th>
            </tr>
        </thead>
        <tbody>
            <% if (CourseListData.Any()) { %>
                <% foreach (var item in CourseListData) { %>
                    <tr>
                        <td><strong><%= H(item.CourseName) %></strong></td>
                        <td><%= item.Credits %> 学分</td>
                        <td><%= item.Teachers == null ? "未分配教师" : H(item.Teachers.TeacherName) %></td>
                        <td><span class="label label-info"><%= H(CourseTypeText(item.CourseType)) %></span></td>
                        <td><a class="btn btn-info btn-sm" href='CourseSchedule.aspx?courseId=<%= item.CourseID %>'>查看安排</a></td>
                        <td>
                            <div class="btn-group btn-group-sm">
                                <a class="btn btn-warning" href='EditCourse.aspx?id=<%= item.CourseID %>'>编辑</a>
                                <a class="btn btn-info" href='DetailsCourse.aspx?id=<%= item.CourseID %>'>详情</a>
                                <a class="btn btn-danger" href='DeleteCourse.aspx?id=<%= item.CourseID %>'>删除</a>
                            </div>
                        </td>
                    </tr>
                <% } %>
            <% } else { %>
                <tr><td colspan="6" class="text-center text-muted">暂无课程记录。</td></tr>
            <% } %>
        </tbody>
    </table>
</div>

<!--#include file="_AdminLayoutBottom.inc" -->
