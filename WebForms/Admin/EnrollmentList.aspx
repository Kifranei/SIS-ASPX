<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected string SearchString = string.Empty;
    protected List<StudentCourses> EnrollmentListData = new List<StudentCourses>();

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "全部选课记录";
        if (!EnsureAdminRole())
        {
            return;
        }

        SearchString = (Request.QueryString["searchString"] ?? string.Empty).Trim();

        using (var db = new StudentManagementDBEntities())
        {
            var query = db.StudentCourses.Include("Students").Include("Courses").AsQueryable();
            if (!string.IsNullOrWhiteSpace(SearchString))
            {
                query = query.Where(e => e.Students.StudentName.Contains(SearchString)
                                      || e.Students.StudentID.Contains(SearchString)
                                      || e.Courses.CourseName.Contains(SearchString));
            }

            EnrollmentListData = query.OrderByDescending(e => e.SC_ID).ToList();
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>全部选课记录</h2>

<form method="get" class="form-inline">
    <div class="form-group">
        <label>查找记录:</label>
        <input type="text" name="searchString" value="<%= H(SearchString) %>" class="form-control" placeholder="输入学生姓名/学号/课程名" />
    </div>
    <button type="submit" class="btn btn-default">搜 索</button>
</form>
<hr />

<p>这里展示了系统中所有的学生选课历史记录。</p>
<div class="table-responsive">
    <table class="table table-striped table-bordered">
        <thead>
            <tr>
                <th>课程名称</th>
                <th>学生姓名</th>
                <th>学号</th>
                <th>成绩</th>
            </tr>
        </thead>
        <tbody>
            <% if (EnrollmentListData.Any()) { %>
                <% foreach (var item in EnrollmentListData) { %>
                    <tr>
                        <td><%= item.Courses == null ? "-" : H(item.Courses.CourseName) %></td>
                        <td><%= item.Students == null ? "-" : H(item.Students.StudentName) %></td>
                        <td><%= H(item.StudentID) %></td>
                        <td>
                            <% if (item.Grade.HasValue) { %>
                                <strong><%= item.Grade.Value.ToString("0.##") %></strong>
                            <% } else { %>
                                <span class="text-muted">未录入</span>
                            <% } %>
                        </td>
                    </tr>
                <% } %>
            <% } else { %>
                <tr><td colspan="4" class="text-center text-muted">暂无选课记录。</td></tr>
            <% } %>
        </tbody>
    </table>
</div>

<p><a class="btn btn-default" href="Index.aspx">返回控制台</a></p>

<!--#include file="_AdminLayoutBottom.inc" -->
