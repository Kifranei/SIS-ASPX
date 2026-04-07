<%@ Page Language="C#" AutoEventWireup="true" CodePage="65001" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected int CourseId = 0;
    protected Courses CurrentCourse;
    protected List<StudentCourses> Enrollments = new List<StudentCourses>();
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

        if (!int.TryParse(Request.QueryString["courseId"], out CourseId) || CourseId <= 0)
        {
            MessageType = "danger";
            MessageText = "\u53C2\u6570 courseId \u65E0\u6548\u3002";
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

            CurrentCourse = db.Courses
                .Include("Teachers")
                .FirstOrDefault(c => c.CourseID == CourseId && c.TeacherID == teacher.TeacherID);

            if (CurrentCourse == null)
            {
                MessageType = "danger";
                MessageText = "\u8BFE\u7A0B\u4E0D\u5B58\u5728\u6216\u4E0D\u5C5E\u4E8E\u5F53\u524D\u6559\u5E08\u3002";
                return;
            }

            if (Request.HttpMethod.Equals("GET", StringComparison.OrdinalIgnoreCase)
                && string.Equals(Request.QueryString["saved"], "1", StringComparison.OrdinalIgnoreCase))
            {
                MessageType = "success";
                MessageText = "\u6210\u7EE9\u4FDD\u5B58\u6210\u529F\u3002";
            }

            if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
            {
                var studentIds = Request.Form.GetValues("studentIds");
                var grades = Request.Form.GetValues("grades");
                if (studentIds != null && grades != null && studentIds.Length == grades.Length)
                {
                    for (int i = 0; i < studentIds.Length; i++)
                    {
                        var studentId = (studentIds[i] ?? string.Empty).Trim();
                        var gradeText = (grades[i] ?? string.Empty).Trim();

                        float? parsedGrade = null;
                        if (!string.IsNullOrEmpty(gradeText))
                        {
                            float gradeValue;
                            var ok = float.TryParse(gradeText, NumberStyles.Float, CultureInfo.CurrentCulture, out gradeValue)
                                || float.TryParse(gradeText, NumberStyles.Float, CultureInfo.InvariantCulture, out gradeValue);

                            if (!ok)
                            {
                                MessageType = "danger";
                                MessageText = "\u5B58\u5728\u65E0\u6CD5\u8BC6\u522B\u7684\u6210\u7EE9\u503C\uFF0C\u8BF7\u68C0\u67E5\u540E\u91CD\u8BD5\u3002";
                                break;
                            }

                            if (gradeValue < 0f || gradeValue > 100f)
                            {
                                MessageType = "danger";
                                MessageText = "\u6210\u7EE9\u5FC5\u987B\u5728 0-100 \u4E4B\u95F4\u3002";
                                break;
                            }

                            parsedGrade = gradeValue;
                        }

                        var enrollment = db.StudentCourses.FirstOrDefault(sc => sc.StudentID == studentId && sc.CourseID == CourseId);
                        if (enrollment != null)
                        {
                            enrollment.Grade = parsedGrade;
                        }
                    }

                    if (string.IsNullOrEmpty(MessageText))
                    {
                        db.SaveChanges();
                        Response.Redirect("GradeEntry.aspx?courseId=" + CourseId + "&saved=1", true);
                        return;
                    }
                }
                else
                {
                    MessageType = "danger";
                    MessageText = "\u63D0\u4EA4\u6570\u636E\u4E0D\u5B8C\u6574\uFF0C\u8BF7\u5237\u65B0\u9875\u9762\u540E\u91CD\u8BD5\u3002";
                }
            }

            Enrollments = db.StudentCourses
                .Include("Students.Classes")
                .Where(sc => sc.CourseID == CourseId)
                .OrderBy(sc => sc.Students.StudentID)
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
    <title>&#x6210;&#x7EE9;&#x5F55;&#x5165;</title>
    <link href="<%= ResolveUrl("~/Content/bootstrap.min.css") %>" rel="stylesheet" />
    <link href="<%= ResolveUrl("~/Content/theme-system.css") %>" rel="stylesheet" />
    <link href="<%= ResolveUrl("~/Content/webforms-student-layout.css") %>" rel="stylesheet" />
</head>
<body class="webforms-student">
    <div class="page-wrapper">
        <div class="sidebar-overlay"></div>
        <aside class="sidebar">
            <div class="sidebar-header">
                <img src="https://jwgl.hrbzy.edu.cn:9081/style04/images/logo.png" height="35" alt="logo" class="sidebar-logo-img" />
            </div>
            <ul class="sidebar-menu">
                <li><a class="<%= Active("Index.aspx") %>" href="Index.aspx">&#x9996;&#x9875;</a></li>
                <li><a class="<%= Active("Timetable.aspx") %>" href="Timetable.aspx">&#x6211;&#x7684;&#x8BFE;&#x8868;</a></li>
                <li><a class="<%= Active("CourseList.aspx") %>" href="CourseList.aspx">&#x6210;&#x7EE9;&#x5F55;&#x5165;</a></li>
                <li><a class="<%= Active("ExamList.aspx") %>" href="ExamList.aspx">&#x8003;&#x8BD5;&#x7BA1;&#x7406;</a></li>
                <li><a class="<%= Active("ChangePassword.aspx") %>" href="ChangePassword.aspx">&#x4FEE;&#x6539;&#x5BC6;&#x7801;</a></li>
            </ul>
        </aside>

        <div class="main-content">
            <header class="header-bar">
                <div class="header-left">
                    <button class="hamburger-menu" type="button" aria-label="menu">&#9776;</button>
                </div>
                <div class="header-right">
                    <button class="dark-toggle-btn" type="button">&#x6697;&#x8272;&#x6A21;&#x5F0F;</button>
                    <div class="user-info">
                        <span class="username">&#x6B22;&#x8FCE;&#x60A8;, <%= ((Session["User"] as Users)?.Username ?? "\u6559\u5E08") %></span>
                        <span class="sep">|</span>
                        <a class="logout-link" href="../Logout.aspx">&#x5B89;&#x5168;&#x9000;&#x51FA;</a>
                    </div>
                </div>
            </header>

            <main class="content-body">
                <div class="container-fluid">
                    <% if (!string.IsNullOrEmpty(MessageText)) { %>
                        <div class="alert alert-<%= MessageType %>"><%= MessageText %></div>
                    <% } %>

                    <% if (CurrentCourse != null) { %>
                        <h2>
                            &#x4E3A;&#x8BFE;&#x7A0B;
                            &#x201C;<%= Server.HtmlEncode(CurrentCourse.CourseName) %>&#x201D;
                            &#x5F55;&#x5165;&#x6210;&#x7EE9;
                        </h2>
                        <hr />
                        <form method="post">
                            <div class="table-responsive">
                                <table class="table table-striped table-bordered">
                                    <thead>
                                        <tr>
                                            <th>&#x5B66;&#x53F7;</th>
                                            <th>&#x59D3;&#x540D;</th>
                                            <th>&#x6210;&#x7EE9; (0-100)</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <% if (Enrollments.Any()) { %>
                                            <% foreach (var item in Enrollments) { var student = item.Students; %>
                                                <tr>
                                                    <td>
                                                        <%= student == null ? "-" : Server.HtmlEncode(student.StudentID) %>
                                                        <input type="hidden" name="studentIds" value="<%= student == null ? "" : Server.HtmlEncode(student.StudentID) %>" />
                                                    </td>
                                                    <td><%= student == null ? "-" : Server.HtmlEncode(student.StudentName) %></td>
                                                    <td>
                                                        <input type="number" name="grades" value="<%= item.Grade.HasValue ? item.Grade.Value.ToString("0.##", CultureInfo.InvariantCulture) : "" %>" class="form-control" min="0" max="100" step="0.1" />
                                                    </td>
                                                </tr>
                                            <% } %>
                                        <% } else { %>
                                            <tr>
                                                <td colspan="3" class="text-center text-muted">&#x8BE5;&#x8BFE;&#x7A0B;&#x6682;&#x65E0;&#x9009;&#x8BFE;&#x5B66;&#x751F;&#x3002;</td>
                                            </tr>
                                        <% } %>
                                    </tbody>
                                </table>
                            </div>
                            <div class="form-group" style="margin-top: 12px;">
                                <button type="submit" class="btn btn-success">&#x4FDD;&#x5B58;&#x5168;&#x90E8;&#x6210;&#x7EE9;</button>
                                <a class="btn btn-default" target="_blank" href="ClassRoster.aspx?courseId=<%= CourseId %>">&#x6253;&#x5370;&#x540D;&#x5355;</a>
                                <a class="btn btn-default" href="CourseList.aspx">&#x8FD4;&#x56DE;&#x5217;&#x8868;</a>
                            </div>
                        </form>
                    <% } else { %>
                        <a class="btn btn-default" href="CourseList.aspx">&#x8FD4;&#x56DE;&#x8BFE;&#x7A0B;&#x5217;&#x8868;</a>
                    <% } %>
                </div>
            </main>
        </div>
    </div>
    <script src="<%= ResolveUrl("~/Scripts/webforms-student-layout.js") %>"></script>
</body>
</html>
