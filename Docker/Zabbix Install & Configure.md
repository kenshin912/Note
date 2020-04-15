# Zabbix/Grafana Install & Configure on Docker

```
This is an article of Zabbix/Grafana install & configure post.the following components are based on Docker.
So. Docker is required.
before you get ready and prepare for pull some images from dockerHub . you'd better modify docker registry to docker-cn.
which is seems like that:
{
  "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "http://registry.docker-cn.com"
  ],
  "insecure-registries":["192.168.1.228:5000"]
}
```

## here's the docker-compose file

```yml
version: '2.2'

 services:
     # zabbix-server container config
     server:
         image: zabbix/zabbix-server-mysql:latest
         container_name: zabbix-server
         depends_on:
             - mysql
             - agent
         environment:
             TZ: Asia/Shanghai
             DB_SERVER_HOST: "mysql"
             MYSQL_DATABASE: "zabbix"
             MYSQL_USER: "zabbix"
             MYSQL_PASSWORD: "fucking mysql password"
             MYSQL_ROOT_PASSWORD: "fucking root password"
         ports:
             - "10051:10051"
         volumes:
             - /etc/localtime:/etc/localtime:ro
         links:
             - mysql:zabbix-mysql
             - agent:zabbix-agent
         user: root
         networks:
             zabbixbr:
                 ipv4_address: 172.16.0.6
         restart: always

     # zabbix-agent container config
     agent:
         image: zabbix/zabbix-agent:latest
         container_name: zabbix-agent
         privileged: true
         ports:
             - "10050:10050"
         volumes:
             - /etc/localtime:/etc/localtime:ro
         user: root
         networks:
             zabbixbr:
                 ipv4_address: 172.16.0.5
         restart: always

     # zabbix-web container config
     web:
        image: zabbix/zabbix-web-nginx-mysql:latest
        container_name: zabbix-web
        depends_on:
            - mysql
            - server
        environment:
            TZ: Asia/Shanghai
            DB_SERVER_HOST: "mysql"
            ZBX_SERVER_HOST: "server"
            MYSQL_DATABASE: "zabbix"
            MYSQL_USER: "zabbix"
            MYSQL_PASSWORD: "fucking mysql password"
            MYSQL_ROOT_PASSWORD: "fucking root password"
        volumes:
            - /etc/localtime:/etc/localtime:ro
        links:
            - mysql:zabbix-mysql
            - server:zabbix-server
        ports:
            - "88:80"
        user: root
        networks:
            zabbixbr:
                ipv4_address: 172.16.0.4
        restart: always
    # MySQL container config
    mysql:
        image: mysql:5.7
        container_name: zabbix-mysql
        command: --character-set-server=utf8 --collation-server=utf8_general_ci
        environment:
            TZ: Asia/Shanghai
            MYSQL_DATABASE: "zabbix"
            MYSQL_USER: "zabbix"
            MYSQL_PASSWORD: "fucking mysql password"
            MYSQL_ROOT_PASSWORD: "fucking root password"
        networks:
            zabbixbr:
                ipv4_address: 172.16.0.3
        volumes:
            #  Path of MySQL Volumes , define whatever you want.
            #  here is "/home/kood/"
            - /home/kood/data/zabbix/database/mysql:/var/lib/mysql
            - /etc/localtime:/etc/localtime:ro
        restart: always

     # Grafana
    grafana:
        image: grafana/grafana:latest
        container_name: zabbix-grafana
        environment:
            TZ: Asia/Shanghai
            # Input the plugins name you need , separate by commas.
            GF_INSTALL_PLUGINS: alexanderzobnin-zabbix-app
        volumes:
            - grafana-storage:/var/lib/grafana
            - grafana-etc:/etc/grafana
        ports:
            - "3000:3000"
        networks:
            zabbixbr:
                ipv4_address: 172.16.0.2
        restart: always

    # Create Volumes
    volumes:
        grafana-storage:
        grafana-etc:
    # Stack internal network config
    networks:
        zabbixbr:
        driver: bridge
        ipam:
            config:
                - subnet: 172.16.0.0/16
                  gateway: 172.16.0.1
```

## docker pull images

```bash
sudo docker pull mysql:5.7
sudo docker pull zabbix/zabbix-server-mysql:latest
sudo docker pull zabbix/zabbix-agent:latest
sudo docker pull zabbix/zabbix-web-nginx-mysql:latest
sudo docker pull grafana/grafana:latest
```

## run docker-compose

```bash
sudo docker-compose up -d
sudo docker-compose ps
```

## Zabbix configure

visit page `http://yourpage.com:88/` to configure Zabbix.

login with ID: admin & password: zabbix

Configure -> Hosts -> Zabbix server , Agent interface , change ip to `zabbix-agent IP Address` . -> Update.

return to Hosts list , wait for a minutes , if `ZBX` tag turn to green , then it WORKS !

## Grafana configure

visit page `http://yourpage.com:3000/` to configure Grafana.

login with ID: admin & password: admin

enable Grafana , Create data source , input URL : `http://yourpage.com:88/api_jsonrpc.php` . input zabbix username & password.