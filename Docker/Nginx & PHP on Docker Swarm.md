## Running Nginx & PHP on Docker Swarm Mode

### Docker Registry
```
On Docker Swarm Mode , the nodes of whole Cluster should use the same image.
Push image to Registry when image build done.
When Cluster working , it will download image from Registry automatically.
```
> [--> Running Docker Registry on Docker <--](https://github.com/kenshin912/Note/blob/master/Docker/Docker%20Registry%20on%20Docker.md)

### Build Image
* #### File Structure
```
+-- docker-compose.yml
+-- logs
+-- nginx
|   +-- Dockerfile
|   +-- ssl
|       +-- fullchain.pem
|       +-- key.pem
|   +-- vhosts
|       +-- www.example.com.conf
|       +-- api.example.com.conf
+-- php
|   +-- Dockerfile
|   +-- sources.list
|   +-- php-fpm.conf
+-- www
|   +-- www.example.com
|       +-- index.html
|       +-- public
|           +-- main.css
|           +-- head.css
|   +-- api.exaple.com
|       +-- index.php
|       +-- config
|           +-- config.inc.php
```
##### docker-compose.yml
```
version: '2'
services:
    nginx:
        image: "local/nginx:v1"
        container_name: nginx
        build:
            context: .
            dockerfile: ./nginx/Dockerfile
        ports:
            - "80:80"
            - "443:443"
        networks:
            - frontend
        depends_on:
            - php
    php:
        image: "local/php:v1"
        container_name: php
        build:
            context: .
            dockerfile: ./php/Dockerfile
        ports:
            - "9000:9000"
        networks:
            - frontend
            - backend
        environment:
            MYSQL_PASSWORD: MySQLMIMA
#        depends_on:
#            - mysql
#    mysql:
#        image: mysql:5.7
#        volumes:
#            - mysql-data:/var/lib/mysql
#        environment:
#            TZ: 'Asia/Shanghai'
#            MYSQL_ROOT_PASSWORD: MySQLMIMA
#         command: ['mysqld', '--character-set-server=utf8']
#         networks:
#            - backend
#
#volumes:
#    mysql-data:
networks:
    frontend:
    backend:
```

##### Nginx Dockerfile
```
FROM nginx:latest
ENV TZ=Asia/Shanghai
RUN mkdir -p /etc/nginx/ssl
COPY ./nginx/vhosts /etc/nginx/conf.d/
COPY ./nginx/ssl /etc/nginx/ssl
COPY ./www /usr/share/nginx/html
```

##### PHP Dockerfile
```
 FROM alpine

 LABEL maintainer="Kenshin <kenshin912@gmail.com>"

 ENV TIMEZONE            Asia/Shanghai
 ENV PHP_MEMORY_LIMIT    512M
 ENV MAX_UPLOAD          50M
 ENV PHP_MAX_FILE_UPLOAD 200
 ENV PHP_MAX_POST        100M

 RUN apk update \
     && apk upgrade \
     && apk add \
         tini \
         curl \
         tzdata \
         php7-fpm \
         php7 \
         php7-apcu \
         php7-bcmath \
         php7-xmlwriter \
         php7-ctype \
         php7-curl \
         php7-common \
         php7-dev \
         php7-iconv \
         php7-intl \
         php7-json \
         php7-mbstring \
         php7-openssl \
         php7-pcntl \
         php7-pdo \
         php7-mysqlnd \
         php7-mysqli \
         php7-pdo_mysql \
         php7-pdo_pgsql \
         php7-phar \
         php7-posix \
         php7-session \
         php7-simplexml \
         php7-xml \
         php7-mcrypt \
         php7-xsl \
         php7-zip \
         php7-zlib \
         php7-redis \
         php7-gd \
         php7-xmlreader \
     && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
     && echo "${TIMEZONE}" > /etc/timezone \
     && apk del tzdata \
     && rm -rf /var/cache/apk/*

 RUN mkdir -p /usr/local/var/log/php7/
 RUN mkdir -p /usr/local/var/run/

 COPY ./php/php-fpm.conf /etc/php7/

 RUN sed -i "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" /etc/php7/php.ini && \
     sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php7/php.ini && \
     sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|i" /etc/php7/php.ini && \
     sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php7/php.ini && \
     sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php7/php.ini && \
     sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= 0|i" /etc/php7/php.ini && \
     sed -i "s|;*listen =.*|listen = 0.0.0.0:9000|i" /etc/php7/php-fpm.d/www.conf
COPY ./www /var/www/html
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/sbin/php-fpm7", "-R", "--nodaemonize"]
EXPOSE 9000
```

##### Source.list 
```
deb http://mirrors.163.com/debian/ jessie main
deb http://mirrors.163.com/debian/ jessie-updates main
deb http://mirrors.163.com/debian-security/ jessie/updates main
```
##### Build images
> $ sudo docker build -t local/php:v1

> $ sudo docker build -t local/nginx:v1

##### RUN docker-compose
> $ sudo docker-compose up -d

##### Push images to Registry
> $ sudo docker tag local/nginx:v1 192.168.1.228:5000/yuan/nginx:v1

> $ sudo docker tag local/php:v1 192.168.1.228:5000/yuan/php:v1

> $ sudo docker push 192.168.1.228:5000/yuan/php

> $ sudo docker push 192.168.1.228:5000/yuan/nginx


### Docker Swarm

#### Initial Swarm Mode

##### On Swarm Leader
> $ sudo docker swarm init

##### On Swarm Node
> $ sudo docker swarm join --token SWMTKN-1-36obhahlhhwfefcs46olwslzmcg0kogth2k7vs032e8iuvx3ep-19xqdp0htn8pqiq47qblo64ob 192.168.1.229:2377

##### Confirm Swarm Mode Actived
> $ sudo docker node ls
```
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
33h23pz0ky1nfw1iumc6jgg32 *   DockerSwarmManage   Ready               Active              Leader              19.03.5
me16dolfohrno24wxqba9p8dm     DockerSwarmNode1    Ready               Active                                  19.03.5

```
##### HTTP Protocol support
* Do this on EVERY NODE ( include Swarm Leader )
> $ sudo vim /etc/docker/daemon.json

```
{ "insecure-registries": ["192.168.1.228:5000"] }
```

> $ sudo systemctl restart docker.service

##### Create stack file
> $ sudo vim service_stack.yml
```
version: '3'
services:
    nginx:
        image: 192.168.1.228:5000/yuan/nginx:v1
        ports:
            - "80:80"
            - "443:443"
        networks:
            - stack_net
         deploy:
             mode: replicated
             replicas: 2
             restart_policy:
                 condition: on-failure
         depends_on:
             - php
     php:
         image: 192.168.1.228:5000/yuan/php:latest
         networks:
             - stack_net
         deploy:
             mode: replicated
             replicas: 2

 networks:
     stack_net:
         driver: overlay
```

##### RUN Swarm
> $ sudo docker stack deploy -c service_stack.yml yuan

> sudo docker service ls
```
ID                  NAME                MODE                REPLICAS            IMAGE                                PORTS
txdfs0g500oj        yuan_nginx          replicated          2/2                 192.168.1.228:5000/yuan/nginx:v1     *:80->80/tcp, *:443->443/tcp
s8dhwk9g2m7o        yuan_php            replicated          2/2                 192.168.1.228:5000/yuan/php:latest
```