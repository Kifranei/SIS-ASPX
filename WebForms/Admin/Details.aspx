<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Students CurrentStudent;
    protected string MessageText = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "学生详情";
        if (!EnsureAdminRole())
        {
            return;
        }

        var id = (Request.QueryString["id"] ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(id))
        {
            MessageText = "缺少学生ID参数。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            CurrentStudent = db.Students.Include("Classes").FirstOrDefault(s => s.StudentID == id);
        }

        if (CurrentStudent == null)
        {
            MessageText = "学生不存在。";
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>学生详情</h2>

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } else { %>
    <div>
        <h4><%= H(CurrentStudent.StudentName) %></h4>
        <hr />
        <dl class="dl-horizontal">
            <dt>学号</dt>
            <dd><%= H(CurrentStudent.StudentID) %></dd>

            <dt>姓名</dt>
            <dd><%= H(CurrentStudent.StudentName) %></dd>

            <dt>性别</dt>
            <dd><%= H(CurrentStudent.Gender) %></dd>

            <dt>班级</dt>
            <dd><%= CurrentStudent.Classes == null ? "-" : H(CurrentStudent.Classes.ClassName) %></dd>
        </dl>
    </div>
    <p>
        <a class="btn btn-primary" href='Edit.aspx?id=<%= Server.UrlEncode(CurrentStudent.StudentID) %>'>编辑</a>
        <a class="btn btn-default" href="StudentList.aspx">返回列表</a>
    </p>
<% } %>

<!--#include file="_AdminLayoutBottom.inc" -->
