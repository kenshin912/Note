## 修改 Docker 容器端口映射

### Stop container

### Stop docker service

```bash
systemctl stop docker.service
```

### Modify hostconfig.json file

``` bash
cd /var/lib/docker/3b6ef264a040* # Container ID
vim hostconfig.json

# find this -> "PortBindings":{}
# change this PortBindings like the following code

"PortBindings":{"3306/tcp":[{"HostIp":"","HostPort":"3307"}]}

```

 ### Start docker service

