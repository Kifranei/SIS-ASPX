<%@ Page Language="C#" AutoEventWireup="true" CodePage="65001" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Web.Helpers" %>
<%@ Import Namespace="StudentInformationSystem.Models" %>

<script runat="server">
    protected string ErrorMessage = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        var currentUser = Session["User"] as Users;
        if (Request.HttpMethod.Equals("GET", StringComparison.OrdinalIgnoreCase) && currentUser != null)
        {
            Session["UseWebForms"] = true;
            Response.Redirect(GetHomeUrlByRole(currentUser.Role), true);
            return;
        }

        if (!Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        try
        {
            AntiForgery.Validate();
        }
        catch
        {
            ErrorMessage = "\u8BF7\u6C42\u65E0\u6548\uFF0C\u8BF7\u5237\u65B0\u9875\u9762\u540E\u91CD\u8BD5\u3002";
            return;
        }

        var username = (Request.Form["username"] ?? string.Empty).Trim();
        var password = (Request.Form["password"] ?? string.Empty).Trim();

        if (string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password))
        {
            ErrorMessage = "\u8BF7\u8F93\u5165\u7528\u6237\u540D\u548C\u5BC6\u7801\u3002";
            return;
        }

        using (var db = new StudentManagementDBEntities())
        {
            var user = db.Users.FirstOrDefault(u => u.Username == username);
            bool upgraded;
            if (!StudentInformationSystem.Helpers.PasswordSecurity.VerifyAndUpgrade(user, password, out upgraded))
            {
                ErrorMessage = "\u7528\u6237\u540D\u6216\u5BC6\u7801\u9519\u8BEF\u3002";
                return;
            }

            if (upgraded)
            {
                db.Entry(user).State = System.Data.Entity.EntityState.Modified;
                db.SaveChanges();
            }

            Session["User"] = new Users
            {
                UserID = user.UserID,
                Username = user.Username,
                Password = user.Password,
                Role = user.Role
            };
            Session["UseWebForms"] = true;

            Response.Redirect(GetHomeUrlByRole(user.Role), true);
        }
    }

    private string GetHomeUrlByRole(int role)
    {
        if (role == 0) return "~/Admin/Index.aspx";
        if (role == 1) return "~/Teacher/Index.aspx";
        return "~/Student/Index.aspx";
    }
</script>

<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width" />
    <title>&#x6559;&#x5B66;&#x7BA1;&#x7406;&#x4E00;&#x4F53;&#x5316;&#x4FE1;&#x606F;&#x7CFB;&#x7EDF; - &#x767B;&#x5F55;</title>
    <script>
        (function () {
            document.documentElement.classList.remove('dark-mode');
        })();
    </script>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@3.3.7/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link href="<%= ResolveUrl("~/Content/theme-system.css") %>" rel="stylesheet" type="text/css" />
    <style>
        html, body { margin: 0; padding: 0; width: 100%; height: 100%; font-family: "Microsoft YaHei", "PingFang SC", sans-serif; overflow: hidden; }
        .login-wrapper { width: 100%; height: 100%; display: flex; flex-direction: column; background-color: var(--login-bg-color); transition: background-color 0.3s ease; }
        .login-header { height: 15%; padding: 2% 5%; box-sizing: border-box; background-color: var(--header-bg-color); display: flex; justify-content: space-between; align-items: center; transition: background-color 0.3s ease; }
        .login-header-left { display: flex; align-items: center; }
        .login-header img { height: 60%; width: auto; }
        .login-main { height: 85%; background-image: url('https://images.unsplash.com/photo-1580582932707-520aed937b7b?q=80&w=1932&auto=format&fit=crop'); background-position: center; background-size: cover; background-repeat: no-repeat; position: relative; display: flex; align-items: center; justify-content: center; }
        .login-form-box { width: 400px; padding: 40px; background: var(--form-bg-color); backdrop-filter: blur(10px); border-radius: 10px; box-shadow: 0 0 15px rgba(0, 0, 0, 0.2); text-align: center; z-index: 10; transition: background 0.3s ease; }
        .login-form-box h2 { font-size: 28px; color: var(--theme-primary); margin-top: 0; margin-bottom: 35px; }
        .form-input-group { margin-bottom: 25px; }
        .form-input-group input { width: 100%; height: 50px; border: 1px solid var(--border-color); border-radius: 25px; padding: 0 20px; font-size: 16px; box-sizing: border-box; background: var(--input-bg-color); color: var(--text-color-primary); transition: all 0.3s ease; max-width: none; }
        .form-input-group input:focus { outline: none; border-color: var(--theme-primary); }
        .form-input-group input::placeholder { color: var(--text-color-secondary); }
        .login-btn { width: 100%; height: 50px; border: none; border-radius: 25px; background: linear-gradient(to right, var(--theme-primary), var(--theme-primary-dark)); color: #fff; font-size: 20px; cursor: pointer; transition: all 0.3s ease; }
        .login-btn:hover { opacity: 0.9; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2); }
        .error-message { margin-top: 15px; }
        .footer-version { position: absolute; bottom: 20px; left: 50%; transform: translateX(-50%); color: var(--footer-text-color); font-size: 14px; transition: color 0.3s ease; }
        @media screen and (max-width: 768px) { .login-header { height: 12%; padding: 4% 5%; } .login-main { height: 88%; align-items: flex-start; padding-top: 15%; } .login-form-box { width: 90%; padding: 30px; backdrop-filter: blur(5px); } .login-form-box h2 { font-size: 24px; margin-bottom: 25px; } .form-input-group input, .login-btn { height: 45px; } }
    </style>
</head>
<body class="login-page">
    <div class="login-wrapper">
        <header class="login-header">
            <div class="login-header-left">
                <img src="https://jwgl.hrbzy.edu.cn:9081/login/s04/images/logo-1-1e3b8670d915457caeefaa35d0d83828.png" alt="logo" />
            </div>
            <div class="login-header-right"></div>
        </header>
        <main class="login-main">
            <div class="login-form-box">
                <h2>&#x7528;&#x6237;&#x767B;&#x5F55;</h2>
                <form method="post" action="<%= ResolveUrl("~/Login.aspx") %>">
                    <%= AntiForgery.GetHtml() %>
                    <div class="form-input-group"><input type="text" id="username" name="username" placeholder="&#x7528;&#x6237;&#x540D;" required /></div>
                    <div class="form-input-group"><input type="password" id="password" name="password" placeholder="&#x5BC6;&#x7801;" required /></div>
                    <button type="submit" class="login-btn">&#x767B; &#x5F55;</button>
                    <hr class="my-4" />
                    <div class="form-group mt-3">
                        <button type="button" id="btnPasskeyLogin" class="btn btn-outline-success btn-block" style="display:flex;justify-content:center;align-items:center;gap:8px;height:calc(1.5em + .75rem + 2px);">
                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" fill="currentColor" class="bi bi-person-badge" viewBox="0 0 16 16"><path d="M6.5 2a.5.5 0 0 0 0 1h3a.5.5 0 0 0 0-1h-3zM11 8a3 3 0 1 1-6 0 3 3 0 0 1 6 0z" /><path d="M4.5 0A2.5 2.5 0 0 0 2 2.5V14a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V2.5A2.5 2.5 0 0 0 11.5 0h-7zM3 2.5A1.5 1.5 0 0 1 4.5 1h7A1.5 1.5 0 0 1 13 2.5v10.795a4.2 4.2 0 0 0-.776-.492C11.392 12.387 10.063 12 8 12s-3.392.387-4.224.803a4.2 4.2 0 0 0-.776.492V2.5z" /></svg>
                            &#x4F7F;&#x7528;&#x901A;&#x884C;&#x5BC6;&#x94A5;&#xFF08;&#x9762;&#x5BB9;/&#x6307;&#x7EB9;&#xFF09;&#x767B;&#x5F55;
                        </button>
                    </div>
                    <% if (!string.IsNullOrEmpty(ErrorMessage)) { %>
                    <div class="alert alert-danger error-message"><%= ErrorMessage %></div>
                    <% } %>
                </form>
            </div>
            <div class="footer-version">&#x7248;&#x672C;&#x53F7;: V1.0</div>
        </main>
    </div>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script>
        const passkeyGetOptionsUrl = '<%= ResolveUrl("~/Passkey/GetAssertionOptions") %>';
        const passkeyAssertionUrl = '<%= ResolveUrl("~/Passkey/MakeAssertion") %>';
        function base64UrlToBuffer(str) { str = str.replace(/-/g, '+').replace(/_/g, '/'); let pad = str.length % 4; if (pad !== 0) { str += new Array(5 - pad).join('='); } let binary = atob(str); let bytes = new Uint8Array(binary.length); for (let i = 0; i < binary.length; i++) { bytes[i] = binary.charCodeAt(i); } return bytes.buffer; }
        function bufferToBase64Url(buffer) { let bytes = new Uint8Array(buffer); let str = ''; for (let charCode of bytes) { str += String.fromCharCode(charCode); } let base64 = btoa(str); return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, ''); }
        document.addEventListener('DOMContentLoaded', function () {
            const btn = document.getElementById('btnPasskeyLogin');
            if (!btn) { return; }
            btn.addEventListener('click', async function () {
                if (!window.PublicKeyCredential) {
                    alert('\u62B1\u6B49\uFF0C\u5F53\u524D\u6D4F\u89C8\u5668\u6216\u8BBE\u5907\u4E0D\u652F\u6301\u901A\u884C\u5BC6\u94A5\u767B\u5F55\u3002');
                    return;
                }
                try {
                    let resp = await fetch(passkeyGetOptionsUrl, { method: 'POST' });
                    let options = await resp.json();
                    if (options.status === 'error') { alert(options.errorMessage); return; }
                    options.challenge = base64UrlToBuffer(options.challenge);
                    if (options.allowCredentials) {
                        for (let cred of options.allowCredentials) { cred.id = base64UrlToBuffer(cred.id); }
                    }
                    let credential = await navigator.credentials.get({ publicKey: options });
                    let assertionResponse = {
                        id: credential.id,
                        rawId: bufferToBase64Url(credential.rawId),
                        type: credential.type,
                        response: {
                            authenticatorData: bufferToBase64Url(credential.response.authenticatorData),
                            clientDataJSON: bufferToBase64Url(credential.response.clientDataJSON),
                            signature: bufferToBase64Url(credential.response.signature),
                            userHandle: credential.response.userHandle ? bufferToBase64Url(credential.response.userHandle) : null
                        }
                    };
                    let verifyResp = await fetch(passkeyAssertionUrl, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(assertionResponse) });
                    let verifyResult = await verifyResp.json();
                    if (verifyResult.status === 'ok') {
                        window.location.href = verifyResult.redirectUrl;
                    } else {
                        alert('\u767B\u5F55\u5931\u8D25: ' + verifyResult.errorMessage);
                    }
                } catch (err) {
                    console.error('Passkey login error:', err);
                }
            });
        });
    </script>
</body>
</html>
