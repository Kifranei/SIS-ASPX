<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Data.Entity" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>
<%@ Import Namespace="StudentInformationSystem.Helpers" %>

<script runat="server">
    protected string PageTitle = "\u7BA1\u7406\u5458";
    protected string CurrentUsername = "\u7BA1\u7406\u5458";

    protected bool EnsureAdminRole()
    {
        var currentUser = Session["User"] as Users;
        if (currentUser == null || currentUser.Role != 0)
        {
            Response.Redirect("~/Login.aspx", true);
            return false;
        }

        CurrentUsername = currentUser.Username ?? "\u7BA1\u7406\u5458";
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
        if (value == "\u7537" || value.Equals("male", StringComparison.OrdinalIgnoreCase))
        {
            return "\u7537";
        }

        if (value == "\u5973" || value.Equals("female", StringComparison.OrdinalIgnoreCase))
        {
            return "\u5973";
        }

        return string.Empty;
    }

    protected bool IsValidGender(string gender)
    {
        var normalized = NormalizeGender(gender);
        return normalized == "\u7537" || normalized == "\u5973";
    }

    protected string CourseTypeText(int courseType)
    {
        switch (courseType)
        {
            case 1: return "\u4E13\u4E1A\u5FC5\u4FEE";
            case 2: return "\u516C\u5171\u5FC5\u4FEE";
            case 3: return "\u4E13\u4E1A\u9009\u4FEE";
            case 4: return "\u516C\u5171\u9009\u4FEE";
            case 5: return "\u4F53\u80B2\u9009\u4FEE";
            default: return "\u672A\u77E5\u7C7B\u578B";
        }
    }

    protected string DayName(int dayOfWeek)
    {
        var days = new[]
        {
            string.Empty,
            "\u5468\u4E00",
            "\u5468\u4E8C",
            "\u5468\u4E09",
            "\u5468\u56DB",
            "\u5468\u4E94",
            "\u5468\u516D",
            "\u5468\u65E5"
        };

        return dayOfWeek >= 1 && dayOfWeek <= 7 ? days[dayOfWeek] : "\u672A\u77E5";
    }

    protected string GetPeriodTime(int period)
    {
        var periodTimes = new[]
        {
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
