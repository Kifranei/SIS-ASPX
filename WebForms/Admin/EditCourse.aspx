<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Courses CurrentCourse;
    protected List<Teachers> TeacherOptions = new List<Teachers>();
    protected List<StudentCourses> EnrolledStudents = new List<StudentCourses>();
    protected List<Students> AvailableStudents = new List<Students>();

    protected string MessageText = string.Empty;
    protected string EnrollmentMessageText = string.Empty;
    protected string EnrollmentMessageType = "info";
    protected string PostAction = string.Empty;

    protected int FormCourseID = 0;
    protected string FormCourseName = string.Empty;
    protected string FormCredits = string.Empty;
    protected string FormTeacherID = string.Empty;
    protected string FormCourseType = string.Empty;
    protected string SelectedStudentID = string.Empty;
    protected bool IsCompulsoryCourse = false;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "编辑课程信息";
        if (!EnsureAdminRole())
        {
            return;
        }

        PostAction = (Request.Form["Action"] ?? string.Empty).Trim();

        if (!TryGetCourseId(out FormCourseID) || FormCourseID <= 0)
        {
            MessageText = "课程参数无效。";
            LoadTeacherOptions();
            return;
        }

        if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
        {
            if (string.Equals(PostAction, "addStudent", StringComparison.OrdinalIgnoreCase))
            {
                SelectedStudentID = (Request.Form["StudentID"] ?? string.Empty).Trim();
                AddStudentToCourse();
            }
            else if (string.Equals(PostAction, "removeStudent", StringComparison.OrdinalIgnoreCase))
            {
                SelectedStudentID = (Request.Form["StudentID"] ?? string.Empty).Trim();
                RemoveStudentFromCourse();
            }
            else
            {
                FormCourseName = (Request.Form["CourseName"] ?? string.Empty).Trim();
                FormCredits = (Request.Form["Credits"] ?? string.Empty).Trim();
                FormTeacherID = (Request.Form["TeacherID"] ?? string.Empty).Trim();
                FormCourseType = (Request.Form["CourseType"] ?? string.Empty).Trim();
                SaveCourse();
            }
        }

        LoadCourseAndForm();
        LoadTeacherOptions();
        LoadEnrollmentData();
    }

    private bool TryGetCourseId(out int courseId)
    {
        courseId = 0;
        var formCourseId = Request.Form["CourseID"];
        if (!string.IsNullOrWhiteSpace(formCourseId) && int.TryParse(formCourseId, out courseId))
        {
            return true;
        }

        var queryCourseId = Request.QueryString["id"];
        if (!string.IsNullOrWhiteSpace(queryCourseId) && int.TryParse(queryCourseId, out courseId))
        {
            return true;
        }

        return false;
    }

    private bool IsCompulsoryType(int courseType)
    {
        return courseType == 1 || courseType == 2;
    }

    private void LoadCourseAndForm()
    {
        using (var db = new StudentManagementDBEntities())
        {
            CurrentCourse = db.Courses.Find(FormCourseID);
        }

        if (CurrentCourse == null)
        {
            MessageText = "课程不存在。";
            return;
        }

        IsCompulsoryCourse = IsCompulsoryType(CurrentCourse.CourseType);

        var shouldUseDbValues = !Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase)
            || string.Equals(PostAction, "addStudent", StringComparison.OrdinalIgnoreCase)
            || string.Equals(PostAction, "removeStudent", StringComparison.OrdinalIgnoreCase);

        if (shouldUseDbValues)
        {
            FormCourseName = CurrentCourse.CourseName;
            FormCredits = CurrentCourse.Credits.ToString();
            FormTeacherID = CurrentCourse.TeacherID;
            FormCourseType = CurrentCourse.CourseType.ToString();
        }
    }

    private void LoadTeacherOptions()
    {
        using (var db = new StudentManagementDBEntities())
        {
            TeacherOptions = db.Teachers.OrderBy(t => t.TeacherName).ToList();
        }
    }

    private void SaveCourse()
    {
        if (FormCourseID <= 0)
        {
            MessageText = "课程参数无效。";
            return;
        }

        if (string.IsNullOrWhiteSpace(FormCourseName))
        {
            MessageText = "课程名称不能为空。";
            return;
        }

        double credits;
        if (!double.TryParse(FormCredits, out credits))
        {
            MessageText = "学分格式不正确。";
            return;
        }

        int courseType;
        if (!int.TryParse(FormCourseType, out courseType))
        {
            MessageText = "请选择课程类别。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            var course = db.Courses.Find(FormCourseID);
            if (course == null)
            {
                MessageText = "课程不存在。";
                return;
            }

            var newTeacherId = string.IsNullOrWhiteSpace(FormTeacherID) ? null : FormTeacherID;
            if (!string.Equals(course.TeacherID, newTeacherId, StringComparison.OrdinalIgnoreCase)
                && !string.IsNullOrWhiteSpace(newTeacherId))
            {
                var courseSessions = db.ClassSessions.Where(cs => cs.CourseID == FormCourseID).ToList();
                var teacherConflicts = new List<ClassSessions>();

                foreach (var session in courseSessions)
                {
                    teacherConflicts.AddRange(ScheduleConflictHelper.GetTeacherSessionConflicts(
                        db,
                        newTeacherId,
                        session.DayOfWeek,
                        session.StartWeek,
                        session.EndWeek,
                        session.StartPeriod,
                        session.EndPeriod));
                }

                teacherConflicts = teacherConflicts
                    .GroupBy(cs => cs.SessionID)
                    .Select(g => g.First())
                    .ToList();

                if (teacherConflicts.Any())
                {
                    MessageText = ScheduleConflictHelper.BuildTeacherConflictMessage(
                        teacherConflicts,
                        "无法分配该教师，当前课程既有安排与该教师已有课表冲突：");
                    return;
                }
            }

            course.CourseName = FormCourseName;
            course.Credits = credits;
            course.TeacherID = newTeacherId;
            course.CourseType = courseType;
            db.Entry(course).State = EntityState.Modified;
            db.SaveChanges();

            Response.Redirect("CourseList.aspx", true);
        }
    }

    private void AddStudentToCourse()
    {
        using (var db = new StudentManagementDBEntities())
        {
            var course = db.Courses.Find(FormCourseID);
            if (course == null)
            {
                EnrollmentMessageType = "danger";
                EnrollmentMessageText = "课程不存在。";
                return;
            }

            if (!IsCompulsoryType(course.CourseType))
            {
                EnrollmentMessageType = "warning";
                EnrollmentMessageText = "只有专业必修/公共必修课程可以通过此入口分配学生。";
                return;
            }

            if (string.IsNullOrWhiteSpace(SelectedStudentID))
            {
                EnrollmentMessageType = "warning";
                EnrollmentMessageText = "请选择要添加的学生。";
                return;
            }

            SelectedStudentID = SelectedStudentID.Trim();
            var student = db.Students.Find(SelectedStudentID);
            if (student == null)
            {
                EnrollmentMessageType = "danger";
                EnrollmentMessageText = "学生不存在。";
                return;
            }

            var exists = db.StudentCourses.Any(sc => sc.CourseID == FormCourseID && sc.StudentID == SelectedStudentID);
            if (exists)
            {
                EnrollmentMessageType = "info";
                EnrollmentMessageText = "该学生已在本课程名单中，无需重复添加。";
                return;
            }

            var conflicts = ScheduleConflictHelper.GetStudentConflictsForCourseAssignment(db, SelectedStudentID, FormCourseID);
            if (conflicts.Any())
            {
                EnrollmentMessageType = "danger";
                EnrollmentMessageText = ScheduleConflictHelper.BuildStudentConflictMessage(
                    conflicts,
                    "无法加入课程名单，学生课表存在冲突：");
                return;
            }

            db.StudentCourses.Add(new StudentCourses
            {
                StudentID = SelectedStudentID,
                CourseID = FormCourseID,
                Grade = null
            });
            db.SaveChanges();

            EnrollmentMessageType = "success";
            EnrollmentMessageText = "学生已成功添加到课程名单。";
            SelectedStudentID = string.Empty;
        }
    }

    private void RemoveStudentFromCourse()
    {
        using (var db = new StudentManagementDBEntities())
        {
            var course = db.Courses.Find(FormCourseID);
            if (course == null)
            {
                EnrollmentMessageType = "danger";
                EnrollmentMessageText = "课程不存在。";
                return;
            }

            if (!IsCompulsoryType(course.CourseType))
            {
                EnrollmentMessageType = "warning";
                EnrollmentMessageText = "只有专业必修/公共必修课程可以通过此入口调整学生名单。";
                return;
            }

            if (string.IsNullOrWhiteSpace(SelectedStudentID))
            {
                EnrollmentMessageType = "warning";
                EnrollmentMessageText = "学生参数无效。";
                return;
            }

            SelectedStudentID = SelectedStudentID.Trim();
            var enrollment = db.StudentCourses.FirstOrDefault(sc => sc.CourseID == FormCourseID && sc.StudentID == SelectedStudentID);
            if (enrollment == null)
            {
                EnrollmentMessageType = "info";
                EnrollmentMessageText = "该学生已不在课程名单中。";
                return;
            }

            db.StudentCourses.Remove(enrollment);
            db.SaveChanges();

            EnrollmentMessageType = "success";
            EnrollmentMessageText = "学生已从课程名单中移除。";
            SelectedStudentID = string.Empty;
        }
    }

    private void LoadEnrollmentData()
    {
        if (FormCourseID <= 0 || !IsCompulsoryCourse)
        {
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            EnrolledStudents = db.StudentCourses
                .Include("Students.Classes")
                .Where(sc => sc.CourseID == FormCourseID)
                .OrderBy(sc => sc.StudentID)
                .ToList();

            var enrolledIds = EnrolledStudents.Select(sc => sc.StudentID).ToList();
            AvailableStudents = db.Students
                .Include("Classes")
                .Where(s => !enrolledIds.Contains(s.StudentID))
                .OrderBy(s => s.StudentID)
                .ToList();
        }
    }

    protected string StudentClassName(Students student)
    {
        if (student == null || student.Classes == null)
        {
            return "未分班";
        }

        return student.Classes.ClassName ?? "未分班";
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>编辑课程信息</h2>
<% if (!string.IsNullOrWhiteSpace(FormCourseName)) { %><h4><%= H(FormCourseName) %></h4><% } %>
<hr />

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } else { %>
    <form method="post" class="form-horizontal" style="max-width:900px;">
        <input type="hidden" name="Action" value="saveCourse" />
        <input type="hidden" name="CourseID" value="<%= FormCourseID %>" />

        <div class="form-group">
            <label class="control-label col-md-2">课程名称</label>
            <div class="col-md-10">
                <input class="form-control" name="CourseName" value="<%= H(FormCourseName) %>" required />
            </div>
        </div>

        <div class="form-group">
            <label class="control-label col-md-2">学分</label>
            <div class="col-md-10">
                <input class="form-control" name="Credits" value="<%= H(FormCredits) %>" required />
            </div>
        </div>

        <div class="form-group">
            <label class="control-label col-md-2">教师姓名</label>
            <div class="col-md-10">
                <select class="form-control" name="TeacherID">
                    <option value="">--请选择教师--</option>
                    <% foreach (var t in TeacherOptions) { %>
                        <option value="<%= H(t.TeacherID) %>" <%= string.Equals(FormTeacherID, t.TeacherID, StringComparison.OrdinalIgnoreCase) ? "selected" : "" %>><%= H(t.TeacherName) %></option>
                    <% } %>
                </select>
            </div>
        </div>

        <div class="form-group">
            <label class="control-label col-md-2">课程类别</label>
            <div class="col-md-10">
                <select class="form-control" name="CourseType" required>
                    <option value="">--请选择类别--</option>
                    <option value="1" <%= FormCourseType == "1" ? "selected" : "" %>>专业必修</option>
                    <option value="2" <%= FormCourseType == "2" ? "selected" : "" %>>公共必修</option>
                    <option value="3" <%= FormCourseType == "3" ? "selected" : "" %>>专业选修</option>
                    <option value="4" <%= FormCourseType == "4" ? "selected" : "" %>>公共选修</option>
                    <option value="5" <%= FormCourseType == "5" ? "selected" : "" %>>体育选修</option>
                </select>
            </div>
        </div>

        <div class="form-group">
            <div class="col-md-offset-2 col-md-10">
                <button type="submit" class="btn btn-success">保 存</button>
                <a class="btn btn-default" href="CourseList.aspx">返回列表</a>
            </div>
        </div>
    </form>

    <hr />
    <h3>课程学生管理（仅必修课）</h3>

    <% if (!IsCompulsoryCourse) { %>
        <div class="alert alert-info">当前课程不是必修课（专业必修/公共必修），不支持在此页分配学生。</div>
    <% } else { %>
        <% if (!string.IsNullOrWhiteSpace(EnrollmentMessageText)) { %>
            <div class="alert alert-<%= H(EnrollmentMessageType) %>"><%= H(EnrollmentMessageText) %></div>
        <% } %>

        <form method="post" class="form-inline" style="margin-bottom: 15px;">
            <input type="hidden" name="Action" value="addStudent" />
            <input type="hidden" name="CourseID" value="<%= FormCourseID %>" />
            <div class="form-group" style="min-width: 420px; margin-right: 10px;">
                <label style="margin-right: 8px;">添加学生：</label>
                <select class="form-control" name="StudentID" style="min-width: 340px;" required>
                    <option value="">--请选择学生--</option>
                    <% foreach (var s in AvailableStudents) { %>
                        <option value="<%= H(s.StudentID) %>" <%= string.Equals(SelectedStudentID, s.StudentID, StringComparison.OrdinalIgnoreCase) ? "selected" : "" %>>
                            <%= H(s.StudentID) %> - <%= H(s.StudentName) %>（<%= H(StudentClassName(s)) %>）
                        </option>
                    <% } %>
                </select>
            </div>
            <button type="submit" class="btn btn-primary" <%= AvailableStudents.Any() ? "" : "disabled" %>>添加到课程</button>
            <% if (!AvailableStudents.Any()) { %>
                <span class="text-muted" style="margin-left: 8px;">暂无可添加学生。</span>
            <% } %>
        </form>

        <div class="table-responsive">
            <table class="table table-striped table-bordered">
                <thead>
                    <tr>
                        <th>学号</th>
                        <th>姓名</th>
                        <th>性别</th>
                        <th>班级</th>
                        <th style="width: 110px;">操作</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (EnrolledStudents.Any()) { %>
                        <% foreach (var item in EnrolledStudents) { var stu = item.Students; %>
                            <tr>
                                <td><%= stu == null ? "-" : H(stu.StudentID) %></td>
                                <td><%= stu == null ? "-" : H(stu.StudentName) %></td>
                                <td><%= stu == null ? "-" : H(stu.Gender) %></td>
                                <td><%= stu == null ? "-" : H(StudentClassName(stu)) %></td>
                                <td>
                                    <% if (stu != null) { %>
                                        <form method="post" style="display:inline;" onsubmit="return confirm('确认将该学生从本课程中移除？');">
                                            <input type="hidden" name="Action" value="removeStudent" />
                                            <input type="hidden" name="CourseID" value="<%= FormCourseID %>" />
                                            <input type="hidden" name="StudentID" value="<%= H(stu.StudentID) %>" />
                                            <button type="submit" class="btn btn-danger btn-xs">移除</button>
                                        </form>
                                    <% } else { %>
                                        <span class="text-muted">-</span>
                                    <% } %>
                                </td>
                            </tr>
                        <% } %>
                    <% } else { %>
                        <tr><td colspan="5" class="text-center text-muted">该课程当前还没有学生。</td></tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    <% } %>
<% } %>

<!--#include file="_AdminLayoutBottom.inc" -->
