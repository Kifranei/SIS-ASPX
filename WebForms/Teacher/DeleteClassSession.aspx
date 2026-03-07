<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected string SourceView = "Views/Teacher/DeleteClassSession.cshtml";
    protected void EnsureRole()
    {
        var currentUser = Session["User"] as Users;
        if (currentUser == null || currentUser.Role != 1)
        {
            Response.Redirect("~/WebForms/Login.aspx", true);
            return;
        }
    }
    protected void Page_Load(object sender, EventArgs e)
    {
        EnsureRole();
        if (TryRedirectToMvc())
        {
            return;
        }
    }

    protected bool TryRedirectToMvc()
    {
        var normalized = (SourceView ?? string.Empty).Replace('\\', '/');
        var parts = normalized.Split('/');
        if (parts.Length < 3)
        {
            return false;
        }

        var controller = parts[1];
        var viewFile = parts[2];
        var action = Path.GetFileNameWithoutExtension(viewFile);

        if (string.IsNullOrWhiteSpace(controller) || string.IsNullOrWhiteSpace(action))
        {
            return false;
        }

        if (controller.Equals("Shared", StringComparison.OrdinalIgnoreCase) || action.StartsWith("_", StringComparison.Ordinal))
        {
            return false;
        }

        string target;
        if (controller.Equals("Account", StringComparison.OrdinalIgnoreCase) && action.Equals("Login", StringComparison.OrdinalIgnoreCase))
        {
            target = "~/WebForms/Login.aspx";
        }
        else
        {
            target = "~/" + controller + "/" + action;
        }

        var qs = Request?.Url?.Query;
        if (!string.IsNullOrEmpty(qs))
        {
            target += qs;
        }

        Response.Redirect(target, true);
        return true;
    }
</script>

<!DOCTYPE html>
<html lang="zh-CN">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Teacher/DeleteClassSession</title>
    <link href="<%= ResolveUrl("~/Content/bootstrap.min.css") %>" rel="stylesheet" />
</head>
<body class="bg-light">
    <div class="container py-4">
        <div class="alert alert-info">
            正在跳转到原页面：<code><%= SourceView %></code>
        </div>
    </div>
</body>
</html>

