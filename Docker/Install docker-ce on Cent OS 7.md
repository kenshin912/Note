### Install docker-ce on Cent OS 7

``` bash
yum update -y
yum install yum-utils -y
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
yum clean all
yum makecache fast
yum list docker-ce --showduplicates | sort -r
yum install docker-ce-20.10.8-3.el7 -y
systemctl enable docker
systemctl start docker
```

```bash
yum install bash-completion -y
source /usr/share/bash-completion/bash_completion
source /usr/share/bash-completion/completions/docker
```

