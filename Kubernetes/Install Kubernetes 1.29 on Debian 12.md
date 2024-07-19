# Install Kubernetes 1.29 via kubeadm on Debian 12

## Set Hostname & Update /etc/hosts file

```bash
hostnamectl set-hostname "k0"
hostnamectl set-hostname "k1"
hostnamectl set-hostname "k2"
```

```bash
sudo vim /etc/hosts

192.168.1.230   k0
192.168.1.231   k1
192.168.1.232   k2
```

## Disable swap & AppArmor Service & Setting Time

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

sudo systemctl stop apparmor.service
sudo systemctl disable apparmor.service

sudo apt install ntpdate -y
sudo ntpdate ntp.aliyun.com
sudo timedatectl set-timezone Asia/Shanghai
```

## Optimize Kernel

```bash
cat > /etc/sysctl.d/kubernetes.conf << EOF
# 允许 IPv6 转发请求通过iptables进行处理（如果禁用防火墙或不是iptables，则该配置无效）
net.bridge.bridge-nf-call-ip6tables = 1

# 允许 IPv4 转发请求通过iptables进行处理（如果禁用防火墙或不是iptables，则该配置无效）
net.bridge.bridge-nf-call-iptables = 1

# 启用IPv4数据包的转发功能
net.ipv4.ip_forward = 1

# 禁用发送 ICMP 重定向消息
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# 提高 TCP 连接跟踪的最大数量
net.netfilter.nf_conntrack_max = 1000000

# 提高连接追踪表的超时时间
net.netfilter.nf_conntrack_tcp_timeout_established = 86400

# 提高监听队列大小
net.core.somaxconn = 1024

# 防止 SYN 攻击
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2

# 提高文件描述符限制
fs.file-max = 65536

# 设置虚拟内存交换（swap）的使用策略为0，减少对磁盘的频繁读写
vm.swappiness = 0
EOF

# 加载或启动内核模块 br_netfilter，该模块提供了网络桥接所需的网络过滤功能
modprobe br_netfilter

# 查看是否已成功加载模块
lsmod | grep br_netfilter

# 将读取该文件中的参数设置，并将其应用到系统的当前运行状态中
sysctl -p /etc/sysctl.d/kubernetes.conf
```

## Install ipvsadm & ipset

在 `Kubernetes` 中，`ipset` 和 `ipvsadm` 的用途：

`ipset` 主要用于支持 `Service` 的负载均衡和网络策略。它可以帮助实现高性能的数据包过滤和转发，以及对 IP 地址和端口进行快速匹配
`ipvsadm` 主要用于配置和管理 `IPVS` 负载均衡器，以实现 `Service` 的负载均衡

```bash
sudo apt install ipset ipvsadm -y

sudo dpkg -l ipset ipvsadm
```

## 内核模块配置

```bash
cat > /etc/modules-load.d/kubernetes.conf << EOF
# /etc/modules-load.d/kubernetes.conf

overlay

# Linux 网桥支持
br_netfilter

# IPVS 加载均衡器
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh

# IPv4 连接跟踪
nf_conntrack_ipv4

# IP 表规则
ip_tables
EOF

# 添加可执行权限
chmod a+x /etc/modules-load.d/kubernetes.conf

sudo modprobe overlay
sudo modprobe br_netfilter
sudo modprobe ip_vs
sudo modprobe ip_vs_rr
sudo modprobe ip_vs_wrr
sudo modprobe ip_vs_sh
```

## Install Containerd

```bash
wget https://github.com/containerd/containerd/releases/download/v1.7.18/cri-containerd-1.7.18-linux-amd64.tar.gz

sudo tar xf cri-containerd-1.7.18-linux-amd64.tar.gz -C /
```

## Configure config.toml

```bash
sudo mkdir /etc/containerd

sudo containerd config default > /etc/containerd/config.toml

sudo sed -i '/sandbox_image/s/3.8/3.9/' /etc/containerd/config.toml

sudo sed -i '/SystemdCgroup/s/false/true/' /etc/containerd/config.toml

sudo systemctl enable --now containerd.service

sudo systemctl status containerd.service

```

## Kubernetes cluster Install

### Install kubelet kubeadm kubectl

```bash
sudo apt install apt-transport-https ca-certificates curl gpg -y
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo mkdir -p -m 755 /etc/apt/keyrings
sudo apt update -y
sudo apt install kubelet kubeadm kubectl -y
sudo apt-mark hold kubelet kubeadm kubectl

```

### Initial Kubernetes cluster

```bash
sudo kubeadm config images pull

sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --cri-socket /run/containerd/containerd.sock --control-plane-endpoint=k0

mkdir -p $HOME/.kube

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Get pods and cluster info
kubectl get nodes -o wide

```

## Install Calico

### Install Tigera Calico operrator

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/tigera-operator.yaml

wget https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/custom-resources.yaml

# 修改 ip 池，需与初始化时一致
sed -i 's/192.168.0.0/10.244.0.0/' custom-resources.yaml

kubectl create -f custom-resources.yaml

# Show Calico status
kubectl get pods -n calico-system
```