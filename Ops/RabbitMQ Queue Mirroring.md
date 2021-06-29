# RabbitMQ Queue Mirroring

## Environment

RabbitMQ Version : 3.8.7

Erlang Version : 23.0

## Server Information

|   Hostname    |   OS Version  |   IP Addr   |     Remark     |
|:-------------:|:-------------:|:-----------:|:--------------:|
|   node1       |   Cent OS 7.9 | 172.16.7.7  |     Disk Node  |
|   node2       |   Cent OS 7.9 | 172.16.7.8  |     RAM Node   |
|   node3       |   Cent OS 7.9 | 172.16.7.9  |     RAM Node   |

## Hosts setting

```
172.16.7.7  node1
172.16.7.8  node2
172.16.7.9  node3
```

## Software Install

### Erlang
```
wget https://github.com/rabbitmq/erlang-rpm/releases/download/v23.0/erlang-23.0-1.el7.x86_64.rpm

yum localinstall erlang-23.0-1.el7.x86_64.rpm
```

### RabbitMQ

```
wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.8.7/rabbitmq-server-3.8.7-1.el7.noarch.rpm

yum localinstall rabbitmq-server-3.8.7-1.el7.noarch.rpm

systemctl enable rabbitmq-server

systemctl start rabbitmq-server

systemctl status rabbitmq-server
```

## Create Cluster

### Share .erlang.cookie
```
[root@node1 ~]# scp /var/lib/rabbitmq/.erlang.cookie root@node2:/var/lib/rabbitmq/

[root@node1 ~]# scp /var/lib/rabbitmq/.erlang.cookie root@node3:/var/lib/rabbitmq/

[root@node2 ~]# chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie

[root@node3 ~]# chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
```

### Join Cluster

```
[root@node1 ~]# rabbitmqctl cluster_status

# Stop rabbitmq-server on node2

[root@node2 ~]# rabbitmqctl stop_app

[root@node2 ~]# rabbitmqctl reset

# Join Cluster 

[root@node2 ~]# rabbitmqctl join_cluster --ram rabbit@node1

[root@node2 ~]# rabbitmqctl start_app


# Do the same on Node3

[root@node3 ~]# rabbitmqctl stop_app

[root@node3 ~]# rabbitmqctl reset

[root@node3 ~]# rabbitmqctl join_cluster --ram rabbit@node1

[root@node3 ~]# rabbitmqctl start_app

```

## Verify cluster status

```
[root@node1 ~]# rabbitmqctl cluster_status
```

## Setting RabbitMQ to Queue Mirroring

```
[root@node1 ~]# rabbitmqctl set_policy ha-all "^" '{"ha-mode":"all"}'
```