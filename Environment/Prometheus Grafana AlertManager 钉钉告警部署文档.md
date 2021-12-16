## Prometheus + Grafana + AlertManager + 钉钉告警 部署文档

### Introduction

​	All services deployed by **docker-compose** except **node_exporter** .

#### Requirements

​	docker version : 20 +

​	docker-compose version : 1.29 +

​	OS : Ubuntu 18 + / Cent OS 7 +

#### Tree List View

```
/home/config/
.
├── alertmanager
│   └── alertmanager.yml
├── blackbox
│   ├── blackbox.yml
├── dingtalk
│   └── config.yml
├── prometheus
│   ├── prometheus.yml
│   └── rules
│       └── host_rules.yaml
```



#### Deploy

##### docker-compose.yml

```yaml
version: '3.9'

services:
    blackbox:
        image: ${BLACKBOX_IMAGE}
        container_name: blackbox-exporter
        ports:
            - "9115:9115"
        volumes:
            - /usr/share/zoneinfo/Asia/Shanghai:/etc/localtime:ro
            - ${BLACKBOX_CONF_FILE}:/etc/blackbox_exporter/config.yml
        restart: always
        networks:
            - prometheus

    cadvisor:
        image: ${CADVISOR_IMAGE}
        container_name: cadvisor
        ports:
            - "8080:8080"
        volumes:
            - /:/rootfs:ro
            - /var/run:/var/run:rw
            - /sys:/sys:ro
            - /var/lib/docker/:/var/lib/docker:ro
        restart: always
        networks:
            - prometheus

    prometheus:
        image: ${PROMETHEUS_IMAGE}
        container_name: prometheus
        ports:
            - "9090:9090"
        volumes:
            - ${PROMETHEUS_CONF_PATH}:/etc/prometheus
            - ${PROMETHEUS_DATA_PATH}:/prometheus-tsdb
        environment:
            - TZ=${TZ}
        command:
            - '--config.file=/etc/prometheus/prometheus.yml'
            - '--storage.tsdb.path=/prometheus-tsdb'
            - '--storage.tsdb.retention.time=7d' #数据保存时间,默认7天
        restart: always
        networks:
            - prometheus
        depends_on:
            - alertmanager
            
		alertmanager:
        image: ${ALERTMANAGER_IMAGE}
        container_name: alertmanager
        ports:
            - "9333:9003" # Maybe useless
            - "9093:9093"
        volumes:
            - ${ALERTMANAGER_CONF_PATH}:/etc/alertmanager
        environment:
            - TZ=${TZ}
        command:
            - "--config.file=/etc/alertmanager/alertmanager.yml"
        restart: always
        networks:
            - prometheus
            
    webhook:
    		image: ${WEBHOOK_IMAGE}
    		container_name: webhook_dingtalk
    		ports:
    				- "8060:8060"
    		volumes:
    				- ${WEBHOOK_CONF_FILE}:/etc/prometheus-webhook-dingtalk/config.yml
    		restart: always
    		networks:
    				- prometheus
            
    grafana:
    		image: ${GRAFANA_IMAGE}
    		container_name: grafana
    		ports:
    				- "3000:3000"
    		volumes:
    				- ${GRAFANA_DATA_PATH}:/var/lib/grafana
    		privileged: true
    		user: root
    		restart: always
    		networks:
    				- prometheus
    		
networks:
    prometheus:
        driver: bridge
```



##### .env

```yaml
TZ=Asia/Shanghai
DATA_PATH=/home/data

BLACKBOX_IMAGE=prom/blackbox-exporter:latest
BLACKBOX_CONF_FILE=/home/config/blackbox/blackbox.yml

CADVISOR_IMAGE=google/cadvisor:latest

PROMETHEUS_IMAGE=prom/prometheus:latest
PROMETHEUS_CONF_PATH=/home/config/prometheus
PROMETHEUS_DATA_PATH=/home/data/prometheus

ALERTMANAGER_IMAGE=prom/alertmanager:latest
ALERTMANAGER_CONF_PATH=/home/config/alertmanager

WEBHOOK_IMAGE=timonwong/prometheus-webhook-dingtalk
WEBHOOK_CONF_FILE=/home/config/dingtalk/config.yml

GRAFANA_IMAGE=grafana/grafana:latest
GRAFANA_DATA_PATH=/home/data/grafana

```



##### /home/config/alertmanager/alertmanager.yml

```yaml
global:
  resolve_timeout: 5m
  #邮件
  smtp_smarthost: 'smtp.exmail.qq.com:465'
  smtp_from: '***'
  smtp_auth_username: '****'
  smtp_auth_password: '****' #邮箱的授权密码或登录密码
  smtp_require_tls: false

#定义模板信息
#templates:
#  - '/home/admin/alertmanager/template/*.tmpl'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 5m
  receiver: 'dingding_ops'
  routes:
#  - receiver: 'dingding_group'
#    group_wait: 10s
#    group_interval: 10s
#    repeat_interval: 3m
#    match_re:
#      severity: 'error'

receivers:
  - name: 'dingding_ops'
    webhook_configs:
    - url: 'http://192.168.1.55:8060/dingtalk/webhook1/send'  #
      send_resolved: true #发送已解决通知
      #message: '{{ template "dingding_alert.html" . }}'

#告警抑制
inhibit_rules:
  - source_match:
      alertname: 'critical'
    target_match:
      alertname: 'warning'
    equal: ['job']
```



##### /home/config/blackbox/blackbox.yml

```yaml
## blackbox_exporter/blackbox.yml
modules:
  http_2xx:
    prober: http
    timeout: 20s
    http:
      preferred_ip_protocol: "ip4"
  http_post_2xx_query:
    prober: http
    timeout: 20s
    http:
      preferred_ip_protocol: "ip4" ##使用ipv4
      method: POST
      headers:
        Content-Type: application/json ##header头
      body: '{"hmac":"","params":{"publicFundsKeyWords":"xxx"}}' ##传参
  tls_connect_tls:
    prober: tcp
    timeout: 5s
    tcp:
      tls: true
  tcp_connect:
    prober: tcp
    timeout: 5s
   #
  pop3s_banner:
    prober: tcp
    tcp:
      query_response:
      - expect: "^+OK"
      tls: true
      tls_config:
        insecure_skip_verify: false
  ssh_banner:
    prober: tcp
    tcp:
      query_response:
      - expect: "^SSH-2.0-"
  irc_banner:
    prober: tcp
    tcp:
      query_response:
      - send: "NICK prober"
      - send: "USER prober prober prober :prober"
      - expect: "PING :([^ ]+)"
        send: "PONG ${1}"
      - expect: "^:[^ ]+ 001"
  icmp:
    prober: icmp
    timeout: 20s
```



##### /home/config/dingtalk/config.yml

```yam
## Request timeout
# timeout: 5s

## Uncomment following line in order to write template from scratch (be careful!)
#no_builtin_template: true

## Customizable templates path
#templates:
#  - contrib/templates/legacy/template.tmpl

## You can also override default template using `default_message`
## The following example to use the 'legacy' template from v0.3.0
#default_message:
#  title: '{{ template "legacy.title" . }}'
#  text: '{{ template "legacy.content" . }}'

## Targets, previously was known as "profiles" , webhook1 地址及密钥不要随意更改.
targets:
  webhook1:
    url: https://oapi.dingtalk.com/robot/send?access_token=890a4324ce2da5a798d4e9227b6b43aa39dc512d9e8a9ff0318a1c100ae18e40
    # secret for signature
    secret: SECac92306b6948e40112fb4b72f43334925fe1512b59641988de46a41282271f25
  webhook2:
    url: https://oapi.dingtalk.com/robot/send?access_token=xxxxxxxxxxxx
  webhook_legacy:
    url: https://oapi.dingtalk.com/robot/send?access_token=xxxxxxxxxxxx
    # Customize template content
    message:
      # Use legacy template
      title: '{{ template "legacy.title" . }}'
      text: '{{ template "legacy.content" . }}'
  webhook_mention_all:
    url: https://oapi.dingtalk.com/robot/send?access_token=xxxxxxxxxxxx
    mention:
      all: true
  webhook_mention_users:
    url: https://oapi.dingtalk.com/robot/send?access_token=xxxxxxxxxxxx
    mention:
      mobiles: ['156xxxxxxxx', '189xxxxxxxx']
```



##### /home/config/prometheus/prometheus.yml

```yaml
my global config
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
    # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
    alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

rule_files:
    - "rules/*.yaml" #载入 Alert 规则文件
#  - ssl_expiry.rules

scrape_configs:
    - job_name: 'web_status'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets: ['http://192.168.1.55:8088/#/login']
        labels:
          instance: 'erp_test'
          group: 'web'
      - targets: ['https://www.wewoerp.com/#/login']
        labels:
          instance: 'erp_prod'
          group: 'web'
      - targets: ['http://yearning.qferp.net/#/login']
        labels:
          instance: 'Yearning'
          group: 'web'
      - targets: ['http://192.168.1.246/login']
        labels:
          instance: 'Walle'
          group: 'web'
      - targets: ['http://192.168.1.231:8888/users/sign_in']
        labels:
          instance: 'Gitlab'
          group: 'web'
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - target_label: __address__
        replacement: 192.168.1.55:9115

  - job_name: 'docker'
    static_configs:
      - targets: ['192.168.1.55:8080','192.168.1.115:8080'] # 8080 是 cadvisor 的端口


  - job_name: 'ERP_Project'
    static_configs:
      - targets: ['192.168.1.55:9100','192.168.1.115:9100'] # 9100 端口是 node_exporter 的端口

  - job_name: 'TEST_SERVER'
    static_configs:
      - targets: ['192.168.1.230:9100','192.168.1.231:9100']
```



##### /home/config/prometheus/runles/host_rules.yaml

```yaml
groups:
- name: 站点无法访问
  rules:
  - alert: "站点无法访问"
    expr: probe_http_status_code != 200
    for: 2m
    labels:
      user: prometheus
      severity: warning
    annotations:
      description: "{{ $labels.instance }} 无法访问! 状态码{{ $value }}"

- name: 实例内存即将满载
  rules:
  - alert: 实例内存即将满载
    expr: node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100 < 10  # Alert when Memory usage is above 80%
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: 实例 {{ $labels.instance }} 内存即将满载
      description: "实例内存即将满载 (剩余可用 < 20% )\n  剩余可用 = {{ $value }}\n  标签 = {{ $labels }}"

- name: 实例内存压力告警
  rules:
  - alert: 实例内存压力告警
    expr: rate(node_vmstat_pgmajfault[1m]) > 1000 # 内存压力大
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: 实例 {{ $labels.instance }} 内存压力告警
      description: "实例内存压力告警\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

- name: 实例 CPU 高负载告警
  rules:
  - alert: 实例 CPU 高负载
    expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100) > 70 # Alert when CPU usage is above 70%
    for: 1m
    labels:
      severity: warning
    annotations:
      summary: 实例 {{ $labels.instance }} CPU 高负载
      description: "实例 CPU 高负载 > 80%\n  CPU 占用 = {{ $value }}\n  标签 = {{ $labels }}"

- name: 实例磁盘可用空间报警
  rules:
  - alert: 实例磁盘可用空间报警
    expr: (node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes < 30 and ON (instance, device, mountpoint) node_filesystem_readonly == 0 # Alert when Disk usage is above 70%
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: 实例 {{ $labels.instance }} 磁盘可用空间不足
      description: "实例磁盘可用空间不足 (剩余可用 < 30% )\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

- name: 实例网络出站流量告警
  rules:
  - alert: 实例网络出站流量告警
    expr: sum by (instance) (rate(node_network_transmit_bytes_total[2m])) / 1024 / 1024 > 10 # 出站流量超过 70 MB/s
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: 实例 {{ $labels.instance }} 网络出站流量告警
      description: "实例网络出站流量告警 (> 70 MB/s)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

- name: 实例网络入站流量告警
  rules:
  - alert: 实例网络入站流量告警
    expr: sum by (instance) (rate(node_network_receive_bytes_total[2m])) / 1024 / 1024 > 10
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: 实例 {{ $labels.instance }} 网络入站流量告警
      description: "实例网络入站流量告警 (> 70 MB/s)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

- name: 实例磁盘 IOPS 告警
  rules:
  - alert: 实例磁盘 IOPS 告警
    expr: sum by (instance) ((rate(node_disk_reads_completed_total[2m])) + (rate(node_disk_writes_completed_total[2m]))) > 7000
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: 实例 {{ $labels.instance }} 磁盘 IOPS 告警
      description: "实例 {{ $labels }} IOPS 告警\n IOPS: {{ $value }} "

- name: 实例磁盘读取速率告警
  rules:
  - alert: 实例磁盘读取速率告警
    expr: sum by (instance) (rate(node_disk_read_bytes_total[2m])) / 1024 / 1024 > 50
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: 实例 {{ $labels.instance }} 磁盘读取速率告警
      description: "磁盘读取速率告警 (> 50 MB/s)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

- name: 实例磁盘写入速率告警
  rules:
  - alert: 实例磁盘写入速率告警
    expr: sum by (instance) (rate(node_disk_written_bytes_total[2m])) / 1024 / 1024 > 50
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: 实例 {{ $labels.instance }} 磁盘写入速率告警
      description: "磁盘写入速率告警 (> 50 MB/s)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

- name: 实例 Inodes 告警
  rules:
  - alert: 实例 Inodes 告警
    expr: node_filesystem_files_free{mountpoint ="/rootfs"} / node_filesystem_files{mountpoint="/rootfs"} * 100 < 10 and ON (instance, device, mountpoint) node_filesystem_readonly{mountpoint="/rootfs"} == 0
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: 实例 {{ $labels.instance }} inodes 告警
      description: "实例可用 inodes 不足 (< 10% left)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

- name: 实例 Swap 空间不足
  rules:
  - alert: 实例 Swap 空间不足
    expr: (1 - (node_memory_SwapFree_bytes / node_memory_SwapTotal_bytes)) * 100 > 80
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: 实例 {{ $labels.instance }} Swap 将满
      description: "实例 Swap 将满 (>80%)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

- name: 检测到 OOM Kill
  rules:
  - alert: 检测到 OOM Kill 发生
    expr: increase(node_vmstat_oom_kill[1m]) > 0
    for: 0m
    labels:
      severity: warning
    annotations:
      summary: 实例 {{ $labels.instance }} 检测到 OOM Kill
      description: "实例检测到 OOM Kill\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

```



##### /home/config/prometheus/runles/container_rules.yaml

```yaml
groups: 
- name: Container killed
  rules:
  - alert: ContainerKilled
    expr: time() - container_last_seen > 60
    for: 0m
    labels:
      severity: warning
    annotations:
      summary: Container killed (instance {{ $labels.instance }})
      description: "A container has disappeared\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

- name: Container CPU Usage
  rules:
  - alert: ContainerCpuUsage
    expr: (sum(rate(container_cpu_usage_seconds_total{image!=""}[3m])) BY (instance, name) * 100) > 80
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: Container {{ $labels.instance }} CPU usage too much
      description: "Container CPU usage is above 80%\n  CPU Usage = {{ $value }}\n  LABELS = {{ $labels }}"

- name: Container Memory Usage
  rules:
  - alert: ContainerMemoryUsage
    expr: (sum(container_memory_usage_bytes{name=~".+"}) BY (name,instance) - sum(container_memory_cache{name=~".+"}) by (name,instance)) /1048576 > 2048
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: Container {{ $labels.instance }} Memory usage too much
      description: "Container Memory usage is above 1GB\n  Memory Usage = {{ $value }}MB\n  LABELS = {{ $labels }}"

- name: Container Volume Usage
  rules:
  - alert: ContainerVolumeUsage
    expr: (1 - (sum(container_fs_inodes_free) BY (instance) / sum(container_fs_inodes_total) BY (instance))) * 100 > 80
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: Container Volume usage (instance {{ $labels.instance }})
      description: "Container Volume usage is above 80%\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

- name: Container Volume I/O Usage
  rules:
  - alert: ContainerVolumeIOUsage
    expr: (sum(container_fs_io_current) BY (instance, name) * 100) > 80
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: Container Volume IO usage (instance {{ $labels.instance }})
      description: "Container Volume IO usage is above 80%\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

- name: Container high throttle rate
  rules:
  - alert: ContainerHighThrottleRate
    expr: rate(container_cpu_cfs_throttled_seconds_total[3m]) > 1
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: Container high throttle rate (instance {{ $labels.instance }})
      description: "Container is being throttled\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

```





#### Exporter install

```bash
tar zxvf node_exporter-1.2.2.linux-amd64.tar.gz
cd node_exporter-1.2.2.linux-amd64/
mv node_exporter /usr/local/bin/
vim /etc/systemd/system/node-exporter.service
```

```shell
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



#### cAdvisor

```
docker run -d --name cadvisor -p 7100:8080 -v /:/rootfs:ro -v /var/run:/var/run:rw -v /sys:/sys:ro -v /var/lib/docker/:/var/lib/docker:ro google/cadvisor:latest
```


