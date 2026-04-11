<%@ Page Language="C#" AutoEventWireup="true" CodePage="65001" %>
<!--#include file="_AdminCommon.inc" -->

<script runat="server">
    protected string MessageType = string.Empty;
    protected string MessageText = string.Empty;

    protected void Page_Load(object sender, EventArgs e)
    {
        PageTitle = "修改密码";
        if (!EnsureAdminRole()) return;
        if (!Request.HttpMethod.Equals("POST", StringComparison.OrdinalIgnoreCase)) return;

        var oldPassword = (Request.Form["OldPassword"] ?? string.Empty).Trim();
        var newPassword = (Request.Form["NewPassword"] ?? string.Empty).Trim();
        var confirmPassword = (Request.Form["ConfirmPassword"] ?? string.Empty).Trim();

        if (string.IsNullOrEmpty(oldPassword) || string.IsNullOrEmpty(newPassword) || string.IsNullOrEmpty(confirmPassword)) { MessageType = "danger"; MessageText = "\u8BF7\u5B8C\u6574\u586B\u5199\u65E7\u5BC6\u7801\u3001\u65B0\u5BC6\u7801\u548C\u786E\u8BA4\u5BC6\u7801\u3002"; return; }
        if (newPassword.Length < 6) { MessageType = "danger"; MessageText = "\u65B0\u5BC6\u7801\u957F\u5EA6\u81F3\u5C11 6 \u4F4D\u3002"; return; }
        if (!newPassword.Equals(confirmPassword, StringComparison.Ordinal)) { MessageType = "danger"; MessageText = "\u65B0\u5BC6\u7801\u548C\u786E\u8BA4\u5BC6\u7801\u4E0D\u5339\u914D\u3002"; return; }

        var currentUser = Session["User"] as Users;
        using (var db = new StudentManagementDBEntities())
        {
            var userInDb = db.Users.Find(currentUser.UserID);
            if (userInDb == null) { MessageType = "danger"; MessageText = "\u7528\u6237\u4E0D\u5B58\u5728\uFF0C\u8BF7\u91CD\u65B0\u767B\u5F55\u3002"; return; }
            if (!StudentInformationSystem.Helpers.PasswordSecurity.VerifyPassword(oldPassword, userInDb.Password)) { MessageType = "danger"; MessageText = "\u65E7\u5BC6\u7801\u4E0D\u6B63\u786E\uFF0C\u8BF7\u91CD\u65B0\u8F93\u5165\u3002"; return; }

            userInDb.Password = StudentInformationSystem.Helpers.PasswordSecurity.HashPassword(newPassword);
            db.Entry(userInDb).State = EntityState.Modified;
            db.SaveChanges();
            if (currentUser != null) currentUser.Password = userInDb.Password;
            MessageType = "success"; MessageText = "\u5BC6\u7801\u4FEE\u6539\u6210\u529F\u3002";
        }
    }
</script>

<!--#include file="_AdminLayoutTop.inc" -->
<h2>修改密码</h2>
<hr />
<% if (!string.IsNullOrEmpty(MessageText)) { %><div class="alert alert-<%= MessageType %>"><%= H(MessageText) %></div><% } %>
<form method="post" class="row g-3" style="max-width:680px;">
    <div class="col-12"><label class="form-label" for="OldPassword">旧密码</label><input class="form-control" type="password" id="OldPassword" name="OldPassword" required /></div>
    <div class="col-12"><label class="form-label" for="NewPassword">新密码</label><input class="form-control" type="password" id="NewPassword" name="NewPassword" required minlength="6" /></div>
    <div class="col-12"><label class="form-label" for="ConfirmPassword">确认新密码</label><input class="form-control" type="password" id="ConfirmPassword" name="ConfirmPassword" required minlength="6" /></div>
    <div class="col-12 d-flex gap-2"><button class="btn btn-success" type="submit">确认修改</button> <a class="btn btn-outline-secondary" href="Index.aspx">返回控制台</a></div>
</form>
<hr class="my-4" />
<div class="card mt-4">
    <div class="card-header bg-light d-flex justify-content-between align-items-center"><h4 class="mb-0">通行密钥（Passkey）管理</h4><button type="button" id="btnRegisterPasskey" class="btn btn-success btn-sm">添加新设备</button></div>
    <div class="card-body">
        <p class="text-muted small">添加通行密钥后，可使用设备指纹、面容或 PIN 直接登录。</p>
        <table class="table table-bordered table-hover"><thead class="table-light"><tr><th>设备名称</th><th>绑定时间</th><th style="width: 100px;">操作</th></tr></thead><tbody id="passkeyTableBody"><tr><td colspan="3" class="text-center text-muted">正在加载...</td></tr></tbody></table>
    </div>
</div>
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<script>
    function base64UrlToBuffer(str) { str = str.replace(/-/g, '+').replace(/_/g, '/'); let pad = str.length % 4; if (pad !== 0) { str += new Array(5 - pad).join('='); } let binary = atob(str); let bytes = new Uint8Array(binary.length); for (let i = 0; i < binary.length; i++) { bytes[i] = binary.charCodeAt(i); } return bytes.buffer; }
    function bufferToBase64Url(buffer) { let bytes = new Uint8Array(buffer); let str = ''; for (let charCode of bytes) { str += String.fromCharCode(charCode); } let base64 = btoa(str); return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, ''); }
    function loadPasskeys() { $.get('/Passkey/GetUserPasskeys', function (res) { if (res.status === 'ok') { let html = ''; res.data.forEach(p => { html += `<tr><td><strong>${p.Name}</strong></td><td>${p.RegDate}</td><td><button class="btn btn-sm btn-outline-danger" onclick="deletePasskey(${p.Id})">删除</button></td></tr>`; }); if (html === '') html = '<tr><td colspan="3" class="text-center text-muted">您还未绑定任何通行密钥。</td></tr>'; $('#passkeyTableBody').html(html); } }); }
    window.deletePasskey = function (id) { if (confirm('确定要删除这个通行密钥吗？删除后将无法使用该设备登录。')) { $.post('/Passkey/DeletePasskey', { id: id }, function (res) { if (res.status === 'ok') { loadPasskeys(); } else { alert(res.errorMessage || '删除失败'); } }); } }
    $('#btnRegisterPasskey').click(async function () { if (!window.PublicKeyCredential) { alert('您的浏览器或设备不支持通行密钥。'); return; } let passkeyName = prompt('请为该通行密钥命名（例如：我的 iPhone、办公电脑）：', '我的设备'); if (!passkeyName) return; try { let options = await $.post('/Passkey/MakeCredentialOptions'); if (options.status === 'error') { alert(options.errorMessage); return; } options.challenge = base64UrlToBuffer(options.challenge); options.user.id = base64UrlToBuffer(options.user.id); if (options.excludeCredentials) { for (let cred of options.excludeCredentials) { cred.id = base64UrlToBuffer(cred.id); } } let credential = await navigator.credentials.create({ publicKey: options }); let attestationResponse = { id: credential.id, rawId: bufferToBase64Url(credential.rawId), type: credential.type, response: { attestationObject: bufferToBase64Url(credential.response.attestationObject), clientDataJSON: bufferToBase64Url(credential.response.clientDataJSON) } }; let verifyResp = await $.ajax({ url: '/Passkey/MakeCredential?name=' + encodeURIComponent(passkeyName), type: 'POST', contentType: 'application/json', data: JSON.stringify(attestationResponse) }); if (verifyResp.status === 'ok') { alert('通行密钥添加成功。'); loadPasskeys(); } else { alert(verifyResp.errorMessage || '添加失败'); } } catch (err) { console.error('Passkey 注册异常:', err); alert('添加通行密钥时发生错误，请稍后重试。'); } });
    $(function () { loadPasskeys(); });
</script>
<!--#include file="_AdminLayoutBottom.inc" -->
