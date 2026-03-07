<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected int StudentsCount;
    protected int TeachersCount;
    protected int CoursesCount;
    protected int EnrollmentsCount;
    protected string ServerName = string.Empty;
    protected string ServerSoftware = string.Empty;
    protected string DotNetVersion = string.Empty;
    protected double MemoryUsage;
    protected DateTime StartTime;
    protected TimeSpan RunningTime;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "管理员控制台";
        if (!EnsureAdminRole())
        {
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            StudentsCount = db.Students.Count();
            TeachersCount = db.Teachers.Count();
            CoursesCount = db.Courses.Count();
            EnrollmentsCount = db.StudentCourses.Count();
        }

        var currentProcess = System.Diagnostics.Process.GetCurrentProcess();
        ServerName = Environment.MachineName;
        ServerSoftware = Request.ServerVariables["SERVER_SOFTWARE"] ?? "-";
        DotNetVersion = Environment.Version.ToString();
        MemoryUsage = Math.Round(currentProcess.WorkingSet64 / 1024.0 / 1024.0, 2);
        StartTime = currentProcess.StartTime;
        RunningTime = DateTime.Now - currentProcess.StartTime;
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->

<div class="jumbotron">
    <h1>管理员控制台</h1>
    <p class="lead">欢迎回来，管理员！以下是当前系统的核心数据统计。</p>
</div>

<div class="row">
    <div class="col-lg-3 col-md-6">
        <div class="panel panel-primary">
            <div class="panel-heading">
                <div class="row">
                    <div class="col-xs-3"><i class="glyphicon glyphicon-user" style="font-size:50px;"></i></div>
                    <div class="col-xs-9 text-right">
                        <div style="font-size:40px;"><%= StudentsCount %></div>
                        <div>学生总数</div>
                    </div>
                </div>
            </div>
            <a href="StudentList.aspx"><div class="panel-footer"><span class="pull-left">查看详情</span><span class="pull-right"><i class="glyphicon glyphicon-circle-arrow-right"></i></span><div class="clearfix"></div></div></a>
        </div>
    </div>

    <div class="col-lg-3 col-md-6">
        <div class="panel panel-green">
            <div class="panel-heading">
                <div class="row">
                    <div class="col-xs-3"><i class="glyphicon glyphicon-education" style="font-size:50px;"></i></div>
                    <div class="col-xs-9 text-right">
                        <div style="font-size:40px;"><%= TeachersCount %></div>
                        <div>教师总数</div>
                    </div>
                </div>
            </div>
            <a href="TeacherList.aspx"><div class="panel-footer"><span class="pull-left">查看详情</span><span class="pull-right"><i class="glyphicon glyphicon-circle-arrow-right"></i></span><div class="clearfix"></div></div></a>
        </div>
    </div>

    <div class="col-lg-3 col-md-6">
        <div class="panel panel-yellow">
            <div class="panel-heading">
                <div class="row">
                    <div class="col-xs-3"><i class="glyphicon glyphicon-list-alt" style="font-size:50px;"></i></div>
                    <div class="col-xs-9 text-right">
                        <div style="font-size:40px;"><%= CoursesCount %></div>
                        <div>课程总数</div>
                    </div>
                </div>
            </div>
            <a href="CourseList.aspx"><div class="panel-footer"><span class="pull-left">查看详情</span><span class="pull-right"><i class="glyphicon glyphicon-circle-arrow-right"></i></span><div class="clearfix"></div></div></a>
        </div>
    </div>

    <div class="col-lg-3 col-md-6">
        <div class="panel panel-red">
            <div class="panel-heading">
                <div class="row">
                    <div class="col-xs-3"><i class="glyphicon glyphicon-check" style="font-size:50px;"></i></div>
                    <div class="col-xs-9 text-right">
                        <div style="font-size:40px;"><%= EnrollmentsCount %></div>
                        <div>总选课人次</div>
                    </div>
                </div>
            </div>
            <a href="EnrollmentList.aspx"><div class="panel-footer"><span class="pull-left">查看详情</span><span class="pull-right"><i class="glyphicon glyphicon-circle-arrow-right"></i></span><div class="clearfix"></div></div></a>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-md-12">
        <div class="panel panel-info">
            <div class="panel-heading">
                <h3 class="panel-title"><i class="glyphicon glyphicon-hdd"></i> 服务器状态</h3>
            </div>
            <div class="panel-body">
                <ul class="list-group">
                    <li class="list-group-item"><strong>服务器名称:</strong> <%= H(ServerName) %></li>
                    <li class="list-group-item"><strong>Web 服务器:</strong> <%= H(ServerSoftware) %></li>
                    <li class="list-group-item"><strong>.NET Framework 版本:</strong> <%= H(DotNetVersion) %></li>
                    <li class="list-group-item"><strong>应用程序内存占用:</strong> <%= MemoryUsage %> MB</li>
                    <li class="list-group-item"><strong>启动时间:</strong> <%= StartTime.ToString("yyyy-MM-dd HH:mm:ss") %></li>
                    <li class="list-group-item"><strong>已运行时长:</strong> <%= RunningTime.ToString(@"d\天\ hh\:mm\:ss") %></li>
                </ul>
            </div>
        </div>
    </div>
</div>

<style>
    .panel-green { border-color: #5cb85c; }
    .panel-green .panel-heading { border-color: #5cb85c; color: #fff; background-color: #5cb85c; }
    .panel-yellow { border-color: #f0ad4e; }
    .panel-yellow .panel-heading { border-color: #f0ad4e; color: #fff; background-color: #f0ad4e; }
    .panel-red { border-color: #d9534f; }
    .panel-red .panel-heading { border-color: #d9534f; color: #fff; background-color: #d9534f; }
</style>

<!--#include file="_AdminLayoutBottom.inc" -->
