## FRP 内网穿透部署手册



#### frp 是什么?

frp 是一个专注于内网穿透的高性能反向代理应用，支持 TCP、UDP、HTTP、HTTPS 等多种协议。可以将内网服务以安全、便捷的方式通过具有公网 IP 节点的中转暴露到公网。

官方教程: https://gofrp.org/docs



##### 服务端配置:

服务端部署在拥有公网 IP 的服务器上.

```bash
docker pull snowdreamtech/frps

docker run -d --name frps \
--restart=unless-stopped \
-p 8080:8080 \
-p 2046:2046 \
-v /home/config/frp/frps.ini:/etc/frp/frps.ini \
snowdreamtech/frps:latest
```

/home/config/frp/frps.ini 内容:

```ini
[common]
bind_port = 8080
authentication_method = token
token = password # 设置密码
```

服务端的 8080 端口用于给客户端连接 , 2046 端口则是在客户端配置能穿透到内网的端口.



##### 客户端配置

客户端部署在被穿透的机器上.

```bash
docker pull snowdreamtech/frpc

docker run -d --name frpc \
--restart=unless-stopped \
-v /home/config/frp/frpc.ini:/etc/frp/frpc.ini \
snowdreamtech/frpc
```

/home/config/frp/frpc.ini 内容:

```ini
[common]
server_addr = 8.8.8.8 # 这里填写服务器公网 IP
server_port = 8080 # 服务端绑定的给客户端连接的端口
authentication_method = token
token = password # 服务端配置好的密码

[ssh]
type = tcp
local_ip = 192.168.1.200
local_port = 22
remote_port = 2046
```

`[ssh]` 中的字符将作为这个连接的名称 , 有多个客户端的话 , 可以修改这里来进行区分.

