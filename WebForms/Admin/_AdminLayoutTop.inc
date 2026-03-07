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
                <img src="https://jwgl.hrbzy.edu.cn:9081/style04/images/logo.png" height="35" alt="校徽" class="sidebar-logo-img" />
            </div>
            <ul class="sidebar-menu">
                <li><a class="<%= MenuActive("Index.aspx") %>" href="Index.aspx">控制台</a></li>
                <li><a class="<%= MenuActive("StudentList.aspx|AddStudent.aspx|Edit.aspx|Details.aspx|Delete.aspx") %>" href="StudentList.aspx">学生管理</a></li>
                <li><a class="<%= MenuActive("TeacherList.aspx|AddTeacher.aspx|EditTeacher.aspx|DetailsTeacher.aspx|DeleteTeacher.aspx") %>" href="TeacherList.aspx">教师管理</a></li>
                <li><a class="<%= MenuActive("ClassList.aspx|AddClass.aspx|EditClass.aspx|DeleteClass.aspx|ClassDetails.aspx") %>" href="ClassList.aspx">班级管理</a></li>
                <li><a class="<%= MenuActive("CourseList.aspx|AddCourse.aspx|EditCourse.aspx|DetailsCourse.aspx|DeleteCourse.aspx|CourseSchedule.aspx|AddCourseSchedule.aspx|EditCourseSchedule.aspx|DeleteCourseSchedule.aspx") %>" href="CourseList.aspx">课程管理</a></li>
                <li><a class="<%= MenuActive("EnrollmentList.aspx") %>" href="EnrollmentList.aspx">选课记录</a></li>
                <li><a class="<%= MenuActive("ExamList.aspx|AddExam.aspx|EditExam.aspx|DetailsExam.aspx|DeleteExam.aspx") %>" href="ExamList.aspx">考试管理</a></li>
                <li><a class="<%= MenuActive("ChangePassword.aspx") %>" href="ChangePassword.aspx">修改密码</a></li>
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
                        <span class="username">欢迎您, <%= Server.HtmlEncode(CurrentUsername) %></span>
                        <span class="sep">|</span>
                        <a class="logout-link" href="../Logout.aspx">安全退出</a>
                    </div>
                </div>
            </header>
            <main class="content-body">
                <div class="container-fluid">
