## Kubernetes 1.23.0 deployed by kubeadm manual

### 部署环境

| IP Address    | Hostname   | Remark |
| ------------- | ---------- | ------ |
| 192.168.1.181 | K8s-master | 主节点 |
| 192.168.1.182 | K8s-node1  |        |
| 192.168.1.183 | K8s-node2  |        |



### 准备开始

* 每台机器 2GB RAM 或更多
* 2 核心 CPU 或更多
* 集群中的所有机器的网络彼此均能相互连接(公网和内网都可以)
* 节点之中不可以有重复的主机名、MAC 地址或 product_uuid。请参见[这里](https://kubernetes.io/zh/docs/setup/production-environment/tools/_print/#verify-mac-address)了解更多详细信息。
* 启机器上的某些端口。请参见[这里](https://kubernetes.io/zh/docs/setup/production-environment/tools/_print/#check-required-ports) 了解更多详细信息。
* 禁用交换分区。为了保证 kubelet 正常工作，你 **必须** 禁用交换分区。



#### 确保每个节点上的 MAC 地址和 product_uuid 的唯一性

* 你可以使用命令 `ip link` 或 `ifconfig -a` 来获取网络接口的 MAC 地址
* 可以使用 `sudo cat /sys/class/dmi/id/product_uuid` 命令对 product_uuid 校验

一般来讲，硬件设备会拥有唯一的地址，但是有些虚拟机的地址可能会重复。 Kubernetes 使用这些值来唯一确定集群中的节点。

 如果这些值在每个节点上不唯一，可能会导致安装 [失败](https://github.com/kubernetes/kubeadm/issues/31)。



#### 允许 iptables 检查桥接流量 (所有节点)

确保 `br_netfilter` 模块被加载。这一操作可以通过运行 `lsmod | grep br_netfilter` 来完成。若要显式加载该模块，可执行 `sudo modprobe br_netfilter`。

为了让你的 Linux 节点上的 iptables 能够正确地查看桥接流量，你需要确保在你的 `sysctl` 配置中将 `net.bridge.bridge-nf-call-iptables` 设置为 1。

```bash
yum update -y

yum install ntp -y

ntpdate ntp.aliyun.com && hwclock -w #从阿里云 NTP 服务器同步时间

swapoff -a # 禁用交换分区

vim /etc/fstab # 注释掉带有 "swap" 的这一行
#/dev/mapper/centos-swap swap                    swap    defaults        0 0

systemctl stop firewalld && systemctl disable firewalld # 关闭防火墙

setenforce 0 && sed -i ‘s/^SELINUX=enforcing$/SELINUX=permissive/’ /etc/selinux/config

vim /etc/hosts
192.168.1.181		k8s-master
192.168.1.182		k8s-node1
192.168.1.183		k8s-node2

hostnamectl set-hostname k8s-master

# 允许 iptables 检查桥接流量
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system

modprobe br_netfilter

reboot

```



### 安装 Runtime (所有节点)

```bash
yum install bash-completion net-tools yum-utils device-mapper-persistent-data lvm2 -y

yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

由于 Kubernetes 与 Docker 默认的 cgroup ( 资源控制组 ) 驱动程序并不一致，Kubernetes 默认为 `systemd`，而 Docker 默认为 `cgroupfs`。

在这里我们要修改 Docker 或者 Kubernetes 其中一个的 cgroup 驱动，以便两者统一。根据官方文档《[CRI installation](https://kubernetes.io/docs/setup/cri/)》中的建议，对于使用 systemd 作为引导系统的 Linux 的发行版，使用 systemd 作为 Docker 的 cgroup 驱动程序可以服务器节点在资源紧张的情况表现得更为稳定。

这里选择修改各个节点上 Docker 的 cgroup 驱动为 `systemd`，具体操作为编辑(无则新增) `/etc/docker/daemon.json`文件，加入以下内容即可：

```bash
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "registry-mirrors": ["https://ud6340vz.mirror.aliyuncs.com"]
}
```

然后重新启动 Docker

```bash
systemctl daemon-reload

systemctl restart docker
```

> ⚠️ 注意 : 当 Linux Kernel 的版本高于 4.0 , 或者 RHEL / Cent OS 的 Kernel 版本高于 `3.10.0-514` 时，overlay2 的存储驱动是 RHEL / CentOS 操作系统优选的存储驱动。 



### 使用部署工具 ( Deployment Tools ) 安装 Kubernetes (所有节点)

> 注，官网介绍了 3 种部署工具部署 K8S
> 1 是使用 kubeadm 部署自举式集群 (本部署使用)
> 2 是使用 kops 安装在 AWS 上安装 K8S 集群
> 3 是使用 kubespray 将 K8S 部署在 GCE (谷歌云) , Azure (微软云) , OpenStack (私有云) ,  AWS (亚马逊云) , vSphere (VMware vSphere) , Packet (bare metal)(裸金属服务器), Oracle Cloud Infrastructure (Experimental) (甲骨文云基础设施) 上的。



> ⚠️ 注意 : 默认安装 Kubernetes 需要从 gcr.io 拉取镜像 ，该地址无法在中国大陆地区直接访问。



添加 Kubernetes 安装源

```bash
cat <<EOF > sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

安装 kubeadm , kubelet , kubectl ( 所有节点都安装 , 其中 kubectl 在 Worker 节点可选安装 )

```bash
yum install kubelet kubeadm kubectl -y && systemctl enable --now kubelet
```

开机自动启动 docker

```bash
systemctl enable docker
systemctl start docker
```



#### 创建集群

##### 初始化集群 ( 主节点 )

```
kubeadm init --image-repository=registry.aliyuncs.com/google_containers --pod-network-cidr=10.244.0.0/16
```

##### 初始化参数解析

| **选项**                                       | **意义**                                                     |
| ---------------------------------------------- | ------------------------------------------------------------ |
| --kubernetes-version=1.22.1                    | 指明需要初始化的kubernetes的版本,默认值为stable-1            |
| --apiserver-advertise-address=192.168.1.181    | Master 服务器的 API 对外监听的 IP , 如有多个 IP , 可以指明一下 IP , 以示明确 |
| –control-plane-endpoint=cluster-endpoint.xx.cn | Master 高可用时用到的                                        |
| --service-cidr=10.10.0.0/16                    | Service 的 IP 地址分配段                                     |
| --pod-network-cidr=10.100.0.0/16               | Pod 的 IP 地址分配段                                         |
| service-dns-domain=xx.cn                       | Service 的域名设置，默认是 cluster.local, 企业内部通常会更改 |
| –upload-certs                                  | 用于新建master集群的时候直接在master之间共享证书             |



> ⚠️ 注意: 在Master初始化完成后，在最后的输出中，会提示如何加入 worker 节点



如果你是普通用户 , 为当前用户生成 kubeconfig

```bash
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

如果你是 root 用户

```bash
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile
export KUBECONFIG=/etc/kubernetes/admin.conf
source <(kubectl completion bash)
```



##### 其他节点加入集群 (Node 节点)

```bash
[root@k8s-node1 ~]# kubeadm join 192.168.1.181:6443 --token ydnah6.obrphugsubbgvtcl --discovery-token-ca-cert-hash sha256:5e926ff217b33d9d78f01ca73ecee98012765b23947b021f5a2ab6443c8f0cd9
[preflight] Running pre-flight checks
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.

[root@k8s-node1 ~]#
```

```bash
[root@k8s-node2 ~]# kubeadm join 192.168.1.181:6443 --token ydnah6.obrphugsubbgvtcl --discovery-token-ca-cert-hash sha256:5e926ff217b33d9d78f01ca73ecee98012765b23947b021f5a2ab6443c8f0cd9
[preflight] Running pre-flight checks
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.

[root@k8s-node2 ~]#
```

> ⚠️ 注意: 加入集群的命令 , token 的有效期为 24 小时 , 如果超时 , 可以使用如下命令重新获取

```bash
kubeadm token create --print-join-command
```



启用 kubectl 命令自动补全功能

```bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'source /usr/share/bash-completion/bash_completion' >> ~/.bashrc
```

安装网络插件，否则 node 是 NotReady 状态（主节点)

```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

