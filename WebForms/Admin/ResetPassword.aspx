<%@ Page Language="C#" AutoEventWireup="true" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "重置密码";
        if (!EnsureAdminRole())
        {
            return;
        }

        int userId;
        if (!int.TryParse(Request.Form["userId"] ?? Request.QueryString["userId"], out userId) || userId <= 0)
        {
            Response.Redirect("StudentList.aspx", true);
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            var userToReset = db.Users.Find(userId);
            if (userToReset != null)
            {
                userToReset.Password = "Hzd@123456";
                db.Entry(userToReset).State = EntityState.Modified;
                db.SaveChanges();
                Session["AdminFlashMessage"] = "用户 " + (userToReset.Username ?? "") + " 的密码已成功重置为 \"Hzd@123456\"。";

                var target = userToReset.Role == 2 ? "StudentList.aspx" : "TeacherList.aspx";
                Response.Redirect(target, true);
                return;
            }
        }

        Response.Redirect("StudentList.aspx", true);
    }
</script>
