<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected Exams CurrentExam;
    protected string MessageType = string.Empty;
    protected string MessageText = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        var currentUser = Session["User"] as Users;
        if (currentUser == null || currentUser.Role != 1)
        {
            Response.Redirect("~/Login.aspx", true);
            return;
        }

        int examId;
        if (!int.TryParse(Request.QueryString["id"], out examId) || examId <= 0)
        {
            MessageType = "danger";
            MessageText = "��Ч�Ŀ��Բ�����";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            var teacher = db.Teachers.FirstOrDefault(t => t.UserID == currentUser.UserID);
            if (teacher == null)
            {
                Response.Redirect("~/Login.aspx", true);
                return;
            }

            var taughtCourseIds = db.Courses.Where(c => c.TeacherID == teacher.TeacherID).Select(c => c.CourseID).ToList();
            CurrentExam = db.Exams.Include("Courses").FirstOrDefault(ei => ei.ExamID == examId);
            if (CurrentExam == null || !taughtCourseIds.Contains(CurrentExam.CourseID))
            {
                CurrentExam = null;
                MessageType = "danger";
                MessageText = "���Լ�¼�����ڻ����ڵ�ǰ��ʦ��";
            }
        }
    }

    protected string Active(string page)
    {
        var current = VirtualPathUtility.GetFileName(Request.AppRelativeCurrentExecutionFilePath) ?? string.Empty;
        return current.Equals(page, StringComparison.OrdinalIgnoreCase) ? "active" : string.Empty;
    }
</script>

<!DOCTYPE html>
<html lang="zh-CN">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <script>
        (function () {
            var theme = localStorage.getItem('theme');
            var isDark = theme === 'dark';
            if (isDark) {
                document.documentElement.classList.add('dark-mode');
            } else {
                document.documentElement.classList.remove('dark-mode');
            }
        })();
    </script>
    <title>��������</title>
    <link href="<%= ResolveUrl("~/Content/bootstrap.min.css") %>" rel="stylesheet" />
    <link href="<%= ResolveUrl("~/Content/theme-system.css") %>" rel="stylesheet" />
    <link href="<%= ResolveUrl("~/Content/webforms-student-layout.css") %>" rel="stylesheet" />
</head>
<body class="webforms-student">
    <div class="page-wrapper">
        <div class="sidebar-overlay"></div>
        <aside class="sidebar">
            <div class="sidebar-header">
                <img src="https://jwgl.hrbzy.edu.cn:9081/style04/images/logo.png" height="35" alt="У��" class="sidebar-logo-img" />
            </div>
            <ul class="sidebar-menu">
                <li><a class="<%= Active("Index.aspx") %>" href="Index.aspx">��ҳ</a></li>
                <li><a class="<%= Active("Timetable.aspx") %>" href="Timetable.aspx">�ҵĿα�</a></li>
                <li><a class="<%= Active("CourseList.aspx") %>" href="CourseList.aspx">�ɼ�¼��</a></li>
                <li><a class="<%= Active("ExamList.aspx") %>" href="ExamList.aspx">���Թ���</a></li>
                <li><a class="<%= Active("ChangePassword.aspx") %>" href="ChangePassword.aspx">�޸�����</a></li>
            </ul>
        </aside>

        <div class="main-content">
            <header class="header-bar">
                <div class="header-left">
                    <button class="hamburger-menu" type="button" aria-label="�˵�">&#9776;</button>
                </div>
                <div class="header-right">
                    <button class='dark-toggle-btn' type='button'>��ɫģʽ</button>
                    <div class="user-info">
                        <span class="username">��ӭ��, <%= (Session["DisplayName"] as string) ?? ((Session["User"] as Users)?.Username ?? "��ʦ") %></span>
                        <span class="sep">|</span>
                        <a class="logout-link" href="../Logout.aspx">��ȫ�˳�</a>
                    </div>
                </div>
            </header>

            <main class="content-body">
                <div class="container-fluid">
                    <h2>��������</h2>

                    <% if (!string.IsNullOrEmpty(MessageText)) { %>
                        <div class="alert alert-<%= MessageType %>"><%= MessageText %></div>
                    <% } %>

                    <% if (CurrentExam != null) { %>
                        <div>
                            <h4><%= CurrentExam.Courses == null ? "-" : CurrentExam.Courses.CourseName %></h4>
                            <hr />
                            <dl class="dl-horizontal">
                                <dt>�γ�����</dt>
                                <dd><%= CurrentExam.Courses == null ? "-" : CurrentExam.Courses.CourseName %></dd>
                                <dt>����ʱ��</dt>
                                <dd><%= CurrentExam.StartTime.ToString("yyyy-MM-dd HH:mm") + " - " + CurrentExam.EndTime.ToString("HH:mm") %></dd>
                                <dt>���Եص�</dt>
                                <dd><%= CurrentExam.Location %></dd>
                                <dt>��ע</dt>
                                <dd><%= string.IsNullOrWhiteSpace(CurrentExam.Details) ? "-" : CurrentExam.Details %></dd>
                            </dl>
                        </div>
                        <p>
                            <a class="btn btn-primary" href="EditExam.aspx?id=<%= CurrentExam.ExamID %>">�༭</a>
                            <a class="btn btn-default" href="ExamList.aspx">�����б�</a>
                        </p>
                    <% } else { %>
                        <a class="btn btn-default" href="ExamList.aspx">�����б�</a>
                    <% } %>
                </div>
            </main>
        </div>
    </div>
    <script src="<%= ResolveUrl("~/Scripts/webforms-student-layout.js") %>"></script>
</body>
</html>

