<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Exams CurrentExam;
    protected string MessageText = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "ɾ������";
        if (!EnsureAdminRole())
        {
            return;
        }

        int id;
        if (!int.TryParse(Request.QueryString["id"] ?? Request.Form["ExamID"], out id) || id <= 0)
        {
            MessageText = "���Բ�����Ч��";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            CurrentExam = db.Exams.Include("Courses").FirstOrDefault(ei => ei.ExamID == id);
            if (CurrentExam == null)
            {
                MessageText = "���Լ�¼�����ڡ�";
                return;
            }

            if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
            {
                db.Exams.Remove(CurrentExam);
                db.SaveChanges();
                Response.Redirect("ExamList.aspx", true);
            }
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>ɾ������</h2>

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } else { %>
    <h3>��ȷ��Ҫɾ���������԰�����</h3>
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
        </dl>

        <form method="post" class="form-actions no-color">
            <input type="hidden" name="ExamID" value="<%= CurrentExam.ExamID %>" />
            <button type="submit" class="btn btn-danger">ȷ��ɾ��</button>
            <a class="btn btn-default" href="ExamList.aspx">�����б�</a>
        </form>
    </div>
<% } %>

<!--#include file="_AdminLayoutBottom.inc" -->
