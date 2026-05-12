<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Exams CurrentExam;
    protected string MessageText = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "��������";
        if (!EnsureAdminRole())
        {
            return;
        }

        int id;
        if (!int.TryParse(Request.QueryString["id"], out id) || id <= 0)
        {
            MessageText = "���Բ�����Ч��";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            CurrentExam = db.Exams.Include("Courses").FirstOrDefault(ei => ei.ExamID == id);
        }

        if (CurrentExam == null)
        {
            MessageText = "���Լ�¼�����ڡ�";
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>��������</h2>

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } else { %>
    <div>
        <h4><%= CurrentExam.Courses == null ? "-" : H(CurrentExam.Courses.CourseName) %></h4>
        <hr />
        <dl class="dl-horizontal">
            <dt>�γ�����</dt>
            <dd><%= CurrentExam.Courses == null ? "-" : H(CurrentExam.Courses.CourseName) %></dd>

            <dt>����ʱ��</dt>
            <dd><%= CurrentExam.StartTime.ToString("yyyy-MM-dd HH:mm") + " - " + CurrentExam.EndTime.ToString("HH:mm") %></dd>

            <dt>���Եص�</dt>
            <dd><%= H(CurrentExam.Location) %></dd>

            <dt>��ע</dt>
            <dd><%= H(CurrentExam.Details) %></dd>
        </dl>
    </div>
    <p>
        <a class="btn btn-primary" href='EditExam.aspx?id=<%= CurrentExam.ExamID %>'>�༭</a>
        <a class="btn btn-default" href="ExamList.aspx">�����б�</a>
    </p>
<% } %>

<!--#include file="_AdminLayoutBottom.inc" -->
