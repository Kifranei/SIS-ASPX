<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected string MessageText = string.Empty;
    protected string FormMajor = string.Empty;
    protected string FormAcademicYear = string.Empty;
    protected string FormClassNumber = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "添加班级";
        if (!EnsureAdminRole())
        {
            return;
        }

        if (!Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        FormMajor = (Request.Form["Major"] ?? string.Empty).Trim();
        FormAcademicYear = (Request.Form["AcademicYear"] ?? string.Empty).Trim();
        FormClassNumber = (Request.Form["ClassNumber"] ?? string.Empty).Trim();

        int year;
        int classNumber;
        if (string.IsNullOrWhiteSpace(FormMajor) || !int.TryParse(FormAcademicYear, out year) || !int.TryParse(FormClassNumber, out classNumber))
        {
            MessageText = "请正确填写专业、学年和班号。";
            return;
        }

        // 要求学年必须为四位数字（例如 2021），并在合理范围内，避免 Substring 越界
        if (FormAcademicYear.Length != 4 || year < 1000 || year > DateTime.Now.Year + 1)
        {
            MessageText = "请填写四位学年，例如 2021。";
            return;
        }

        var className = FormMajor + year.ToString().Substring(2, 2) + classNumber.ToString("D2") + "班";
        using (var db = new StudentManagementDBEntities())
        {
            var classModel = new Classes
            {
                Major = FormMajor,
                AcademicYear = year,
                ClassNumber = classNumber,
                ClassName = className
            };
            db.Classes.Add(classModel);
            db.SaveChanges();
            Response.Redirect("ClassList.aspx", true);
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<h2>添加班级</h2>

<% if (!string.IsNullOrEmpty(MessageText)) { %>
    <div class="alert alert-danger"><%= H(MessageText) %></div>
<% } %>

<form method="post" class="form-horizontal" style="max-width:900px;">
    <h4>班级信息</h4>
    <hr />

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
            <button type="submit" class="btn btn-success">创建</button>
            <a class="btn btn-default" href="ClassList.aspx">返回列表</a>
        </div>
    </div>
</form>

<!--#include file="_AdminLayoutBottom.inc" -->

