<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Students CurrentStudent;
    protected List<Classes> ClassOptions = new List<Classes>();
    protected string MessageText = string.Empty;

    protected string FormStudentID = string.Empty;
    protected string FormStudentName = string.Empty;
    protected string FormGender = string.Empty;
    protected int FormUserID = 0;
    protected int? FormClassID = null;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "编辑学生信息";
        if (!EnsureAdminRole())
        {
            return;
        }

        if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
        {
            FormStudentID = (Request.Form["StudentID"] ?? string.Empty).Trim();
            FormStudentName = (Request.Form["StudentName"] ?? string.Empty).Trim();
            FormGender = NormalizeGender(Request.Form["Gender"]);
            int uid;
            if (int.TryParse(Request.Form["UserID"], out uid))
            {
                FormUserID = uid;
            }
            int cid;
            if (int.TryParse(Request.Form["ClassID"], out cid))
            {
                FormClassID = cid;
            }

            SaveStudent();
        }
        else
        {
            var id = (Request.QueryString["id"] ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(id))
            {
                MessageText = "缺少学生ID参数。";
            }
            else
            {
                using (var db = new StudentManagementDBEntities())
                {
                    CurrentStudent = db.Students.Find(id);
                }

                if (CurrentStudent == null)
                {
                    MessageText = "学生不存在。";
                }
                else
                {
                    FormStudentID = CurrentStudent.StudentID;
                    FormStudentName = CurrentStudent.StudentName;
                    FormGender = NormalizeGender(CurrentStudent.Gender);
                    FormClassID = CurrentStudent.ClassID;
                    FormUserID = CurrentStudent.UserID;
                }
            }
        }

        using (var db = new StudentManagementDBEntities())
        {
            ClassOptions = db.Classes.OrderBy(c => c.ClassName).ToList();
            if (CurrentStudent == null && !string.IsNullOrWhiteSpace(FormStudentID))
            {
                CurrentStudent = db.Students.Find(FormStudentID);
            }
        }
    }

    private void SaveStudent()
    {
        if (string.IsNullOrWhiteSpace(FormStudentID) || string.IsNullOrWhiteSpace(FormStudentName))
        {
            MessageText = "学号和姓名不能为空。";
            return;
        }

        if (!IsValidGender(FormGender))
        {
            MessageText = "性别只能选择“男”或“女”。";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            var student = db.Students.Find(FormStudentID);
            if (student == null)
            {
                MessageText = "学生不存在。";
                return;
            }

            student.StudentName = FormStudentName;
            student.Gender = FormGender;
            student.ClassID = FormClassID;
            if (FormUserID > 0)
            {
                student.UserID = FormUserID;
            }

            db.Entry(student).State = EntityState.Modified;
            db.SaveChanges();

            Response.Redirect("StudentList.aspx", true);
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>编辑学生信息</h2>
<% if (!string.IsNullOrWhiteSpace(FormStudentName)) { %>
    <h4><%= H(FormStudentName) %></h4>
<% } %>
<hr />

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } else { %>
    <form method="post" class="form-horizontal" style="max-width:900px;">
        <input type="hidden" name="StudentID" value="<%= H(FormStudentID) %>" />
        <input type="hidden" name="UserID" value="<%= FormUserID %>" />

        <div class="form-group">
            <label class="control-label col-md-2">学号 (不可修改)</label>
            <div class="col-md-10">
                <input class="form-control" value="<%= H(FormStudentID) %>" readonly />
            </div>
        </div>

        <div class="form-group">
            <label class="control-label col-md-2">姓名</label>
            <div class="col-md-10">
                <input class="form-control" name="StudentName" value="<%= H(FormStudentName) %>" required />
            </div>
        </div>

        <div class="form-group">
            <label class="control-label col-md-2">性别</label>
            <div class="col-md-10">
                <select class="form-control" name="Gender" required>
                    <option value="">--请选择性别--</option>
                    <option value="男" <%= FormGender == "男" ? "selected" : "" %>>男</option>
                    <option value="女" <%= FormGender == "女" ? "selected" : "" %>>女</option>
                </select>
            </div>
        </div>

        <div class="form-group">
            <label class="control-label col-md-2">班级</label>
            <div class="col-md-10">
                <select class="form-control" name="ClassID">
                    <option value="">--请选择班级--</option>
                    <% foreach (var cls in ClassOptions) { %>
                        <option value="<%= cls.ClassID %>" <%= FormClassID.HasValue && FormClassID.Value == cls.ClassID ? "selected" : "" %>><%= H(cls.ClassName) %></option>
                    <% } %>
                </select>
            </div>
        </div>

        <div class="form-group">
            <div class="col-md-offset-2 col-md-10">
                <button type="submit" class="btn btn-success">保 存</button>
                <a class="btn btn-default" href="StudentList.aspx">返回列表</a>
            </div>
        </div>
    </form>
<% } %>

<!--#include file="_AdminLayoutBottom.inc" -->

