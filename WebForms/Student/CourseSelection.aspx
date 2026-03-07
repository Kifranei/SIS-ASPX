<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected List<StudentCourses> EnrolledCourses = new List<StudentCourses>();
    protected List<Courses> SportsElectives = new List<Courses>();
    protected List<Courses> OtherElectives = new List<Courses>();
    protected Dictionary<int, List<ClassSessions>> ScheduleMap = new Dictionary<int, List<ClassSessions>>();
    protected int SportsCoursesTaken = 0;
    protected int OtherCoursesTaken = 0;
    protected string MessageType = string.Empty;
    protected string MessageText = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        var currentUser = Session["User"] as Users;
        if (currentUser == null || currentUser.Role != 2)
        {
            Response.Redirect("~/Login.aspx", true);
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            var student = db.Students.FirstOrDefault(s => s.UserID == currentUser.UserID);
            if (student == null)
            {
                Response.Redirect("~/Login.aspx", true);
                return;
            }

            if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
            {
                HandlePost(db, student.StudentID);
                return;
            }

            ReadFlash();
            LoadData(db, student.StudentID);
        }
    }

    protected void HandlePost(StudentManagementDBEntities db, string studentId)
    {
        var op = (Request.Form["op"] ?? string.Empty).Trim().ToLowerInvariant();
        int courseId;
        if (!int.TryParse(Request.Form["courseId"], out courseId))
        {
            SetFlash("danger", "课程参数无效。");
            Response.Redirect("CourseSelection.aspx", true);
            return;
        }

        var course = db.Courses.Find(courseId);
        if (course == null)
        {
            SetFlash("danger", "课程不存在。");
            Response.Redirect("CourseSelection.aspx", true);
            return;
        }

        if (op == "select")
        {
            var isEnrolled = db.StudentCourses.Any(sc => sc.StudentID == studentId && sc.CourseID == courseId);
            if (isEnrolled)
            {
                SetFlash("danger", "您已经选过这门课了。");
                Response.Redirect("CourseSelection.aspx", true);
                return;
            }

            if (course.CourseType == 5)
            {
                var hasPE = db.StudentCourses.Any(sc => sc.StudentID == studentId && sc.Courses.CourseType == 5);
                if (hasPE)
                {
                    SetFlash("danger", "体育选修课每人限选一门，请先退选原体育课后再选！");
                    Response.Redirect("CourseSelection.aspx", true);
                    return;
                }
            }

            db.StudentCourses.Add(new StudentCourses
            {
                StudentID = studentId,
                CourseID = courseId,
                Grade = null
            });
            db.SaveChanges();
            SetFlash("success", "选课成功！");
            Response.Redirect("CourseSelection.aspx", true);
            return;
        }

        if (op == "withdraw")
        {
            if (course.CourseType == 1 || course.CourseType == 2)
            {
                SetFlash("danger", "必修课程为教务处统一排课，学生不可自行退选！");
                Response.Redirect("CourseSelection.aspx", true);
                return;
            }

            var enrollment = db.StudentCourses.FirstOrDefault(sc => sc.StudentID == studentId && sc.CourseID == courseId);
            if (enrollment != null)
            {
                db.StudentCourses.Remove(enrollment);
                db.SaveChanges();
                SetFlash("success", "退课成功！");
            }
            else
            {
                SetFlash("danger", "未找到该选课记录。");
            }

            Response.Redirect("CourseSelection.aspx", true);
            return;
        }

        SetFlash("danger", "不支持的操作。");
        Response.Redirect("CourseSelection.aspx", true);
    }

    protected void LoadData(StudentManagementDBEntities db, string studentId)
    {
        var allEnrollments = db.StudentCourses
            .Include("Courses.Teachers")
            .Where(sc => sc.StudentID == studentId)
            .ToList();

        EnrolledCourses = allEnrollments;
        var enrolledCourseIds = allEnrollments.Select(sc => sc.CourseID).ToList();
        var retakeCourseIds = allEnrollments.Where(sc => sc.Grade < 60).Select(sc => sc.CourseID).Distinct().ToList();

        SportsCoursesTaken = allEnrollments.Count(sc => sc.Courses.CourseType == 5);
        OtherCoursesTaken = allEnrollments.Count(sc => sc.Courses.CourseType == 4);

        var allAvailableCourses = db.Courses
            .Include("Teachers")
            .Where(c => !enrolledCourseIds.Contains(c.CourseID) && !retakeCourseIds.Contains(c.CourseID))
            .ToList();

        SportsElectives = allAvailableCourses.Where(c => c.CourseType == 5).ToList();
        OtherElectives = allAvailableCourses.Where(c => c.CourseType == 4).ToList();

        var allCourseIds = allAvailableCourses.Select(c => c.CourseID)
            .Union(enrolledCourseIds)
            .Union(retakeCourseIds)
            .Distinct()
            .ToList();

        var schedules = db.ClassSessions
            .Where(cs => allCourseIds.Contains(cs.CourseID))
            .OrderBy(cs => cs.CourseID)
            .ThenBy(cs => cs.StartWeek)
            .ThenBy(cs => cs.DayOfWeek)
            .ThenBy(cs => cs.StartPeriod)
            .ToList();

        ScheduleMap = schedules
            .GroupBy(s => s.CourseID)
            .ToDictionary(g => g.Key, g => g.ToList());
    }

    protected void SetFlash(string type, string message)
    {
        Session["StudentFlashType"] = type;
        Session["StudentFlashMessage"] = message;
    }

    protected void ReadFlash()
    {
        MessageType = Session["StudentFlashType"] as string ?? string.Empty;
        MessageText = Session["StudentFlashMessage"] as string ?? string.Empty;
        Session.Remove("StudentFlashType");
        Session.Remove("StudentFlashMessage");
    }

    protected string Active(string page)
    {
        var current = VirtualPathUtility.GetFileName(Request.AppRelativeCurrentExecutionFilePath) ?? string.Empty;
        return current.Equals(page, StringComparison.OrdinalIgnoreCase) ? "active" : string.Empty;
    }

    protected string CourseTypeText(int? t)
    {
        switch (t)
        {
            case 1: return "专业必修";
            case 2: return "公共/思政必修";
            case 3: return "专业选修";
            case 4: return "公共选修";
            case 5: return "体育选修";
            default: return "未知";
        }
    }

    protected string CourseTypeBadge(int? t)
    {
        if (t == 1 || t == 2) return "bg-danger";
        if (t == 5) return "bg-success";
        return "bg-primary";
    }

    protected string TeacherName(Courses c)
    {
        return c != null && c.Teachers != null ? c.Teachers.TeacherName : "待分配";
    }

    protected string RenderScheduleHtml(int courseId)
    {
        if (!ScheduleMap.ContainsKey(courseId) || !ScheduleMap[courseId].Any())
        {
            return "<small class='text-muted'>时间地点待定</small>";
        }

        var dayNames = new[] { "", "周一", "周二", "周三", "周四", "周五", "周六", "周日" };
        var sb = new StringBuilder();
        foreach (var s in ScheduleMap[courseId])
        {
            var day = s.DayOfWeek >= 1 && s.DayOfWeek <= 7 ? dayNames[s.DayOfWeek] : "未知";
            sb.Append("<div style='margin-bottom:4px;'>");
            sb.Append("<span class='badge bg-secondary'>第" + s.StartWeek + "-" + s.EndWeek + "周</span> ");
            sb.Append("<span class='badge bg-secondary'>" + day + " 第" + s.StartPeriod + "-" + s.EndPeriod + "节</span> ");
            sb.Append("<span class='badge bg-success'>" + HttpUtility.HtmlEncode(s.Classroom) + "</span>");
            sb.Append("</div>");
        }
        return sb.ToString();
    }

    protected bool IsMustCourse(Courses c)
    {
        return c != null && (c.CourseType == 1 || c.CourseType == 2);
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
    <title>在线选课</title>
    <link href="<%= ResolveUrl("~/Content/bootstrap.min.css") %>" rel="stylesheet" />
    <link href="<%= ResolveUrl("~/Content/theme-system.css") %>" rel="stylesheet" />
    <link href="<%= ResolveUrl("~/Content/webforms-student-layout.css") %>" rel="stylesheet" />
    <style>
        .tab-pane { display: none; }
        .tab-pane.active { display: block; }
        .table td { vertical-align: middle; }
    </style>
</head>
<body class="webforms-student">
    <div class="page-wrapper">
        <div class="sidebar-overlay"></div>
        <aside class="sidebar">
            <div class="sidebar-header">
                <img src="https://jwgl.hrbzy.edu.cn:9081/style04/images/logo.png" height="35" alt="校徽" class="sidebar-logo-img" />
            </div>
            <ul class="sidebar-menu">
                <li><a class="<%= Active("Index.aspx") %>" href="Index.aspx">个人中心</a></li>
                <li><a class="<%= Active("Timetable.aspx") %>" href="Timetable.aspx">我的课表</a></li>
                <li><a class="<%= Active("CourseSelection.aspx") %>" href="CourseSelection.aspx">在线选课</a></li>
                <li><a class="<%= Active("MyExams.aspx") %>" href="MyExams.aspx">我的考试</a></li>
                <li><a class="<%= Active("ChangePassword.aspx") %>" href="ChangePassword.aspx">修改密码</a></li>
            </ul>
        </aside>

        <div class="main-content">
            <header class="header-bar">
                <div class="header-left">
                    <button class="hamburger-menu" type="button" aria-label="菜单">&#9776;</button>
                </div>
                <div class="header-right">
                    <button class='dark-toggle-btn' type='button'>暗色模式</button>
                    <div class="user-info">
                        <span class="username">欢迎您, <%= ((Session["User"] as Users)?.Username ?? "学生") %></span>
                        <span class="sep">|</span>
                        <a class="logout-link" href="../Logout.aspx">安全退出</a>
                    </div>
                </div>
            </header>
            <main class="content-body">
                <div class="container-fluid">
        <h2>在线选课与退选</h2>
        <p class="text-muted">请根据培养计划要求，完成本学期课程选择。</p>

        <% if (!string.IsNullOrEmpty(MessageText)) { %>
            <div class="alert alert-<%= MessageType %>"><%= MessageText %></div>
        <% } %>

        <div class="alert alert-warning" style="padding:10px; margin-bottom:15px;">
            <strong>注意：</strong> 带有 <span class="badge bg-danger">必修</span> 标记的课程不可自行退选。
        </div>

        <div class="mb-3">
            <button class="btn btn-primary tab-btn active" data-target="my-selected">我的已选课程 <span class="badge bg-light text-dark"><%= EnrolledCourses.Count %></span></button>
            <button class="btn btn-light tab-btn" data-target="sports-market">体育选修区</button>
            <button class="btn btn-light tab-btn" data-target="other-market">其他选修区</button>
        </div>

        <div id="my-selected" class="tab-pane active">
            <div class="table-responsive">
                <table class="table table-hover bg-white">
                    <thead>
                        <tr>
                            <th>课程名称</th>
                            <th>授课教师</th>
                            <th>学分</th>
                            <th>上课时间与地点</th>
                            <th style="width:130px;" class="text-center">操作</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (EnrolledCourses.Any()) { foreach (var item in EnrolledCourses) { %>
                            <tr>
                                <td>
                                    <strong><%= item.Courses.CourseName %></strong><br />
                                    <span class="badge <%= CourseTypeBadge(item.Courses.CourseType) %>"><%= CourseTypeText(item.Courses.CourseType) %></span>
                                </td>
                                <td><%= TeacherName(item.Courses) %></td>
                                <td><%= item.Courses.Credits %></td>
                                <td><%= RenderScheduleHtml(item.CourseID) %></td>
                                <td class="text-center">
                                    <% if (IsMustCourse(item.Courses)) { %>
                                        <button type="button" class="btn btn-secondary btn-sm" disabled>不可退选</button>
                                    <% } else { %>
                                        <form method="post" style="display:inline;">
                                            <input type="hidden" name="op" value="withdraw" />
                                            <input type="hidden" name="courseId" value="<%= item.CourseID %>" />
                                            <button type="submit" class="btn btn-warning btn-sm" onclick="return confirm('确定退选该课程吗？');">退选</button>
                                        </form>
                                    <% } %>
                                </td>
                            </tr>
                        <% } } else { %>
                            <tr><td colspan="5" class="text-center text-muted py-4">您当前课表为空。</td></tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
        </div>

        <div id="sports-market" class="tab-pane">
            <div class="alert alert-success">体育选修课每人每学期限选 1 门，您当前已选 <strong><%= SportsCoursesTaken %></strong> 门。</div>
            <div class="table-responsive">
                <table class="table table-hover bg-white">
                    <thead><tr><th>课程名称</th><th>教师</th><th>学分</th><th>时间</th><th class="text-center" style="width:100px;">操作</th></tr></thead>
                    <tbody>
                        <% if (SportsElectives.Any()) { foreach (var c in SportsElectives) { %>
                            <tr>
                                <td><strong><%= c.CourseName %></strong><br /><span class="badge bg-success"><%= CourseTypeText(c.CourseType) %></span></td>
                                <td><%= TeacherName(c) %></td>
                                <td><%= c.Credits %></td>
                                <td><%= RenderScheduleHtml(c.CourseID) %></td>
                                <td class="text-center">
                                    <form method="post" style="display:inline;">
                                        <input type="hidden" name="op" value="select" />
                                        <input type="hidden" name="courseId" value="<%= c.CourseID %>" />
                                        <button type="submit" class="btn btn-success btn-sm">选课</button>
                                    </form>
                                </td>
                            </tr>
                        <% } } else { %>
                            <tr><td colspan="5" class="text-center text-muted py-4">暂无可选体育课。</td></tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
        </div>

        <div id="other-market" class="tab-pane">
            <div class="alert alert-info">公共选修课程当前已选 <strong><%= OtherCoursesTaken %></strong> 门。</div>
            <div class="table-responsive">
                <table class="table table-hover bg-white">
                    <thead><tr><th>课程名称</th><th>教师</th><th>学分</th><th>时间</th><th class="text-center" style="width:100px;">操作</th></tr></thead>
                    <tbody>
                        <% if (OtherElectives.Any()) { foreach (var c in OtherElectives) { %>
                            <tr>
                                <td><strong><%= c.CourseName %></strong><br /><span class="badge bg-primary"><%= CourseTypeText(c.CourseType) %></span></td>
                                <td><%= TeacherName(c) %></td>
                                <td><%= c.Credits %></td>
                                <td><%= RenderScheduleHtml(c.CourseID) %></td>
                                <td class="text-center">
                                    <form method="post" style="display:inline;">
                                        <input type="hidden" name="op" value="select" />
                                        <input type="hidden" name="courseId" value="<%= c.CourseID %>" />
                                        <button type="submit" class="btn btn-success btn-sm">选课</button>
                                    </form>
                                </td>
                            </tr>
                        <% } } else { %>
                            <tr><td colspan="5" class="text-center text-muted py-4">暂无可选公共选修课。</td></tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
        </div>
                    </div>
            </main>
        </div>
    </div>
    <script src="<%= ResolveUrl("~/Scripts/webforms-student-layout.js") %>"></script>
    
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script>
        $(function() {
            $('.tab-btn').on('click', function() {
                var target = $(this).data('target');
                $('.tab-btn').removeClass('btn-primary active').addClass('btn-light');
                $(this).removeClass('btn-light').addClass('btn-primary active');
                $('.tab-pane').removeClass('active');
                $('#' + target).addClass('active');
            });
        });
    </script>
</body>
</html>













