# Build images for Docker Swarm Cluster

## Docker Registry

### Establish directory of Docker Registry

```bash
mkdir -p /root/DockerRegistry

cd /root/DockerRegistry

mkdir -p auth certs data

touch docker-compose.yml
```

### Create Auth password

```bash
docker pull registry:latest

docker run --rm --entrypoint htpasswd registry -Bbn ubilin ppnn13%dkstFeb.1st > /root/DockerRegistry/auth/htpasswd
```

### Move cert files to /root/DockerRegistry/certs

```bash
mv fullchain.pem /root/DockerRegistry/certs
mv example.com.key /root/DockerRegistry/certs
```

### Edit docker-compose.yml

```yaml
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
            REGISTRY_HTTP_TLS_CERTIFICATE: /certs/fullchain.pem
            REGISTRY_HTTP_TLS_KEY: /certs/example.com.key
        volumes:
            - ./data:/var/lib/registry
            - ./certs:/certs
            - ./auth:/auth
```

### RUN

```bash
docker-compose up -d
```

## Build images & Push images to Docker Registry

### Edit hosts

* Append on /etc/hosts

```bash
xx.xx.xx.xx repository.example.com
```

### Build Nginx & PHP images

#### Compose file tree

* docker-compose File Structure

```Markdown
├── ./clear.sh
├── ./docker-compose.yml
├── ./Dockerfile.nginx
├── ./Dockerfile.php
├── ./.env
└── ./extensions
    ├── ./extensions/amqp-1.9.4.tgz
    ├── ./extensions/apcu-5.1.17.tgz
    ├── ./extensions/event-2.5.3.tgz
    ├── ./extensions/imagick-3.4.4.tgz
    ├── ./extensions/install.sh
    ├── ./extensions/mongodb-1.5.5.tgz
    ├── ./extensions/redis-5.0.2.tgz
    ├── ./extensions/swoole-2.0.11.tgz
    ├── ./extensions/swoole-4.4.16.tgz
    ├── ./extensions/swoole-4.4.2.tgz
    ├── ./extensions/xdebug-2.5.5.tgz
    ├── ./extensions/xdebug-2.6.1.tgz
    ├── ./extensions/xhprof-2.1.0.tgz
    └── ./extensions/yaf-2.3.5.tgz
```

* clear.sh

```bash
#!/bin/bash

docker stop nginx php
docker rm nginx php
docker rmi nginx:v1 php:v1
```

* docker-compose.yml

```yaml
version: '3'
services:
    nginx:
        image: "nginx:v1"
        container_name: nginx
        build:
            context: .
            dockerfile: ./Dockerfile.nginx
        ports:
            - "80:80"
            - "443:443"
        volumes:
            - ${SOURCE_DIR}:/home/wwwroot/:rw
            - ${NGINX_SSL_DIR}:/etc/nginx/ssl:rw
            - ${NGINX_CONF_DIR}:/etc/nginx/conf.d/:rw
            - ${NGINX_CONF_FILE}:/etc/nginx/nginx.conf:ro
            - ${NGINX_LOG_DIR}:/home/wwwlogs/nginx/:rw
        restart: always
        networks:
            - frontend
        depends_on:
            - php
    php:
        image: "php:v1"
        container_name: php
        build:
            context: .
            dockerfile: ./Dockerfile.php
            args:
                PHP_VERSION: php:${PHP_VERSION}-fpm-alpine
                PHP_EXTENSIONS: ${PHP_EXTENSIONS}
                TZ: "$TZ"
                CONTAINER_PACKAGE_URL: ${CONTAINER_PACKAGE_URL}
        volumes:
            - ${SOURCE_DIR}:/home/wwwroot/:rw
            - ${PHP_CONF_FILE}:/etc/php7/php.ini:ro
            - ${PHP_FPM_CONF_FILE}:/etc/php7/php-fpm.conf:rw
            - ${PHP_LOG_DIR}:/var/log/php
            - ${DATA_DIR}/composer:/tmp/composer
        networks:
            - frontend
            - backend
#        environment:
#        MYSQL_PASSWORD: MySQL_PWD
#        depends_on:
#            - mysql
#    mysql:
#        image: mysql:5.7
#        container_name: mysql
#        volumes:
#            - mysql-data:/var/lib/mysql
#        environment:
#            TZ: 'Asia/Shanghai'
#            MYSQL_ROOT_PASSWORD: MySQL_PWD
#            command: ['mysqld', '--character-set-server=utf8']
#        networks:
#            - backend
#        volumes:
#            mysql-data:
#
networks:
    frontend:
    backend:
```

* .env

```bash
TZ=Asia/Shanghai
CONTAINER_PACKAGE_URL=mirrors.aliyun.com

SOURCE_DIR=/home/wwwroot/
DATA_DIR=/home/data

NGINX_CONF_DIR=/home/config/nginx/vhosts
NGINX_CONF_FILE=/home/config/nginx/nginx.conf
NGINX_SSL_DIR=/home/config/nginx/ssl
NGINX_LOG_DIR=/home/wwwlogs/nginx

PHP_VERSION=7.3
PHP_CONF_FILE=/home/config/php/php.ini
PHP_FPM_CONF_FILE=/home/config/php/php-fpm.conf
PHP_LOG_DIR=/home/wwwlogs/php
PHP_EXTENSIONS=pdo_mysql,mysqli,mbstring,gd,curl,swoole,redis,openssl,zip,imagick,bcmath,sockets,simplexml
```

* Dockerfile.nginx

```dockerfile
FROM nginx:latest
ENV TZ=Asia/Shanghai
RUN mkdir -p /etc/nginx/ssl /home/wwwroot
```

* Dockerfile.php

```dockerfile
FROM php:7.3.11-fpm-alpine

ARG TZ
ARG PHP_EXTENSIONS

RUN sed -i "s/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g" /etc/apk/repositories && apk --no-cache add tzdata shadow supervisor && cp "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone && apk del tzdata

COPY ./extensions /tmp/extensions

WORKDIR /tmp/extensions

RUN chmod +x install.sh && sh install.sh && rm -rf /tmp/extensions/*

RUN apk add gnu-libiconv --no-cache --repository http://mirrors.aliyun.com/alpine/edge/community/ --allow-untrusted && curl -o /usr/bin/composer https://mirrors.aliyun.com/composer/composer.phar && chmod +x /usr/bin/composer && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ && usermod -u 1000 www-data && groupmod -g 1000 www-data && rm -rf /var/cache/apk/*

ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

ENV COMPOSER_HOME=/tmp/composer

ENTRYPOINT ["docker-php-entrypoint"]
CMD ["php-fpm","-R"]

WORKDIR /home/wwwroot

EXPOSE 9000
```

#### Site config / logs / data

* Fire Structure

```Markdown
├── config
│   ├── nginx
│   │   ├── fastcgi_params
│   │   ├── fastcgi-php.conf
│   │   ├── nginx.conf
│   │   ├── ssl
│   │   │   ├── example.com.crt
│   │   │   └── example.com.key
│   │   └── vhosts
│   │       ├── default.conf
│   │       └── example.com.conf
│   └── php
│       ├── php-fpm.conf
│       └── php.ini
├── data
│   └── composer
├── wwwlogs
│   ├── nginx
│   └── php
├── wwwroot
|   ├── example.com
│   └── example.cn
```

### Build images & Push images

```bash
cd /root/release && docker-compose up -d

docker tag nginx:v1 repository.example.com:5000/nginx:latest
docker tag php:v1 repository.example.com:5000/php:latest

docker login https://repository.example.com:5000

docker push repository.example.com:5000/nginx:latest
docker push repository.example.com:5000/php:latest
```
