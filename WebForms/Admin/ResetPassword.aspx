<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "÷ÿ÷√√‹¬Î";
        if (!EnsureAdminRole())
        {
            return;
        }

        if (!Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
        {
            Response.Redirect("StudentList.aspx", true);
            return;
        }

        int userId;
        if (!int.TryParse(Request.Form["userId"], out userId) || userId <= 0)
        {
            Response.Redirect("StudentList.aspx", true);
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            var userToReset = db.Users.Find(userId);
            if (userToReset != null)
            {
                userToReset.Password = StudentInformationSystem.Helpers.PasswordSecurity.HashPassword("Hzd@123456");
                db.Entry(userToReset).State = EntityState.Modified;
                db.SaveChanges();
                Session["AdminFlashMessage"] = "\u7528\u6237 " + (userToReset.Username ?? "") + " \u7684\u5BC6\u7801\u5DF2\u6210\u529F\u91CD\u7F6E\u4E3A \"Hzd@123456\"\u3002";

                var target = userToReset.Role == 2 ? "StudentList.aspx" : "TeacherList.aspx";
                Response.Redirect(target, true);
                return;
            }
        }

        Response.Redirect("StudentList.aspx", true);
    }
</script>
