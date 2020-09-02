# SSH Tunnel to Aliyun RDS

## Turn on ip forward

```bash
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

sysctl -p
```

## Establish SSH Tunnel

```bash
firewall-cmd --state

firewall-cmd --zone=public --add-port=3307/tcp --permanent

ssh -CfNg -L ${Local_Port}:${RDS_URL}:${RDS_PORT} ${ECS_USER}@${ESC_IP} -p${ECS_SSH_Port}
```

> INPUT ECS Password  

You can access Aliyun RDS via Local Port

## Bash Script

```bash
#/bin/bash
# C:压缩数据
# f:后台用户验证,这个选项很有用,没shell的不可登陆账号也能使用
# N:不执行脚本或命令
# G:允许远程主机连接转发端口
# Author: Yuan
# DATE  : 06/15/2020
# DESC  : Establish tunnels to Aliyun RDS / Redis services.
# USAGE : ./tunnel.sh rds  OR  ./tunnel.sh redis
# Run this script every 5 minutes by crontab to prevent tunnel disappear cause ip address change.
# */5 * * * * /root/tunnel.sh rds > /dev/null 2>&1

AliRDS=(172.16.159.25 3306)
AliREDIS=(172.16.68.144 6379)
AliMQ=(172.16.68.144 15672)
LocalRDSPort=3307
LocalREDISPort=6379
LocalMQPort=15672
RDSProxyServer=(121.196.60.28 22 Ubilin2019)
REDISProxyServer=(121.196.58.33 22 Ubilin2019)
MQProxyServer=(121.196.58.33 22 Ubilin2019)
ProxyServerUser=root

function ESTABLISH_TUNNEL() {
    >/dev/tcp/${5}/${6}
    if [ "$?" -eq "0" ];then
        STATUS=`ps aux | grep "ssh -CfNg -L ${1}" | grep -v "grep"`
        if [ -n "${STATUS}" ];then
            echo "Tunnel still alive now..."
            exit 1
        else
            expect -c "
            set timeout 5
            spawn ssh -CfNg -L ${1}:${2}:${3} ${4}@${5} -p${6}
            expect {
                \"*yes/no*\" {send \"yes\r\"; exp_continue}
                \"*password*\" {send \"${7}\r\";}
            }
            expect eof" > /dev/null 2>&1
        fi
    else
        echo "Could not connected to the Proxy Server!"
    fi
}

case ${1} in
    "rds" | "RDS" )
    ESTABLISH_TUNNEL ${LocalRDSPort} ${AliRDS[0]} ${AliRDS[1]} ${ProxyServerUser} ${RDSProxyServer[0]} ${RDSProxyServer[1]} ${RDSProxyServer[2]}
    ;;
    "redis" | "REDIS" )
    ESTABLISH_TUNNEL ${LocalREDISPort} ${AliREDIS[0]} ${AliREDIS[1]} ${ProxyServerUser} ${REDISProxyServer[0]} ${REDISProxyServer[1]} ${REDISProxyServer[2]}
    ;;
    "mq" | "MQ" )
    ESTABLISH_TUNNEL ${LocalMQPort} ${AliMQ[0]} ${AliMQ[1]} ${ProxyServerUser} ${MQProxyServer[0]} ${MQProxyServer[1]} ${MQProxyServer[2]}
    ;;
esac

exit 0
```
