# Docker Swarm INIT  

## 安全组操作

> 安全组内开放 `2377/tcp`,`4789/UDP`,`7946/TCP&UDP` 端口以保证可以顺利 Join.   [Use overlay networks](https://docs.docker.com/network/overlay/#create-an-overlay-network)  

```markdown
Firewall rules for Docker daemons using overlay networks

You need the following ports open to traffic to and from each Docker host participating on an overlay network:

TCP port 2377 for cluster management communications
TCP and UDP port 7946 for communication among nodes
UDP port 4789 for overlay network traffic

```

## ipv6 disabled

> \# vim /etc/sysctl.conf

Append on sysctl.conf

```bash
net.ipv4.ip_forward = 1
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
```

> \# sysctl -p  
> \# reboot

## Docker install

Install docker-ce on each node

```bash
yum update

curl https://download.docker.com/linux/centos/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo

yum install docker-ce
```

## Auto running when server startup

```bash
systemctl enable docker.service
```

## Initial Swarm Mode

On Swarm Leader  
> \$ sudo docker swarm init

On Swarm Node
> \$ sudo docker swarm join --token SWMTKN-1-36obhahlhhwfefcs46olwslzmcg0kogth2k7vs032e8iuvx3ep-19xqdp0htn8pqiq47qblo64ob 172.16.11.22:2377
