<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected string SearchString = string.Empty;
    protected List<Exams> ExamsList = new List<Exams>();

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "���԰����б�";
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

            ExamsList = query.OrderBy(ei => ei.StartTime).ToList();
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>���԰����б�</h2>

<form method="get" class="form-inline">
    <div class="form-group">
        <label>���ҿ���:</label>
        <input type="text" name="searchString" value="<%= H(SearchString) %>" class="form-control" placeholder="����γ������Եص�" />
    </div>
    <button type="submit" class="btn btn-default">�� ��</button>
</form>
<br />

<p><a class="btn btn-primary" href="AddExam.aspx">�����¿���</a></p>

<div class="table-responsive">
    <table class="table table-striped table-bordered">
        <thead>
            <tr>
                <th>�γ�����</th>
                <th>����ʱ��</th>
                <th>���Եص�</th>
                <th>����</th>
            </tr>
        </thead>
        <tbody>
            <% if (ExamsList.Any()) { %>
                <% foreach (var item in ExamsList) { %>
                    <tr>
                        <td><%= item.Courses == null ? "-" : H(item.Courses.CourseName) %></td>
                        <td><%= item.StartTime.ToString("yyyy-MM-dd HH:mm") + " - " + item.EndTime.ToString("HH:mm") %></td>
                        <td><%= H(item.Location) %></td>
                        <td>
                            <a href='EditExam.aspx?id=<%= item.ExamID %>'>�༭</a> |
                            <a href='DetailsExam.aspx?id=<%= item.ExamID %>'>����</a> |
                            <a href='DeleteExam.aspx?id=<%= item.ExamID %>'>ɾ��</a>
                        </td>
                    </tr>
                <% } %>
            <% } else { %>
                <tr><td colspan="4" class="text-center text-muted">���޿��԰��š�</td></tr>
            <% } %>
        </tbody>
    </table>
</div>

<!--#include file="_AdminLayoutBottom.inc" -->
