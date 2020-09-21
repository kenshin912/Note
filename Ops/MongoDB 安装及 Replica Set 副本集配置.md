## MongoDB 安装及 Replica Set 副本集配置

### MongoDB 安装

创建 mongodb.repo

```bash
vim /etc/yum.repos.d/mongodb.repo
```

> [mongodb-org-4.0]  
> name=MongoDB Repository  
> baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.0/x86_64/  
> gpgcheck=1  
> enabled=1  
> gpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc

```bash
yum install mongodb-org -y
```

删除 mongodb.repo

```bash
rm -f /etc/yum.repos.d/mongodb.repo
```

开启远程访问

```bash
vim /etc/mongod.conf
```

把 BindIp:127.0.0.1 改为 BindIp:0.0.0.0

开放 MongoDB 默认端口,设置开机启动，关闭 SELinux

```bash
firewall-cmd --zone=public --add-port=27017/tcp --permanent
firewall-cmd --reload
systemctl enable mongod
systemctl start mongod
setenforce 0
```



### Replica Set 副本集设置

主节点 ( Primary ) : 副本集唯一节点，支持读写，写入操作一般在 oplog 中

从节点 ( Secondary ) : 数据节点，拥有和主节点一样的数据副本，一般情况下只读。从主节点的 oplog 同步数据，不可参与投票。

```bash
mkdir /home/data
mkdir /home/data/db
touch /home/data/mongodb.log
chown -R mongod:mongod /home/data
```

修改 /etc/hosts ，添加如下内容

> 192.168.1.100 mongo1
>
> 192.168.1.101 mongo2
>
> 192.168.1.103 mongo3

#### 节点认证

产生 key 文件并给予正确的权限

```bash
openssl rand -base64 555 > /home/data/mongo-keyfile
chown mongod:mongod /home/data/mongo-keyfile
chmod 400 /home/data/mongo-keyfile
```



#### 创建 admin 用户

登陆打算设定为 Primary 的 MongoDB 节点，进入 admin 数据库，创建有 root 权限的用户。

```bash
use admin
db.createUser({user: "mongo-admin", pwd: "password", roles:[{role: "root", db: "admin"}]})
```



#### 配置 MongoDB

修改副本集每个节点的 /etc/mongod.conf

> ```:
> systemLog:
>   destination: file
>   logAppend: true
>   path: /home/data/mongodb.log
>   
> storage:
>   dbPath: /home/data/db
>   journal:
>     enabled: true
>     
> processManagement:
>   fork: true  # fork and run in background
>   pidFilePath: /var/run/mongodb/mongod.pid  # location of pidfile
>   timeZoneInfo: /usr/share/zoneinfo
> net:
>    port: 27017
>    bindIp: 0.0.0.0 
> security:
>    keyFile: /home/data/mongo-keyfile
> replication:  
>    replSetName: yuan
> ```

指定 key 文件，replication set 名称等

重启 MongoDB

```bash
systemctl restart mongodb
```

#### 启动集群，添加节点

使用之前在主节点创建的用户名进行登录

```bash
mongo -u mongo-admin -p --authenticationDatabase admin
```

初始化集群添加节点

```bash
rs.initiate()
rs.add("mongo2")
rs.add("mongo3")
```

使用 rs.conf() 或者 rs.status() 验证集群配置和状态
