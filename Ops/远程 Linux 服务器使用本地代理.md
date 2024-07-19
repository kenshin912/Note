# 远程 Linux 服务器使用本地代理

## 终端配置

在终端的 `端口转发` 配置中 , 添加如下配置

|  Local   | Remote  |
| :----: | :----: |
| 127.0.0.1:7890  | localhost:7890 |

## 服务器端配置

执行以下命令:

```bash
export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890 no_proxy=localhost,127.0.0.0/8,*.local
```

## 本机配置

打开 Clash 等软件 , 允许局域网访问 , 并将端口设置为 7890 .

## 验证

```bash
[root@test ~]# curl -I https://www.google.com
HTTP/1.1 200 Connection established

HTTP/1.1 200 OK
Content-Type: text/html; charset=ISO-8859-1
Content-Security-Policy-Report-Only: object-src 'none';base-uri 'self';script-src 'nonce-y_WxWb1-33Zc73_6mTYMQQ' 'strict-dynamic' 'report-sample' 'unsafe-eval' 'unsafe-inline' https: http:;report-uri https://csp.withgoogle.com/csp/gws/other-hp
P3P: CP="This is not a P3P policy! See g.co/p3phelp for more info."
Date: Mon, 15 Jul 2024 05:31:40 GMT
Server: gws
X-XSS-Protection: 0
X-Frame-Options: SAMEORIGIN
Transfer-Encoding: chunked
Expires: Mon, 15 Jul 2024 05:31:40 GMT
Cache-Control: private
Set-Cookie: AEC=AVYB7cp8YO0b3sbuygyXPUBj29C57wB1m8azX-NccdNhOusMlhBD6U_s_A; expires=Sat, 11-Jan-2025 05:31:40 GMT; path=/; domain=.google.com; Secure; HttpOnly; SameSite=lax
Set-Cookie: NID=515=JEVaDP5O49YpgtMLVrYcLumDwfO3ENCsEe55Ng3d1pCs7_AucX9D-Y7LjP3-jJiRxwmkx3z3XCgNmpZdMtwuRKl8_uhJT5PUYVTobEIE0U2vvoriGNKfJN_s5IqUakbrg7TQek0bNMgtDWAlgUO4IUOGhHDdmoxaKJGmXGn498s; expires=Tue, 14-Jan-2025 05:31:40 GMT; path=/; domain=.google.com; HttpOnly
Alt-Svc: h3=":443"; ma=2592000,h3-29=":443"; ma=2592000
```