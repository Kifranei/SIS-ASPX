using System;
using System.Web;
using System.Web.Http;
using System.Web.Mvc;
using System.Web.Optimization;
using System.Web.Routing;

namespace StudentInformationSystem
{
    public class MvcApplication : System.Web.HttpApplication
    {
        private static readonly string[] PublicAreaPrefixes = new[]
        {
            "Admin/",
            "Teacher/",
            "Student/",
            "Home/",
            "Account/",
            "Shared/"
        };

        protected void Application_BeginRequest()
        {
            var appRelativePath = Request.AppRelativeCurrentExecutionFilePath ?? string.Empty;
            var query = Request.Url == null ? string.Empty : Request.Url.Query;

            string publicPath;
            if (TryMapLegacyWebFormsPath(appRelativePath, out publicPath))
            {
                Response.Redirect(VirtualPathUtility.ToAbsolute(publicPath) + query, true);
                return;
            }

            string physicalPath;
            if (TryMapPublicWebFormsPath(appRelativePath, out physicalPath))
            {
                var queryString = query.StartsWith("?", StringComparison.Ordinal) ? query.Substring(1) : query;
                Context.RewritePath(physicalPath, string.Empty, queryString, false);
            }
        }

        protected void Application_Start()
        {
            AreaRegistration.RegisterAllAreas();
            GlobalConfiguration.Configure(WebApiConfig.Register);
            FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            BundleConfig.RegisterBundles(BundleTable.Bundles);
        }

        private static bool TryMapPublicWebFormsPath(string appRelativePath, out string physicalWebFormsPath)
        {
            physicalWebFormsPath = null;

            if (appRelativePath.Equals("~/Login.aspx", StringComparison.OrdinalIgnoreCase))
            {
                physicalWebFormsPath = "~/WebForms/Login.aspx";
                return true;
            }

            if (appRelativePath.Equals("~/Logout.aspx", StringComparison.OrdinalIgnoreCase))
            {
                physicalWebFormsPath = "~/WebForms/Logout.aspx";
                return true;
            }

            if (!appRelativePath.EndsWith(".aspx", StringComparison.OrdinalIgnoreCase))
            {
                return false;
            }

            foreach (var prefix in PublicAreaPrefixes)
            {
                if (appRelativePath.StartsWith("~/" + prefix, StringComparison.OrdinalIgnoreCase))
                {
                    physicalWebFormsPath = "~/WebForms" + appRelativePath.Substring(1);
                    return true;
                }
            }

            return false;
        }

        private static bool TryMapLegacyWebFormsPath(string appRelativePath, out string publicPath)
        {
            publicPath = null;

            if (appRelativePath.Equals("~/WebForms/Login.aspx", StringComparison.OrdinalIgnoreCase))
            {
                publicPath = "~/Login.aspx";
                return true;
            }

            if (appRelativePath.Equals("~/WebForms/Logout.aspx", StringComparison.OrdinalIgnoreCase))
            {
                publicPath = "~/Logout.aspx";
                return true;
            }

            const string prefix = "~/WebForms/";
            if (appRelativePath.StartsWith(prefix, StringComparison.OrdinalIgnoreCase) && appRelativePath.EndsWith(".aspx", StringComparison.OrdinalIgnoreCase))
            {
                var suffix = appRelativePath.Substring(prefix.Length);
                foreach (var areaPrefix in PublicAreaPrefixes)
                {
                    if (suffix.StartsWith(areaPrefix, StringComparison.OrdinalIgnoreCase))
                    {
                        publicPath = "~/" + suffix;
                        return true;
                    }
                }
            }

            return false;
        }
    }
}
