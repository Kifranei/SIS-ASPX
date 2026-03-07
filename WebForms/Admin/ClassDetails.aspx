<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Classes CurrentClass;
    protected List<Students> StudentsInClass = new List<Students>();
    protected string MessageText = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "班级详情";
        if (!EnsureAdminRole())
        {
            return;
        }

        int id;
        if (!int.TryParse(Request.QueryString["id"], out id) || id <= 0)
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

            StudentsInClass = db.Students.Where(s => s.ClassID == id).OrderBy(s => s.StudentID).ToList();
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>班级详情</h2>

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } else { %>
    <h4><%= H(CurrentClass.ClassName) %></h4>
    <hr />
    <dl class="dl-horizontal">
        <dt>专业</dt>
        <dd><%= H(CurrentClass.Major) %></dd>

        <dt>学年</dt>
        <dd><%= CurrentClass.AcademicYear.HasValue ? CurrentClass.AcademicYear.Value.ToString() : "-" %></dd>

        <dt>班号</dt>
        <dd><%= CurrentClass.ClassNumber.HasValue ? CurrentClass.ClassNumber.Value.ToString() : "-" %></dd>

        <dt>班级人数</dt>
        <dd><%= StudentsInClass.Count %> 人</dd>
    </dl>
    <hr />

    <h4>班级学生名单</h4>
    <div class="table-responsive">
        <table class="table table-striped table-bordered">
            <thead>
                <tr>
                    <th>学号</th>
                    <th>姓名</th>
                    <th>性别</th>
                    <th>操作</th>
                </tr>
            </thead>
            <tbody>
                <% if (StudentsInClass.Any()) { %>
                    <% foreach (var student in StudentsInClass) { %>
                        <tr>
                            <td><%= H(student.StudentID) %></td>
                            <td><%= H(student.StudentName) %></td>
                            <td><%= H(student.Gender) %></td>
                            <td><a href='Edit.aspx?id=<%= Server.UrlEncode(student.StudentID) %>'>编辑该学生</a></td>
                        </tr>
                    <% } %>
                <% } else { %>
                    <tr><td colspan="4" class="text-center text-muted">该班级暂无学生。</td></tr>
                <% } %>
            </tbody>
        </table>
    </div>

    <p>
        <a class="btn btn-primary" href='AddStudent.aspx?classId=<%= CurrentClass.ClassID %>'>添加新学生</a>
        <a class="btn btn-default" href="ClassList.aspx">返回班级列表</a>
    </p>
<% } %>

<!--#include file="_AdminLayoutBottom.inc" -->
