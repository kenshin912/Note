# 自建 Docker Registry 反向代理 Docker Hub

## 部署 Docker Registry

在境外 VPS 部署 Docker Registry , 以我手中的这台 Debian 12 为例.

创建 `/home/registry` 目录 , 然后在这个目录下 , 创建 `docker-compose.yml` 和 `config.yml`

docker-compose.yml

```yaml
services:
    registry:
        image: registry:2.8.3
        container_name: registry
        ports:
            - "5000:5000"
        volumes:
            - "/etc/localtime:/etc/localtime"
            - "/home/data/registry:/var/lib/registry"
            - "./config.yml:/etc/docker/registry/config.yml"
        logging:
            driver: "json-file"
            options:
                max-size: "64m"
                max-file: "1"
        restart: unless-stopped
        networks:
            - net

networks:
    net:
        driver: bridge
```

config.yml

```yaml
version: 0.1
log:
    level: info
    formatter: json
storage:
    filesystem:
        rootdirectory: /var/lib/registry
    delete:
        enabled: true
    cache:
        blobdescriptor: inmemory
    maintenance:
        uploadpurging:
            enabled: true
            age: 168h
            dryrun: false
            interval: 1h
        readonly:
            enabled: false
http:
    addr: 0.0.0.0:5000
health:
    storagedriver:
        enabled: true
        interval: 60s
proxy:
    remoteurl: https://registry-1.docker.io
```

执行 `docker compose up -d` , 即可部署好服务.

## 部署反向代理

在 Nginx 的虚拟主机配置中 , 添加一个虚拟主机配置 , 如下:

```nginx
server {
    listen 443 ssl;
    http2 on;
    server_name docker.test.com;
    client_max_body_size 1024M;

    include /etc/nginx/ssl/test.com.conf;

    ssl_session_timeout 24h;

    location / {
        proxy_pass http://172.16.1.100:5000; # registry 的地址
    }
}
```

## 使用

```bash
docker pull docker.test.com/library/nginx:latest
```