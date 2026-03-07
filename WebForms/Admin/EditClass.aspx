<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected Classes CurrentClass;
    protected string MessageText = string.Empty;
    protected int FormClassID = 0;
    protected string FormMajor = string.Empty;
    protected string FormAcademicYear = string.Empty;
    protected string FormClassNumber = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "编辑班级信息";
        if (!EnsureAdminRole())
        {
            return;
        }

        if (Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
        {
            int.TryParse(Request.Form["ClassID"], out FormClassID);
            FormMajor = (Request.Form["Major"] ?? string.Empty).Trim();
            FormAcademicYear = (Request.Form["AcademicYear"] ?? string.Empty).Trim();
            FormClassNumber = (Request.Form["ClassNumber"] ?? string.Empty).Trim();
            SaveClass();
        }
        else
        {
            int id;
            if (!int.TryParse(Request.QueryString["id"], out id) || id <= 0)
            {
                MessageText = "班级参数无效。";
            }
            else
            {
                using (var db = new StudentManagementDBEntities())
                {
                    CurrentClass = db.Classes.Find(id);
                }

                if (CurrentClass == null)
                {
                    MessageText = "班级不存在。";
                }
                else
                {
                    FormClassID = CurrentClass.ClassID;
                    FormMajor = CurrentClass.Major;
                    FormAcademicYear = CurrentClass.AcademicYear.HasValue ? CurrentClass.AcademicYear.Value.ToString() : string.Empty;
                    FormClassNumber = CurrentClass.ClassNumber.HasValue ? CurrentClass.ClassNumber.Value.ToString() : string.Empty;
                }
            }
        }
    }

    private void SaveClass()
    {
        int year;
        int classNumber;
        if (FormClassID <= 0 || string.IsNullOrWhiteSpace(FormMajor) || !int.TryParse(FormAcademicYear, out year) || !int.TryParse(FormClassNumber, out classNumber))
        {
            MessageText = "请正确填写专业、学年和班号。";
            return;
        }

        var className = FormMajor + year.ToString().Substring(2, 2) + classNumber.ToString("D2") + "班";

        using (var db = new StudentManagementDBEntities())
        {
            var classModel = db.Classes.Find(FormClassID);
            if (classModel == null)
            {
                MessageText = "班级不存在。";
                return;
            }

            classModel.Major = FormMajor;
            classModel.AcademicYear = year;
            classModel.ClassNumber = classNumber;
            classModel.ClassName = className;
            db.Entry(classModel).State = EntityState.Modified;
            db.SaveChanges();

            Response.Redirect("ClassList.aspx", true);
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>编辑班级信息</h2>
<% if (FormClassID > 0) { %><h4><%= H(FormMajor) %></h4><% } %>

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } else { %>
    <form method="post" class="form-horizontal" style="max-width:900px;">
        <input type="hidden" name="ClassID" value="<%= FormClassID %>" />

        <div class="form-group">
            <label class="control-label col-md-2">专业</label>
            <div class="col-md-10">
                <input class="form-control" name="Major" value="<%= H(FormMajor) %>" required />
            </div>
        </div>

        <div class="form-group">
            <label class="control-label col-md-2">学年</label>
            <div class="col-md-10">
                <input class="form-control" name="AcademicYear" value="<%= H(FormAcademicYear) %>" required />
            </div>
        </div>

        <div class="form-group">
            <label class="control-label col-md-2">班号</label>
            <div class="col-md-10">
                <input class="form-control" name="ClassNumber" value="<%= H(FormClassNumber) %>" required />
            </div>
        </div>

        <div class="form-group">
            <div class="col-md-offset-2 col-md-10">
                <button type="submit" class="btn btn-success">保 存</button>
                <a class="btn btn-default" href="ClassList.aspx">返回列表</a>
            </div>
        </div>
    </form>
<% } %>

<!--#include file="_AdminLayoutBottom.inc" -->
