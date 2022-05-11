## Kubernetes Cluster deployed by kubeadm on Ubuntu 20.04 LTS

| Server Name | IP Address    | Role                   |
| ----------- | ------------- | ---------------------- |
| K1          | 192.168.1.230 | Master , Control-plane |
| K2          | 192.168.1.231 | Worker1                |
| K3          | 192.168.1.232 | Worker2                |
| Harbor      | 192.168.1.235 | Harbor                 |



#### Prepare

##### System Settings ( on all kubernetes cluster server )

```bash
sudo apt update -y && sudo apt upgrade -y

sudo apt install ntpdate -y

sudo ntpdate ntp.aliyun.com # 校准服务器时间

sudo timedatectl set-timezone Asia/Shanghai #设置为中国标准时间

sudo swapoff -a #关闭 Swap

sudo vim /etc/fstab # 注释带 Swap 的那一行

sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target # 如果是虚拟机 , 禁止 Sleep , suspend , etc

sudo modprobe br_netfilter # 加载内核模块 br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo sysctl --system

sudo vim /etc/sysctl.d/10-network-security.conf # net.ipv4.conf.default.rp_filter , net.ipv4.conf.all.rp_filter 的值从 2 修改为 1

sudo sysctl --system

sudo apt update && sudo apt install docker.io -y

sudo systemctl status docker

sudo vim /etc/docker/daemon.json # 添加如下内容
{
"exec-opts": ["native.cgroupdriver=systemd"]
}

sudo systemctl daemon-reload && sudo systemctl restart docker

sudo apt update && sudo apt install ca-certificates curl software-properties-common apt-transport-https -y

curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -

sudo tee /etc/apt/sources.list.d/kubernetes.list <<EOF 
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

sudo apt update -y && sudo apt install kubelet kubeadm kubectl -y && sudo apt-mark hold kubelet kubectl kubeadm
```



#### 初始化 Master 节点

```bash
sudo kubeadm init --image-repository=registry.aliyuncs.com/google_containers --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sudo chown $(id -u):$(id -g) $HOME/.kube/config

wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml # 使用 Flannel 网络插件

vim kube-flannel.yml # 找到 "--kube-subnet-mgr" , 再其下方增加 "- --iface=enp2s0(网卡名称)"

kubectl apply -f ./kube-flannel.yml

```





#### Harbor 部署

Harbor 是一个由 CNCF 托管的开源 Docker 镜像仓库管理工具. 我们使用它来作为内网 Kubernetes 集群的镜像仓库.

由于内网服务器不方便直接访问 GitHub , 我们使用离线安装的方式.

GitHub: https://github.com/goharbor/harbor/releases/tag/v2.4.2 , 选择 offline-installer 安装包下载并上传到服务器.

>  ⚠️ 该版本 Harbor 依赖 Docker & Docker-compose v1

```bash
tar zxvf harbor-online-installer-v2.4.2.tgz

cd harbor

cp harbor.yml.tmpl harbor.yml
```

修改 harbor.yml , 修改 hostname 并注释掉 https 部分.

```yaml
hostname: 192.168.1.235
http:
  port: 80
# https related config
#https:
  # https port for harbor, default is 443
  # port: 443
  # The path of cert and key files for nginx
  #certificate: /your/certificate/path
  #private_key: /your/private/key/path
harbor_admin_password: Harbor12345
```

执行安装

```bash
sudo bash install.sh
```



#### Docker 连接仓库

修改 /etc/docker/daemon.json 添加如下配置

```json
"insecure-registries": ["http://192.168.1.235"]
```

重启 Docker



#### 登录仓库并推送镜像

```bash
docker login http://192.168.1.235 --username Jaina --password ArthasPlzComeBack # 登录

docker tag a34820e87aca 192.168.1.235/invincible/website-manage:latest # 对镜像打 Tag

docker push 192.168.1.235/invincible/website-manage:latest # PUSH
The push refers to repository [192.168.1.235/invincible/website-manage]
eb355e194620: Pushed
1f52a8fb3649: Pushed
5f70bf18a086: Pushed
11e143a1f9bf: Mounted from invincible/jdk
b9039fa743bf: Mounted from invincible/jdk
7a694df0ad6c: Mounted from invincible/jdk
3fd9df553184: Mounted from invincible/jdk
805802706667: Mounted from invincible/jdk
latest: digest: sha256:17bdd205ca89ec834253a63cb8077f6a947b0de121ab8b9baa7ed2fbfe0c49a7 size: 1991
```

