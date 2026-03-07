using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace StudentInformationSystem.Controllers
{
    public class BaseController : Controller
    {
        // 这个方法在执行任何Action之前都会先被调用
        protected override void OnActionExecuting(ActionExecutingContext filterContext)
        {
            base.OnActionExecuting(filterContext);

            // 检查Session中是否存有用户信息
            if (Session["User"] == null)
            {
                // 如果没有登录，就统一重定向到 Web Forms 登录页
                filterContext.Result = new RedirectResult("~/WebForms/Login.aspx");
            }
        }
    }
}
