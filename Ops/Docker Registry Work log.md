# 私有 Docker 镜像服务器搭建

## 证书

### 获取对应证书的公钥私钥

> example.com.crt & example.com.key

## 执行

```bash
# mkdir -p /root/DockerRegistry
# mkdir -p /root/DockerRegistry/auth
# mkdir -p /root/DockerRegistry/certs
# mkdir -p /root/DockerRegistry/data

# docker pull registry:latest
# docker run --rm --entrypoint htpasswd registry -Bbn 账号 密码 > /root/DockerRegistry/auth/htpasswd

# vim /etc/hosts

127.0.0.1   repository.example.com

# cd /root/DockerRegistry
# touch docker-compose.yml
# vim docker-compose.yml

version: '3'
  
services:
    registry:
        restart: always
        image: registry:latest
        ports:
            - 5000:5000
        environment:
            REGISTRY_AUTH: htpasswd
            REGISTRY_AUTH_HTPASSWD_PATH: /auth/htpasswd
            REGISTRY_AUTH_HTPASSWD_REALM: Registry Realm
            REGISTRY_HTTP_ADDR: 0.0.0.0:5000
            REGISTRY_HTTP_TLS_CERTIFICATE: /certs/example.com.crt
            REGISTRY_HTTP_TLS_KEY: /certs/example.com.key
        volumes:
            - ./data:/var/lib/registry
            - ./certs:/certs
            - ./auth:/auth
```

## 查看日志

```bash
# docker logs -f registry
```

## Login

```bash
# docker login https://repository.example.com:5000
Username: 填写账号
Password: 填写密码

Login Succeeded
```

## 安全组开放对应端口
