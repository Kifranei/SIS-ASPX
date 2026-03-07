<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Teachers CurrentTeacher;
    protected string MessageText = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "教师详情";
        if (!EnsureAdminRole())
        {
            return;
        }

        var id = (Request.QueryString["id"] ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(id))
        {
            MessageText = "缺少教师ID参数。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            CurrentTeacher = db.Teachers.Find(id);
        }

        if (CurrentTeacher == null)
        {
            MessageText = "教师不存在。";
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>教师详情</h2>

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } else { %>
    <h4><%= H(CurrentTeacher.TeacherName) %></h4>
    <hr />
    <dl class="dl-horizontal">
        <dt>教师工号</dt>
        <dd><%= H(CurrentTeacher.TeacherID) %></dd>

        <dt>姓名</dt>
        <dd><%= H(CurrentTeacher.TeacherName) %></dd>

        <dt>职称</dt>
        <dd><%= H(CurrentTeacher.Title) %></dd>
    </dl>
    <p>
        <a class="btn btn-primary" href='EditTeacher.aspx?id=<%= Server.UrlEncode(CurrentTeacher.TeacherID) %>'>编辑</a>
        <a class="btn btn-default" href="TeacherList.aspx">返回列表</a>
    </p>
<% } %>

<!--#include file="_AdminLayoutBottom.inc" -->
