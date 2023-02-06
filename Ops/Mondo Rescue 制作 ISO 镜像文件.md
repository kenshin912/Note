### Mondo Rescue 制作 ISO 镜像文件

> For Cent OS 7 only 

##### Install Mondo Rescue

```bash
cd /etc/yum.repos.d

wget ftp://ftp.mondorescue.org/centos/7/x86_64/mondorescue.repo

vim mondorescue.repo

修改 gpgcheck=0

yum install mondo -y
```

##### Run

> 以 root 身份运行
    
```bash
mondoarchive
```
