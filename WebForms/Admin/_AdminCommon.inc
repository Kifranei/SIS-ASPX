<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>
<%@ Import Namespace="StudentInformationSystem.Helpers" %>

<script runat="server">
    protected string PageTitle = "管理员";
    protected string CurrentUsername = "管理员";

    protected bool EnsureAdminRole()
    {
        var currentUser = Session["User"] as Users;
        if (currentUser == null || currentUser.Role != 0)
        {
            Response.Redirect("~/Login.aspx", true);
            return false;
        }

        CurrentUsername = currentUser.Username ?? "管理员";
        return true;
    }

    protected string MenuActive(string pages)
    {
        var current = VirtualPathUtility.GetFileName(Request.AppRelativeCurrentExecutionFilePath) ?? string.Empty;
        if (string.IsNullOrWhiteSpace(pages))
        {
            return string.Empty;
        }

        foreach (var page in pages.Split('|'))
        {
            if (current.Equals(page, StringComparison.OrdinalIgnoreCase))
            {
                return "active";
            }
        }

        return string.Empty;
    }

    protected string H(string value)
    {
        return Server.HtmlEncode(value ?? string.Empty);
    }

    protected string NormalizeGender(string gender)
    {
        var value = (gender ?? string.Empty).Trim();
        if (value == "男" || value.Equals("male", StringComparison.OrdinalIgnoreCase))
        {
            return "男";
        }

        if (value == "女" || value.Equals("female", StringComparison.OrdinalIgnoreCase))
        {
            return "女";
        }

        return string.Empty;
    }

    protected bool IsValidGender(string gender)
    {
        var normalized = NormalizeGender(gender);
        return normalized == "男" || normalized == "女";
    }

    protected string CourseTypeText(int courseType)
    {
        switch (courseType)
        {
            case 1: return "专业必修";
            case 2: return "公共必修";
            case 3: return "专业选修";
            case 4: return "公共选修";
            case 5: return "体育选修";
            default: return "未知类型";
        }
    }

    protected string DayName(int dayOfWeek)
    {
        var days = new[] { "", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日" };
        return dayOfWeek >= 1 && dayOfWeek <= 7 ? days[dayOfWeek] : "未知";
    }

    protected string GetPeriodTime(int period)
    {
        var periodTimes = new[] {
            "08:40-09:25", "09:30-10:15", "10:35-11:20", "11:25-12:10",
            "13:20-14:05", "14:10-14:55", "15:15-16:00", "16:05-16:50",
            "17:30-18:15", "18:20-19:05", "19:10-19:55", "20:00-20:45"
        };

        return period >= 1 && period <= 12 ? periodTimes[period - 1] : string.Empty;
    }

    protected string BuildQueryString(params KeyValuePair<string, string>[] items)
    {
        if (items == null || items.Length == 0)
        {
            return string.Empty;
        }

        var parts = new List<string>();
        foreach (var item in items)
        {
            if (!string.IsNullOrWhiteSpace(item.Key) && item.Value != null)
            {
                parts.Add(Server.UrlEncode(item.Key) + "=" + Server.UrlEncode(item.Value));
            }
        }

        return parts.Count == 0 ? string.Empty : "?" + string.Join("&", parts);
    }
</script>

