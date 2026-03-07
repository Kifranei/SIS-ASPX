<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected string SearchString = string.Empty;
    protected List<Exams> ExamsList = new List<Exams>();

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "考试安排列表";
        if (!EnsureAdminRole())
        {
            return;
        }

        SearchString = (Request.QueryString["searchString"] ?? string.Empty).Trim();

        using (var db = new StudentManagementDBEntities())
        {
            var query = db.Exams.Include("Courses").AsQueryable();
            if (!string.IsNullOrWhiteSpace(SearchString))
            {
                query = query.Where(ei => ei.Courses.CourseName.Contains(SearchString) || ei.Location.Contains(SearchString));
            }

            ExamsList = query.OrderBy(ei => ei.ExamTime).ToList();
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>考试安排列表</h2>

<form method="get" class="form-inline">
    <div class="form-group">
        <label>查找考试:</label>
        <input type="text" name="searchString" value="<%= H(SearchString) %>" class="form-control" placeholder="输入课程名或考试地点" />
    </div>
    <button type="submit" class="btn btn-default">搜 索</button>
</form>
<br />

<p><a class="btn btn-primary" href="AddExam.aspx">添加新考试</a></p>

<div class="table-responsive">
    <table class="table table-striped table-bordered">
        <thead>
            <tr>
                <th>课程名称</th>
                <th>考试时间</th>
                <th>考试地点</th>
                <th>操作</th>
            </tr>
        </thead>
        <tbody>
            <% if (ExamsList.Any()) { %>
                <% foreach (var item in ExamsList) { %>
                    <tr>
                        <td><%= item.Courses == null ? "-" : H(item.Courses.CourseName) %></td>
                        <td><%= item.ExamTime.ToString("yyyy-MM-dd HH:mm") %></td>
                        <td><%= H(item.Location) %></td>
                        <td>
                            <a href='EditExam.aspx?id=<%= item.ExamID %>'>编辑</a> |
                            <a href='DetailsExam.aspx?id=<%= item.ExamID %>'>详情</a> |
                            <a href='DeleteExam.aspx?id=<%= item.ExamID %>'>删除</a>
                        </td>
                    </tr>
                <% } %>
            <% } else { %>
                <tr><td colspan="4" class="text-center text-muted">暂无考试安排。</td></tr>
            <% } %>
        </tbody>
    </table>
</div>

<!--#include file="_AdminLayoutBottom.inc" -->
