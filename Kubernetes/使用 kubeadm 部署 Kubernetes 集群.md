## 使用 kubeadm 部署 Kubernetes 集群

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

yum install docker-ce -y

systemctl enable docker.service

systemctl start docker.service
```

由于 Kubernetes 与 Docker 默认的 cgroup ( 资源控制组 ) 驱动程序并不一致，Kubernetes 默认为 `systemd`，而 Docker 默认为 `cgroupfs`。

在这里我们要修改 Docker 或者 Kubernetes 其中一个的 cgroup 驱动，以便两者统一。根据官方文档《[CRI installation](https://kubernetes.io/docs/setup/cri/)》中的建议，对于使用 systemd 作为引导系统的 Linux 的发行版，使用 systemd 作为 Docker 的 cgroup 驱动程序可以服务器节点在资源紧张的情况表现得更为稳定。

这里选择修改各个节点上 Docker 的 cgroup 驱动为 `systemd`，具体操作为编辑(无则新增) `/etc/docker/daemon.json`文件，加入以下内容即可：

```bash
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
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



使用清华大学镜像站配置 yum 源

```bash
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes-TUNA]
name=Kubernetes-TUNA
baseurl=https://mirrors.tuna.tsinghua.edu.cn/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
EOF
```

安装 kubeadm , kubelet , kubectl ( 所有节点都安装 , 其中 kubectl 在 Worker 节点可选安装 )

```bash
yum install kubelet kubeadm kubectl -y && systemctl enable --now kubelet
```



#### 创建集群

预拉取镜像 ( 所有节点 )

> ⚠️ 注意 : 预拉取镜像不是必须的 ,  如果你的服务器所在地不在中国大陆地区内 , 可以不必预拉取镜像。
>
> ⚠️ 注意: 实测通过设置 http_proxy / https_proxy 代理的方式拉取镜像是不可行的。



使用命令查询当前版本需要哪些镜像:

```bash
[root@k8s-master ~]# kubeadm config images list
k8s.gcr.io/kube-apiserver:v1.22.1
k8s.gcr.io/kube-controller-manager:v1.22.1
k8s.gcr.io/kube-scheduler:v1.22.1
k8s.gcr.io/kube-proxy:v1.22.1
k8s.gcr.io/pause:3.5
k8s.gcr.io/etcd:3.5.0-0
k8s.gcr.io/coredns/coredns:v1.8.4
```



从 registry.aliyuncs.com/google_containers 拉取对应镜像

```bash
docker pull registry.aliyuncs.com/google_containers/kube-apiserver:v1.22.1
docker pull registry.aliyuncs.com/google_containers/kube-controller-manager:v1.22.1
docker pull registry.aliyuncs.com/google_containers/kube-scheduler:v1.22.1
docker pull registry.aliyuncs.com/google_containers/kube-proxy:v1.22.1
docker pull registry.aliyuncs.com/google_containers/pause:3.5
docker pull registry.aliyuncs.com/google_containers/etcd:3.5.0-0
docker pull registry.aliyuncs.com/google_containers/coredns:1.8.4
```

重新给镜像打 tag

```bash
docker tag registry.aliyuncs.com/google_containers/kube-apiserver:v1.22.1 k8s.gcr.io/kube-apiserver:v1.22.1
docker tag registry.aliyuncs.com/google_containers/kube-proxy:v1.22.1 k8s.gcr.io/kube-proxy:v1.22.1
docker tag registry.aliyuncs.com/google_containers/kube-controller-manager:v1.22.1 k8s.gcr.io/kube-controller-manager:v1.22.1
docker tag registry.aliyuncs.com/google_containers/kube-scheduler:v1.22.1 k8s.gcr.io/kube-scheduler:v1.22.1
docker tag registry.aliyuncs.com/google_containers/etcd:3.5.0-0 k8s.gcr.io/etcd:3.5.0-0
docker tag registry.aliyuncs.com/google_containers/coredns:1.8.4 k8s.gcr.io/coredns/coredns:v1.8.4
docker tag registry.aliyuncs.com/google_containers/pause:3.5 k8s.gcr.io/pause:3.5
```

删除原先镜像名称

```bash
docker rmi registry.aliyuncs.com/google_containers/kube-apiserver1.22.1
docker rmi registry.aliyuncs.com/google_containers/kube-apiserver:v1.22.1
docker rmi registry.aliyuncs.com/google_containers/kube-proxy:v1.22.1
docker rmi registry.aliyuncs.com/google_containers/kube-controller-manager:v1.22.1
docker rmi registry.aliyuncs.com/google_containers/kube-scheduler:v1.22.1
docker rmi registry.aliyuncs.com/google_containers/etcd:3.5.0-0
docker rmi registry.aliyuncs.com/google_containers/coredns:1.8.4
docker rmi registry.aliyuncs.com/google_containers/pause:3.5
```



#### 初始化集群 ( 主节点 )

```bash
[root@k8s-master ~]# kubeadm init --kubernetes-version=1.22.1 --apiserver-advertise-address=192.168.1.181 --service-cidr=10.10.0.0/16 --pod-network-cidr=10.100.0.0/16
[init] Using Kubernetes version: v1.22.1
[preflight] Running pre-flight checks
	[WARNING Service-Kubelet]: kubelet service is not enabled, please run 'systemctl enable kubelet.service'
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [k8s-master kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.10.0.1 192.168.1.181]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [k8s-master localhost] and IPs [192.168.1.181 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [k8s-master localhost] and IPs [192.168.1.181 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[apiclient] All control plane components are healthy after 8.002953 seconds
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.22" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --upload-certs
[mark-control-plane] Marking the node k8s-master as control-plane by adding the labels: [node-role.kubernetes.io/master(deprecated) node-role.kubernetes.io/control-plane node.kubernetes.io/exclude-from-external-load-balancers]
[mark-control-plane] Marking the node k8s-master as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[bootstrap-token] Using token: ydnah6.obrphugsubbgvtcl
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.1.181:6443 --token ydnah6.obrphugsubbgvtcl \
	--discovery-token-ca-cert-hash sha256:5e926ff217b33d9d78f01ca73ecee98012765b23947b021f5a2ab6443c8f0cd9
[root@k8s-master ~]#
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



> ⚠️ 注意: 在Master初始化完成后，在最后的输出中，会提示如何加入其它的 Master，提示如何加入 worker 节点



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





#### 踩坑

如果只在主节点拉取镜像 , 在安装 Flannel / calico 这类 CNI 插件会出现问题 , 节点会显示 Not Ready 

```bash
[root@k8s-master ~]# kubectl get nodes
NAME         STATUS     ROLES                  AGE     VERSION
k8s-master   NotReady   control-plane,master   4m3s    v1.22.1
k8s-node1    NotReady   <none>                 2m32s   v1.22.1
k8s-node2    NotReady   <none>                 2m10s   v1.22.1
```

解决办法: 

```bash
[root@k8s-master ~]# kubectl get pods -n kube-system -o wide
NAME                                 READY   STATUS              RESTARTS   AGE     IP              NODE         NOMINATED NODE   READINESS GATES
coredns-78fcd69978-bkzkl             1/1     Running             0          9m53s   10.100.0.2      k8s-master   <none>           <none>
coredns-78fcd69978-q494j             1/1     Running             0          9m53s   10.100.0.3      k8s-master   <none>           <none>
etcd-k8s-master                      1/1     Running             0          10m     192.168.1.181   k8s-master   <none>           <none>
kube-apiserver-k8s-master            1/1     Running             0          10m     192.168.1.181   k8s-master   <none>           <none>
kube-controller-manager-k8s-master   1/1     Running             0          10m     192.168.1.181   k8s-master   <none>           <none>
kube-flannel-ds-68c8l                1/1     Running             0          4m32s   192.168.1.181   k8s-master   <none>           <none>
kube-flannel-ds-9v5t7                0/1     Init:0/1            0          4m32s   192.168.1.182   k8s-node1    <none>           <none>
kube-flannel-ds-qbggp                0/1     Init:0/1            0          4m32s   192.168.1.183   k8s-node2    <none>           <none>
kube-proxy-8txg9                     0/1     ContainerCreating   0          8m40s   192.168.1.182   k8s-node1    <none>           <none>
kube-proxy-ctjf4                     0/1     ContainerCreating   0          8m18s   192.168.1.183   k8s-node2    <none>           <none>
kube-proxy-fspqz                     1/1     Running             0          9m53s   192.168.1.181   k8s-master   <none>           <none>
kube-scheduler-k8s-master            1/1     Running             0          10m     192.168.1.181   k8s-master   <none>           <none>

[root@k8s-master ~]# kubectl describe pod kube-flannel-ds-9v5t7 -n kube-system
Name:                 kube-flannel-ds-9v5t7
Namespace:            kube-system
Priority:             2000001000
Priority Class Name:  system-node-critical
Node:                 k8s-node1/192.168.1.182
Start Time:           Tue, 24 Aug 2021 19:41:56 +0800
Labels:               app=flannel
                      controller-revision-hash=7fb8b954f9
                      pod-template-generation=1
                      tier=node
Annotations:          <none>
Status:               Pending
IP:                   192.168.1.182
IPs:
  IP:           192.168.1.182
Controlled By:  DaemonSet/kube-flannel-ds
Init Containers:
  install-cni:
    Container ID:
    Image:         quay.io/coreos/flannel:v0.14.0
    Image ID:
    Port:          <none>
    Host Port:     <none>
    Command:
      cp
    Args:
      -f
      /etc/kube-flannel/cni-conf.json
      /etc/cni/net.d/10-flannel.conflist
    State:          Waiting
      Reason:       PodInitializing
    Ready:          False
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /etc/cni/net.d from cni (rw)
      /etc/kube-flannel/ from flannel-cfg (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-cjzr5 (ro)
Containers:
  kube-flannel:
    Container ID:
    Image:         quay.io/coreos/flannel:v0.14.0
    Image ID:
    Port:          <none>
    Host Port:     <none>
    Command:
      /opt/bin/flanneld
    Args:
      --ip-masq
      --kube-subnet-mgr
    State:          Waiting
      Reason:       PodInitializing
    Ready:          False
    Restart Count:  0
    Limits:
      cpu:     100m
      memory:  50Mi
    Requests:
      cpu:     100m
      memory:  50Mi
    Environment:
      POD_NAME:       kube-flannel-ds-9v5t7 (v1:metadata.name)
      POD_NAMESPACE:  kube-system (v1:metadata.namespace)
    Mounts:
      /etc/kube-flannel/ from flannel-cfg (rw)
      /run/flannel from run (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-cjzr5 (ro)
Conditions:
  Type              Status
  Initialized       False
  Ready             False
  ContainersReady   False
  PodScheduled      True
Volumes:
  run:
    Type:          HostPath (bare host directory volume)
    Path:          /run/flannel
    HostPathType:
  cni:
    Type:          HostPath (bare host directory volume)
    Path:          /etc/cni/net.d
    HostPathType:
  flannel-cfg:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      kube-flannel-cfg
    Optional:  false
  kube-api-access-cjzr5:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 :NoSchedule op=Exists
                             node.kubernetes.io/disk-pressure:NoSchedule op=Exists
                             node.kubernetes.io/memory-pressure:NoSchedule op=Exists
                             node.kubernetes.io/network-unavailable:NoSchedule op=Exists
                             node.kubernetes.io/not-ready:NoExecute op=Exists
                             node.kubernetes.io/pid-pressure:NoSchedule op=Exists
                             node.kubernetes.io/unreachable:NoExecute op=Exists
                             node.kubernetes.io/unschedulable:NoSchedule op=Exists
Events:
  Type     Reason                  Age                 From               Message
  ----     ------                  ----                ----               -------
  Normal   Scheduled               6m26s               default-scheduler  Successfully assigned kube-system/kube-flannel-ds-9v5t7 to k8s-node1
  Warning  FailedCreatePodSandBox  8s (x9 over 5m55s)  kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed pulling image "k8s.gcr.io/pause:3.5": Error response from daemon: Get "https://k8s.gcr.io/v2/": net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
```

第一条命令显示 node1 , node2 节点上 flannel 和 kube-proxy 没有正常运行起来。

后面的报错中可以看到 "failed pulling image k8s.grc.io/pasue:3.5" 这样的错误，这表示它无法访问该地址 。

所以 , **登录 node1 , node2 以后拉取对应镜像** , 稍等片刻再次 `kubectl get nodes` 即可看到:

```bash
[root@k8s-master ~]# kubectl get pods -n kube-system -o wide
NAME                                 READY   STATUS    RESTARTS   AGE   IP              NODE         NOMINATED NODE   READINESS GATES
coredns-78fcd69978-bkzkl             1/1     Running   0          46m   10.100.0.2      k8s-master   <none>           <none>
coredns-78fcd69978-q494j             1/1     Running   0          46m   10.100.0.3      k8s-master   <none>           <none>
etcd-k8s-master                      1/1     Running   0          47m   192.168.1.181   k8s-master   <none>           <none>
kube-apiserver-k8s-master            1/1     Running   0          47m   192.168.1.181   k8s-master   <none>           <none>
kube-controller-manager-k8s-master   1/1     Running   0          47m   192.168.1.181   k8s-master   <none>           <none>
kube-flannel-ds-68c8l                1/1     Running   0          41m   192.168.1.181   k8s-master   <none>           <none>
kube-flannel-ds-9v5t7                1/1     Running   0          41m   192.168.1.182   k8s-node1    <none>           <none>
kube-flannel-ds-qbggp                1/1     Running   0          41m   192.168.1.183   k8s-node2    <none>           <none>
kube-proxy-8txg9                     1/1     Running   0          45m   192.168.1.182   k8s-node1    <none>           <none>
kube-proxy-ctjf4                     1/1     Running   0          45m   192.168.1.183   k8s-node2    <none>           <none>
kube-proxy-fspqz                     1/1     Running   0          46m   192.168.1.181   k8s-master   <none>           <none>
kube-scheduler-k8s-master            1/1     Running   0          47m   192.168.1.181   k8s-master   <none>           <none>
[root@k8s-master ~]# kubectl get nodes
NAME         STATUS   ROLES                  AGE   VERSION
k8s-master   Ready    control-plane,master   47m   v1.22.1
k8s-node1    Ready    <none>                 45m   v1.22.1
k8s-node2    Ready    <none>                 45m   v1.22.1
[root@k8s-master ~]#
```

