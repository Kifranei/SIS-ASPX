<!DOCTYPE html>
<html lang="zh-CN">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <script>
        (function () {
            var theme = localStorage.getItem('theme');
            if (theme === 'dark') {
                document.documentElement.classList.add('dark-mode');
            } else {
                document.documentElement.classList.remove('dark-mode');
            }
        })();
    </script>
    <title><%= PageTitle %></title>
    <link href="<%= ResolveUrl("~/Content/bootstrap.min.css") %>" rel="stylesheet" />
    <link href="<%= ResolveUrl("~/Content/theme-system.css") %>" rel="stylesheet" />
    <link href="<%= ResolveUrl("~/Content/webforms-student-layout.css") %>" rel="stylesheet" />
</head>
<body class="webforms-student">
    <div class="page-wrapper">
        <div class="sidebar-overlay"></div>
        <aside class="sidebar">
            <div class="sidebar-header">
                <img src="https://jwgl.hrbzy.edu.cn:9081/style04/images/logo.png" height="35" alt="&#x6821;&#x5FBD;" class="sidebar-logo-img" />
            </div>
            <ul class="sidebar-menu">
                <li><a class="<%= MenuActive("Index.aspx") %>" href="Index.aspx">&#x63A7;&#x5236;&#x53F0;</a></li>
                <li><a class="<%= MenuActive("StudentList.aspx|AddStudent.aspx|Edit.aspx|Details.aspx|Delete.aspx") %>" href="StudentList.aspx">&#x5B66;&#x751F;&#x7BA1;&#x7406;</a></li>
                <li><a class="<%= MenuActive("TeacherList.aspx|AddTeacher.aspx|EditTeacher.aspx|DetailsTeacher.aspx|DeleteTeacher.aspx") %>" href="TeacherList.aspx">&#x6559;&#x5E08;&#x7BA1;&#x7406;</a></li>
                <li><a class="<%= MenuActive("ClassList.aspx|AddClass.aspx|EditClass.aspx|DeleteClass.aspx|ClassDetails.aspx") %>" href="ClassList.aspx">&#x73ED;&#x7EA7;&#x7BA1;&#x7406;</a></li>
                <li><a class="<%= MenuActive("CourseList.aspx|AddCourse.aspx|EditCourse.aspx|DetailsCourse.aspx|DeleteCourse.aspx|CourseSchedule.aspx|AddCourseSchedule.aspx|EditCourseSchedule.aspx|DeleteCourseSchedule.aspx") %>" href="CourseList.aspx">&#x8BFE;&#x7A0B;&#x7BA1;&#x7406;</a></li>
                <li><a class="<%= MenuActive("EnrollmentList.aspx") %>" href="EnrollmentList.aspx">&#x9009;&#x8BFE;&#x8BB0;&#x5F55;</a></li>
                <li><a class="<%= MenuActive("ExamList.aspx|AddExam.aspx|EditExam.aspx|DetailsExam.aspx|DeleteExam.aspx") %>" href="ExamList.aspx">&#x8003;&#x8BD5;&#x7BA1;&#x7406;</a></li>
                <li><a class="<%= MenuActive("ChangePassword.aspx") %>" href="ChangePassword.aspx">&#x4FEE;&#x6539;&#x5BC6;&#x7801;</a></li>
            </ul>
        </aside>

        <div class="main-content">
            <header class="header-bar">
                <div class="header-left">
                    <button class="hamburger-menu" type="button" aria-label="menu">&#9776;</button>
                </div>
                <div class="header-right">
                    <button class='dark-toggle-btn' type='button'>&#x6697;&#x8272;&#x6A21;&#x5F0F;</button>
                    <div class="user-info">
                        <span class="username">&#x6B22;&#x8FCE;&#x60A8;, <%= Server.HtmlEncode(CurrentUsername) %></span>
                        <span class="sep">|</span>
                        <a class="logout-link" href="../Logout.aspx">&#x5B89;&#x5168;&#x9000;&#x51FA;</a>
                    </div>
                </div>
            </header>
            <main class="content-body">
                <div class="container-fluid">
