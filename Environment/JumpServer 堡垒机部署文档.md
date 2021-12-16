### JumpServer 堡垒机部署文档

JumpServer 部署基于 docker-compose , 采用 OpenResty 作为反向代理并配置 SSL 证书.

Docker image 来源: https://github.com/jumpserver/Dockerfile/tree/master/allinone

反向代理部署参考: https://docs.jumpserver.org/zh/master/admin-guide/proxy/



> ⚠️ 注意事项
>
> Safari 15.1 on Mac OS 12.0.1 (Monterey) 在开启系统代理后 , Safari 会提示 "Connect WebSocket closed"  , 查看 develop 工具提示 "kNWErrorDomainPOSIX error 57 - Socket is not connected" . 关闭代理后则正常.
>
> 这是因为 Mac OS Monterey 的 Safari 开启了 **NSURLSession WebSocket** 这个实验特性 , 会导致 WebSocket 在 HTTPS 代理下无法工作.
>
> 解决方法: Safari -> Develop -> Experimental Features -> NSURLSession WebSocket 取消勾选.
>
> Chrome / Edge 无此问题.



#### Requirements

> MySQL version >= 5.7
>
> Redis version >= 6.0
>
> docker version : 19.03+ (20.10.3 Currently)
>
> docker-compose version : 1.27+ (1.29.2 Currently)



#### docker-compose.yml

```yaml
version: '3.9'

services:
		openresty: # 使用 OpenResty 作为反向代理
        image: openresty/openresty:latest
        container_name: openresty
        ports:
            - "80:80"
            - "443:443"
            - "2222:2222" # JumpServer 使用
        volumes:
            - /home/wwwroot:/home/wwwroot
            - /home/config/openresty/nginx.conf:/usr/local/openresty/nginx/conf/nginx.conf:ro
            - /home/config/openresty/vhosts:/etc/nginx/conf.d/:rw
            - /home/config/openresty/ssl:/etc/nginx/ssl:rw
        restart: always
        logging:
            driver: "json-file"
            options:
                max-size: "128m"
        networks:
            - net
            
		jumpserver:
        image: jumpserver/jms_all:v2.16.3
        container_name: jumpserver
        volumes:
            - /home/jumpserver/core:/opt/jumpserver/data
            - /home/jumpserver/koko:/opt/koko/data
            - /home/jumpserver/lion:/opt/lion/data
        expose: # 和 OpenResty 在同一 compose 下不必再占用宿主机端口
            - "80"
            - "2222"
        environment:
            SECRET_KEY: SpringWind10milesYangZhouROAD #随机字符,不可包含特殊字符
            BOOTSTRAP_TOKEN: MissingMonkeyKingTodayCauseMonsterReturnAgain #随机字符,不可包含特殊字符
            LOG_LEVEL: ERROR
            DB_HOST: 172.16.7.13 #数据库地址
            DB_PORT: 3306
            DB_USER: jumpserver
            DB_PASSWORD: ppnn13%dkstFeb.1st
            DB_NAME: jumpserver
            REDIS_HOST: 172.16.7.13 # Redis 地址
            REDIS_PORT: 6379
            REDIS_PASSWORD: ppnn13%dkstFeb.1st
        privileged: true
        restart: always
        logging:
            driver: "json-file"
            options:
                max-size: "64m"
        networks:
            - net
```



#### 创建 MySQL 数据库

```mysql
create database jumpserver default charset 'utf8';
create user 'jumpserver'@'%' identified by 'ppnn13%dkstFeb.1st';
grant all on jumpserver.* to 'jumpserver'@'%';
flush privileges;
```



#### 创建 OpenResty 反向代理

```nginx
server {
    listen 80;
    server_name jump.qferp.net;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name jump.qferp.net;

    ssl_certificate     /etc/nginx/ssl/qferp.net.pem; # SSL 证书
    ssl_certificate_key /etc/nginx/ssl/qferp.net.key;

    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;
    ssl_session_tickets off;
    ssl_protocols TLSv1.2 TLSv1.3;

    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    add_header Strict-Transport-Security "max-age=63072000" always; # HSTS
    client_max_body_size 5000m;  # 上传文件大小限制

    location /ws/ {
        proxy_pass http://jumpserver:8070;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location / {
        proxy_pass http://jumpserver;
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $http_connection;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_ignore_client_abort on;
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        send_timeout 6000;
    }
}
```



#### 修改 OpenResty 配置文件(nginx.conf)

```nginx
stream { # 添加该部分
    server {
        listen 2222;
        proxy_pass jumpserver:2222;
    }
}

http {
  include mime.types;
  default_type application/octet-stream;
  server_names_hash_bucket_size 128;
  client_header_buffer_size 32k;
  large_client_header_buffers 4 32k;
  client_max_body_size 1024m;
  client_body_buffer_size 10m;
  sendfile on;
  tcp_nopush on;
  keepalive_timeout 65;
  server_tokens off;
  tcp_nodelay on;

  set_real_ip_from 0.0.0.0/0;
  real_ip_header  X-Forwarded-For;
  real_ip_recursive on;

  map $http_upgrade $connection_upgrade { # 添加该部分
      default upgrade;
      '' close;
  }
```



#### 升级 JumpServer

```
# 查询定义的 JumpServer 配置
docker exec -it jumpserver env

# 停止 JumpServer
docker stop jumpserver

# 备份数据库
# 例:docker exec mysql mysqldump -uroot -proot jumpserver > /home/jumpserver.sql

# 拉取新版本镜像
docker pull jumpserver/jms_all:v2.xx.x

# 删掉旧版本容器
docker rm jumpserver

# 修改 docker-compose.yml 里面镜像版本信息

# 启动新版本容器
docker-compose up -d
```

