<%@ Page Language="C#" AutoEventWireup="true" CodePage="65001" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected Courses CurrentCourse;
    protected List<StudentCourses> Enrollments = new List<StudentCourses>();
    protected string ErrorMessage = string.Empty;

    protected string FormatGrade(double? grade)
    {
        return grade.HasValue ? grade.Value.ToString("0.##") : "\u672A\u5F55\u5165";
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        var currentUser = Session["User"] as Users;
        if (currentUser == null || currentUser.Role != 1)
        {
            Response.Redirect("~/Login.aspx", true);
            return;
        }

        int courseId;
        if (!int.TryParse(Request.QueryString["courseId"], out courseId) || courseId <= 0)
        {
            ErrorMessage = "\u53C2\u6570 courseId \u65E0\u6548\u3002";
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
                .FirstOrDefault(c => c.CourseID == courseId && c.TeacherID == teacher.TeacherID);

            if (CurrentCourse == null)
            {
                ErrorMessage = "\u8BFE\u7A0B\u4E0D\u5B58\u5728\u6216\u4E0D\u5C5E\u4E8E\u5F53\u524D\u6559\u5E08\u3002";
                return;
            }

            Enrollments = db.StudentCourses
                .Include("Students.Classes")
                .Where(sc => sc.CourseID == courseId)
                .OrderBy(sc => sc.Students.StudentID)
                .ToList();
        }
    }
</script>

<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>&#x73ED;&#x7EA7;&#x540D;&#x5355;<%= CurrentCourse != null ? " - " + CurrentCourse.CourseName : string.Empty %></title>
    <link href="<%= ResolveUrl("~/Content/bootstrap.min.css") %>" rel="stylesheet" />
    <style>
        body { padding: 20px; }
        .toolbar { margin-bottom: 16px; }
        .toolbar .btn { margin-right: 8px; }
        .print-header { text-align: center; margin-bottom: 20px; }
        .print-table { margin-top: 16px; }
        @media print {
            .no-print { display: none !important; }
            body { padding: 0; }
        }
    </style>
    <script>
        function printRoster() {
            var styles = '' +
                '<style>' +
                '@page{margin:12mm;}' +
                'html,body{margin:0;padding:0;background:#fff;}' +
                'body{padding:20px;font-family:"Microsoft YaHei",sans-serif;color:#111;}' +
                '.print-header{text-align:center;margin-bottom:20px;}' +
                'table{width:100%;border-collapse:collapse;margin-top:16px;}' +
                'th,td{border:1px solid #ddd;padding:8px;}' +
                'th{text-align:left;background:#f5f5f5;}' +
                '.text-center{text-align:center;}' +
                '.text-muted{color:#777;}' +
                '</style>';
            var iframe = document.createElement('iframe');
            iframe.style.position = 'fixed';
            iframe.style.right = '0';
            iframe.style.bottom = '0';
            iframe.style.width = '0';
            iframe.style.height = '0';
            iframe.style.border = '0';
            document.body.appendChild(iframe);

            var hasPrinted = false;
            function finalizePrint() {
                if (hasPrinted || !document.body.contains(iframe)) {
                    return;
                }

                hasPrinted = true;
                iframe.contentWindow.focus();
                iframe.contentWindow.print();
                window.setTimeout(function () {
                    if (document.body.contains(iframe)) {
                        document.body.removeChild(iframe);
                    }
                }, 1000);
            }

            var doc = iframe.contentWindow.document;
            doc.open();
            doc.write('<!DOCTYPE html><html><head><meta charset="utf-8" /><title>&#x6253;&#x5370;&#x5B66;&#x751F;&#x540D;&#x5355;</title>' + styles + '</head><body>');
            doc.write(document.getElementById('print-area').innerHTML);
            doc.write('</body></html>');
            doc.close();

            iframe.onload = finalizePrint;
            window.setTimeout(finalizePrint, 200);
        }
    </script>
</head>
<body>
    <div class="container-fluid">
        <% if (!string.IsNullOrEmpty(ErrorMessage)) { %>
            <div class="alert alert-danger"><%= ErrorMessage %></div>
            <a class="btn btn-default no-print" href="CourseList.aspx">&#x8FD4;&#x56DE;&#x6388;&#x8BFE;&#x5217;&#x8868;</a>
        <% } else { %>
            <div class="toolbar no-print">
                <button class="btn btn-primary" type="button" onclick="printRoster();">&#x6253;&#x5370;&#x540D;&#x5355;</button>
                <a class="btn btn-default" href="CourseList.aspx">&#x8FD4;&#x56DE;&#x6388;&#x8BFE;&#x5217;&#x8868;</a>
            </div>

            <div id="print-area">
                <div class="print-header">
                    <h2><%= CurrentCourse.CourseName %></h2>
                    <h4>&#x73ED;&#x7EA7;&#x5B66;&#x751F;&#x540D;&#x5355;</h4>
                    <p>
                        &#x6388;&#x8BFE;&#x6559;&#x5E08;&#xFF1A;<%= CurrentCourse.Teachers == null ? "-" : Server.HtmlEncode(CurrentCourse.Teachers.TeacherName) %>
                    </p>
                </div>

                <table class="table table-bordered table-striped print-table">
                    <thead>
                        <tr>
                            <th class="text-center" style="width: 70px;">&#x5E8F;&#x53F7;</th>
                            <th>&#x5B66;&#x53F7;</th>
                            <th>&#x59D3;&#x540D;</th>
                            <th>&#x6027;&#x522B;</th>
                            <th>&#x73ED;&#x7EA7;</th>
                            <th>&#x6210;&#x7EE9;</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (int i = 0; i < Enrollments.Count; i++) {
                               var item = Enrollments[i];
                               var student = item.Students; %>
                            <tr>
                                <td class="text-center"><%= i + 1 %></td>
                                <td><%= student == null ? "-" : Server.HtmlEncode(student.StudentID) %></td>
                                <td><%= student == null ? "-" : Server.HtmlEncode(student.StudentName) %></td>
                                <td><%= student == null ? "-" : Server.HtmlEncode(student.Gender) %></td>
                                <td><%= student == null || student.Classes == null ? "-" : Server.HtmlEncode(student.Classes.ClassName) %></td>
                                <td><%= FormatGrade(item.Grade) %></td>
                            </tr>
                        <% } %>
                        <% if (!Enrollments.Any()) { %>
                            <tr>
                                <td colspan="6" class="text-center text-muted">&#x6682;&#x65E0;&#x5B66;&#x751F;&#x540D;&#x5355;</td>
                            </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
        <% } %>
    </div>
</body>
</html>
