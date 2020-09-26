## Install Docker on Cent OS 8

### Disable SELinux

> $ sudo setenforce 0

### Install docker-ce.repo

Cent OS 8 use `dnf` for package manage by default.

> $ dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo

Show available package list

> $ dnf list docker-ce --showduplicates

Install dependency `containerd.io` before install docker-ce , that is different with Cent OS 7.

> $ dnf install -y https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.13-3.2.el7.x86_64.rpm

Install Docker-ce

> $ dnf install -y --nobest docker-ce

Running Docker

> $ sudo systemctl enable docker.service

> $ sudo systemctl start docker.service

### Install docker-compose

Install docker-compose via pip3

> $ dnf install -y python3-pip

>$ pip3 install docker-compose


### firewalld settings

If firewalld service running, trust docker0 interface is required.

> $ firewall-cmd --zone=trusted --add-interface=docker0 --permanent

> $ firewall-cmd --zone=public --add-service=http --permanent

> $ firewall-cmd --zone=public --add-service=https --permanent

> $ firewall-cmd --zone=public --add-masquerade --permanent

> $ firewall-cmd --reload

> $ sudo systemctl restart docker.service
