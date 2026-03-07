<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        var currentUser = Session["User"] as Users;
        if (currentUser == null || currentUser.Role != 0)
        {
            Response.Redirect("~/WebForms/Login.aspx", true);
            return;
        }

        var target = "~/Admin/Index";
        var qs = Request?.Url?.Query;
        if (!string.IsNullOrEmpty(qs)) target += qs;
        Response.Redirect(target, true);
    }
</script>
