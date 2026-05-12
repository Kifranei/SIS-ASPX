<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected List<Exams> ExamsList = new List<Exams>();
    protected string FlashMessage = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        var currentUser = Session["User"] as Users;
        if (currentUser == null || currentUser.Role != 1)
        {
            Response.Redirect("~/Login.aspx", true);
            return;
        }

        FlashMessage = (Request.QueryString["msg"] ?? string.Empty).Trim();

        using (var db = new StudentManagementDBEntities())
        {
            var teacher = db.Teachers.FirstOrDefault(t => t.UserID == currentUser.UserID);
            if (teacher == null)
            {
                Response.Redirect("~/Login.aspx", true);
                return;
            }

            var taughtCourseIds = db.Courses.Where(c => c.TeacherID == teacher.TeacherID).Select(c => c.CourseID).ToList();
            ExamsList = db.Exams.Include("Courses")
                .Where(ei => taughtCourseIds.Contains(ei.CourseID))
                .OrderBy(ei => ei.StartTime)
                .ToList();
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
    <title>���԰����б�</title>
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
                    <% if (!string.IsNullOrEmpty(FlashMessage)) { %>
                        <div class="alert alert-success"><%= Server.HtmlEncode(FlashMessage) %></div>
                    <% } %>

                    <h2>���԰����б�</h2>
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
                                            <td><%= item.Courses == null ? "-" : item.Courses.CourseName %></td>
                                            <td><%= item.StartTime.ToString("yyyy-MM-dd HH:mm") + " - " + item.EndTime.ToString("HH:mm") %></td>
                                            <td><%= item.Location %></td>
                                            <td>
                                                <a href="EditExam.aspx?id=<%= item.ExamID %>">�༭</a> |
                                                <a href="DetailsExam.aspx?id=<%= item.ExamID %>">����</a> |
                                                <a href="DeleteExam.aspx?id=<%= item.ExamID %>">ɾ��</a>
                                            </td>
                                        </tr>
                                    <% } %>
                                <% } else { %>
                                    <tr><td colspan="4" class="text-center text-muted">���޿��԰��š�</td></tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </main>
        </div>
    </div>
    <script src="<%= ResolveUrl("~/Scripts/webforms-student-layout.js") %>"></script>
</body>
</html>

