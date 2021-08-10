## Elasticsearch 集群搭建文档



### 服务器列表

| IP Address   | Hostname | Remark |
| ------------ | -------- | ------ |
| 172.31.1.100 | es1      | 主节点 |
| 172.31.1.101 | es2      |        |
| 172.31.1.102 | es3      |        |

``` bash
vim /etc/hosts
```

``` bash
172.31.1.100	es1
172.31.1.101	es2
172.31.1.102	es3
```

修改 3 台服务器 `hosts `



### Java 运行环境安装

``` bash
tar zxvf jdk-8u291-linux-x64.tar.gz
mv jdk-8u291-linux /usr/local/jdk
vim /etc/profile
```

``` bash
export JAVA_HOME=/usr/local/jdk
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:$PATH
```

``` bash
source /etc/profile
ln -s /usr/local/jdk/bin/java /usr/bin/java
java -version
```



### 服务器免密码登录

所有服务器互相做好免密码登录

``` bash
ssh-keygen

cat ~/.ssh/id_rsa.pub

vim ~/.ssh/authorized_keys
```



### Elasticsearch 安装

``` bash
tar -zxvf elasticsearch-7.10.2-linux-x86_64.tar.gz -C /usr/local/elasticsearch/
```



进入 `Elasticsearch` 安装目录，找到 `config` 目录并编辑 `elasticsearch.yml`

``` yaml
#配置 es 的集群名称，同一个集群中的多个节点使用相同的标识
#如果在同一网段下有多个集群，就可以用这个属性来区分不同的集群。
cluster.name: es-cluster

#节点名称
node.name: node-a

#是不是有资格竞选主节点
node.master: true
#是否存储数据
node.data: true
#最大集群节点数
node.max_local_storage_nodes: 3

#数据存储路径
path.data: /home/data/elasticsearch
#日志存储路径
path.logs: /home/wwwlogs/elasticsearch

#节点所绑定的 IP 地址，并且该节点会被通知到集群中的其他节点
#通过指定相同网段的其他节点会加入该集群中 0.0.0.0 任意IP都可以访问 elasticsearch
network.host: 172.31.1.100

#对外提供服务的 http 端口，默认为 9200
http.port: 9200

#内部节点之间沟通端口
transport.tcp.port: 9300

#es7.x 之后新增的配置，写入候选主节点的设备地址，在开启服务后可以被选为主节点
discovery.seed_hosts: ["172.31.1.100:9300","172.31.1.101:9300","172.31.1.102:9300"]

#es7.x 之后新增的配置，初始化一个新的集群时需要此配置来选举 master
cluster.initial_master_nodes: ["node-a", "node-b","node-c"]

#ES 默认开启了内存地址锁定，为了避免内存交换提高性能。但是 Centos6 不支持 SecComp 功能，启动会报错，所以需要将其设置为 false
bootstrap.memory_lock: false

# 是否支持跨域
http.cors.enabled: true

# *表示支持所有域名
http.cors.allow-origin: "*"
```

修改`limits.conf`配置文件

``` bash
vim /etc/security/limits.conf

* soft nofile 65536
* hard nofile 131072
* soft nproc 2048
* hard nproc 4096
* soft memlock unlimited
* hard memlock unlimited


vim /etc/sysctl.conf

vm.max_map_count=262144

sysctl -p
```

由于 `Elasticsearch` 限制，不可以使用 `root` 用户启动。

``` bash
adduser elasticsearch

passwd elasticsearch

chown -R elasticsearch:elasticsearch /usr/local/elasticsearch
```



### 启动集群

``` bash
#切换到用户
su elasticsearch

#切换到 a 节点 elasticsearch 的 bin 目录
cd /usr/local/elasticsearch/bin

#控制台启动命令
./elasticsearch

#后台启动命令
#./elasticsearch -d
```



### 查看集群状态

访问集群服务器任意 IP，查看集群节点  http://172.31.1.100:9200/_cat/nodes?v

查看集群状态 http://172.31.1.100:9200/_cluster/stats?pretty



### 验证集群状态

安装 `elasticsearch-head`

```bash
docker pull mobz/elasticsearch-head:5

docker run -d --name es-head -p 9100:9100 mobz/elasticsearch-head:5
```

访问 http://IP:9100 设置集群地址即可



### 修改 JVM 堆大小

切换到 `config` 目录打开 `jvm.options` 修改 `Xms` 和 `Xmx`

``` bash
vim /usr/local/elasticsearch/config/jvm.options
```

Elasticsearch 使用 `Xms` ( minimum heap size ) 以及 `Xmx` ( maxmimum heap size ) 设置堆的大小，你应该将这两个值设置为同样大小。

`Xms`  和 `Xmx` 不能大于宿主机内存的 50 % ，建议设置为宿主机可用 RAM 的 50 % ，最多最大 30 GB，以避免 GC



