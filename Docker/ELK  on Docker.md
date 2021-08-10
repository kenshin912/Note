## Deploy ELK based on Docker

### ELK 说明

```
ELK 部署组件包含 Elastic Search , Logstash , Kibana 以及 filebeat

Elastic Search: 存储及索引日志，提供查询。
Logstash: 过滤日志数据
Kibana: 数据展示
filebeat: 日志文件采集
```

### ELK 部署环境

```
宿主机操作系统: Cent OS 7 / Cent OS 8 / Ubuntu 20.04 / Debian 10
Docker 版本 : 20.10.7, build f0df350
Docker-compose 版本: 1.29.2, build 5becea4c
ELK 版本: 7.7.1
filebeat 版本: 7.7.1
```

### ELK 部署文件

#### ELK 集群

``` yaml
version: "3.9"
 
services:
  elasticsearch01:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.7.1
    container_name: es01
    volumes:
      - ./data/es01:/usr/share/elasticsearch/data:rw
    ports:
      - 9200:9200
      - 9300:9300
    environment:
      node.name: "es01"
      cluster.name: "docker-cluster"
      network.host: "0.0.0.0"
      discovery.seed_hosts: "es02"
      cluster.initial_master_nodes: "es01,es02"
      bootstrap.memory_lock: "true"
      xpack.license.self_generated.type: "basic"
      xpack.security.enabled: "false"
      xpack.monitoring.collection.enabled: "true"
      ES_JAVA_OPTS: "-Xmx512m -Xms512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    networks:
      - elk
 
  elasticsearch02:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.7.1
    container_name: es02
    volumes:
      - ./data/es02:/usr/share/elasticsearch/data:rw
    environment:
      node.name: "es02"
      cluster.name: "docker-cluster"
      network.host: "0.0.0.0"
      discovery.seed_hosts: "es01"
      cluster.initial_master_nodes: "es01,es02"
      bootstrap.memory_lock: "true"
      xpack.license.self_generated.type: "basic"
      xpack.security.enabled: "false"
      xpack.monitoring.collection.enabled: "true"
      ES_JAVA_OPTS: "-Xmx512m -Xms512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    networks:
      - elk
 
  # elasticsearch03:
  #   image: docker.elastic.co/elasticsearch/elasticsearch:7.6.2
  #   container_name: es03
  #   volumes:
  #     - ./data/es03:/usr/share/elasticsearch/data:rw
  #   environment:
  #     node.name: "es03"
  #     cluster.name: "docker-cluster"
  #     network.host: "0.0.0.0"
  #     discovery.seed_hosts: "es01,es02"
  #     cluster.initial_master_nodes: "es01,es02,es03"
  #     bootstrap.memory_lock: "true"
  #     xpack.license.self_generated.type: "basic"
  #     xpack.security.enabled: "false"
  #     xpack.monitoring.collection.enabled: "true"
  #     ES_JAVA_OPTS: "-Xmx1g -Xms1g"
  #   ulimits:
  #     memlock:
  #       soft: -1
  #       hard: -1
  #   networks:
  #     - elk
 
  logstash:
    build:
      context: logstash/
      args:
        ELK_VERSION: $ELK_VERSION
    volumes:
      - ./logstash/config/logstash.yml:/usr/share/logstash/config/logstash.yml:ro
      - ./logstash/pipeline:/usr/share/logstash/pipeline:ro
    ports:
      - "5000:5000/tcp"
      - "5000:5000/udp"
      - "9600:9600"
    environment:
      LS_JAVA_OPTS: "-Xmx256m -Xms256m"
    networks:
      - elk
    depends_on:
      - elasticsearch01
      - elasticsearch02
      #- elasticsearch03
 
  kibana:
    build:
      context: kibana/
      args:
        ELK_VERSION: $ELK_VERSION
    volumes:
      - ./kibana/config/kibana.yml:/usr/share/kibana/config/kibana.yml:ro
    ports:
      - "5601:5601"
    networks:
      - elk
    depends_on:
      - elasticsearch01
      - elasticsearch02
      #- elasticsearch03
    environment:
      - ELASTICSEARCH_URL=http://es01:9200
      - xpack.security.enabled=false
 
networks:
  elk:
    driver: bridge

```

#### ELK 单节点

``` yaml
version: '3.9'

services:
    elasticsearch:
        image: docker.elastic.co/elasticsearch/elasticsearch:7.7.1
        container_name: elasticsearch
        environment:
            discovery.type: single-node
            ELASTIC_PASSWORD: ppnn13%dkstFeb.1st
            ES_JAVA_OPTS: "-Xmx1g -Xms1g"
            xpack.license.self_generated.type: "basic"
            xpack.security.enabled: "false"
            xpack.monitoring.collection.enabled: "true"
        volumes: 
            - /etc/localtime:/etc/localtime
            - /home/elasticsearch/data:/usr/share/elasticsearch/data:rw
        ports: 
            - "9200:9200"
            - "9300:9300"
        restart: always
        networks:
            - elk
    
    logstash:
        image: docker.elastic.co/logstash/logstash:7.7.1
        container_name: logstash
        volumes:
            - ./logstash/config/logstash.yml:/usr/share/logstash/config/logstash.yml:ro
            - ./logstash/pipeline:/usr/share/logstash/pipeline:ro
        ports:
            - "5044:5044"
            - "5000:5000/tcp"
            - "5000:5000/udp"
            - "9600:9600"
        environment:
            LS_JAVA_OPTS: "-Xmx256m -Xms256m"
        networks:
            - elk
        depends_on:
            - elasticsearch
    
    kibana:
        image: docker.elastic.co/kibana/kibana:7.7.1
        container_name: kibana
        volumes:
            - /etc/localtime:/etc/localtime
            - ./kibana/config/kibana.yml:/usr/share/kibana/config/kibana.yml:ro
        ports:
            - "5601:5601"
        environment:
            - ELASTICSEARCH_URL=http://elasticsearch:9200
            - xpack.security.enabled=false
        networks:
            - elk
        depends_on:
            - elasticsearch

networks:
    elk:
        driver: bridge
    



```

#### filebeat Install
> https://www.elastic.co/cn/downloads/beats/filebeat

