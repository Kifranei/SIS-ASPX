using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using StudentInformationSystem.Models;


namespace StudentInformationSystem.Controllers
{
    public class AccountController : Controller
    {
        // 实例化数据库上下文，用于操作数据库
        private StudentManagementDBEntities db = new StudentManagementDBEntities();

        // 1. GET请求: 显示登录页面
        // 当用户直接访问 /Account/Login 时，执行此方法
        public ActionResult Login()
        {
            // 统一走 Web Forms 登录页，避免回到旧 cshtml 登录页
            return Redirect("~/Login.aspx");
        }

        // 2. POST请求: 处理用户提交的登录表单
        // 当用户在登录页面点击“登录”按钮时，执行此方法
        [HttpPost]
        public ActionResult Login(string username, string password)
        {
            // 使用LINQ在Users表中查找匹配的用户名和密码
            var user = db.Users.FirstOrDefault(u => u.Username == username && u.Password == password);

            // 如果找到了用户
            if (user != null)
            {
                // 使用Session来记录用户的登录状态
                Session["User"] = user;

                // 根据角色判断跳转到哪里
                if (user.Role == 0) // 管理员
                {
                    return RedirectToAction("Index", "Admin");
                }
                else if (user.Role == 1) // 教师
                {
                    // 跳转到教师控制器的主页
                    return RedirectToAction("Index", "Teacher");
                }
                else // 学生
                {
                    // 跳转到学生控制器的主页
                    return RedirectToAction("Index", "Student");
                }
            }
            else // 如果没找到用户
            {
                // 兼容旧 POST 入口：失败后也回到 Web Forms 登录页
                return Redirect("~/Login.aspx");
            }
        }

        // 3. 注销功能
        public ActionResult Logout()
        {
            // 清空Session，实现用户退出
            Session.Clear();
            // 统一走 Web Forms 退出页，确保最终回到 Web Forms 登录页
            return Redirect("~/Logout.aspx");
        }
    }
}

