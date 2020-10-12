## Build Prometheus & Grafana on docker-compose

### Create docker-compose file

Create docker-compose.yml and .env files

```yaml
version: '3.6'

services:
    openresty:
        image: "${OPENRESTY_IMAGE}"
        container_name: "openresty"
        ports:
            - "80:80"
            - "443:443"
        volumes:
            - ${SOURCE_DIR}:/home/wwwroot/:rw
            - ${OPENRESTY_SSL_DIR}:/etc/nginx/ssl:rw
            - ${OPENRESTY_CONF_DIR}:/etc/nginx/conf.d/:rw
            - ${OPENRESTY_CONF_FILE}:/usr/local/openresty/nginx/conf/nginx.conf:ro
            - ${OPENRESTY_LOG_DIR}:/home/wwwlogs/nginx/:rw
        restart: always
        networks:
            - prometheus
        depends_on:
            - grafana
    
    prometheus:
        image: "prom/prometheus"
        container_name: "prometheus"
        volumes:
            - ${PROMETHEUS_CONF_FILE}:/etc/prometheus/prometheus.yml
        restart: always
        networks:
            - prometheus

    grafana:
        image: "grafana/grafana"
        container_name: "grafana"
        volumes:
            - ${DATA_DIR}grafana:/var/lib/grafana/:rw
        restart: always
        privileged: true
        user: root
        #environment:
            #- GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
        networks:
            - prometheus
        depends_on:
            - prometheus

networks:
    prometheus:
        driver: bridge
```

```bash
TZ=Asia/Shanghai

CONTAINER_PACKAGE_URL=mirrors.aliyun.com
SOURCE_DIR=/home/wwwroot/
DATA_DIR=/home/data/

OPENRESTY_IMAGE=openresty/openresty:latest
OPENRESTY_CONF_DIR=/home/config/nginx/vhosts
OPENRESTY_CONF_FILE=/home/config/nginx/nginx.conf
OPENRESTY_SSL_DIR=/home/config/nginx/ssl
OPENRESTY_LOG_DIR=/home/wwwlogs/nginx
OPENRESTY_LUA_DIR=/home/config/nginx/lua

PROMETHEUS_CONF_FILE=/home/config/prometheus/prometheus.yml
```

### Create Config directorys & files

```bash
mkdir -p /home/config/nginx/
mkdir -p /home/config/nginx/ssl/
mkdir -p /home/config/nginx/vhosts/
mkdir -p /home/config/prometheus/
mkdir -p /home/config/grafana/
mkdir -p /home/wwwroot/
mkdir -p /home/wwwlogs/
mkdir -p /home/wwwlogs/nginx/
mkdir -p /home/data/
mkdir -p /home/data/grafana/

Tree list view

├── config
│   ├── grafana
│   ├── nginx
│   │   ├── nginx.conf
│   │   ├── ssl
│   │   │   ├── xxx.com.key
│   │   │   └── xxx.com.pem
│   │   └── vhosts
│   │       ├── default.conf
│   │       └── prometheus.conf
│   └── prometheus
│       └── prometheus.yml
├── data
│   └── grafana
│       ├── grafana.db
│       ├── plugins
│       └── png
├── wwwlogs
│   └── nginx
│       ├── grafana.access.log
│       └── grafana.error.log
└── wwwroot

```

### Prometheus vhosts file

```conf
server {
    listen 80;
    server_name grafana.xxx.com;
    return  301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name grafana.xxx.com;
    ssl_certificate     /etc/nginx/ssl/xxx.com.pem;
    ssl_certificate_key /etc/nginx/ssl/xxx.com.key;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_timeout 10m;
    ssl_session_cache builtin:1000 shared:SSL:10m;
    ssl_buffer_size 1400;
    #ssl_stapling on;
    #ssl_stapling_verify on;

    access_log /home/wwwlogs/nginx/grafana.access.log main;
    error_log /home/wwwlogs/nginx/grafana.error.log error;

    location / {
        proxy_pass http://grafana:3000/;
    }
}
```

### Prometheus config file

```yaml
global:
  scrape_interval:     15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
  - static_configs:
    - targets:

rule_files:

scrape_configs:

  - job_name: 'prometheus'
    static_configs:
    - targets: ['192.168.3.227:9090']

  - job_name: 'node'
    static_configs:
    - targets: ['192.168.3.221:9100','192.168.3.222:9100','192.168.3.223:9100','192.168.3.224:9100']

  - job_name: 'TST'
    static_configs:
    - targets: ['192.168.3.219:9100','192.168.3.218:9100','192.168.3.216:9100','192.168.3.215:9100','192.168.3.214:9100','192.168.3.207:9100']
```

### Node_export Install

```bash
tar zxvf node_exporter-1.0.1.linux-amd64.tar.gz
cd node_exporter-1.0.1.linux-amd64/
mv node_exporter /usr/local/bin/
vim /etc/systemd/system/node-exporter.service
```

```bash
[Unit]
Description=Prometheus Node Exporter
After=network.target
[Service]
ExecStart=/usr/local/bin/node_exporter
User=root
Restart=on-failure
[Install]
WantedBy=multi-user.target
```

```bash
systemctl daemon-reload
systemctl enable node-exporter.service
systemctl start node-exporter.service
systemctl status node-exporter.service
```

