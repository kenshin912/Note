## Kubernetes Cluster deployed by kubeadm on Ubuntu 20.04 LTS

| Server Name | IP Address    | Role                   |
| ----------- | ------------- | ---------------------- |
| K1          | 192.168.1.230 | Master , Control-plane |
| K2          | 192.168.1.231 | Worker1                |
| K3          | 192.168.1.232 | Worker2                |
| K4          | 192.168.1.233 | Worker3                |
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

vim kube-flannel.yml # 找到 "--kube-subnet-mgr" , 再其下方增加 "- --iface-regex=eth*|en*" (网卡名称的正则)

kubectl apply -f ./kube-flannel.yml

```

> ⚠️ 注意 , 阿里云 registry 并不总是可用 , 如果发现使用阿里云 registry 也无法初始化成功 ,且你在该内网有一个透明代理 , 可以将网关指向该透明代理 , 并删除指定 image repository . 没有透明代理的话 , 那就唱一句: 听我说 , 谢谢你~
>



#### Docker 连接私有仓库

修改 /etc/docker/daemon.json 添加如下配置

```json
"insecure-registries": ["http://192.168.1.235"]
```

重启 Docker



#### Containerd 连接私有仓库

创建 Containerd 配置文件

```bash
sudo mkdir /etc/containerd
sudo touch /etc/containerd/config.toml
sudo chown ubuntu:ubuntu /etc/containerd/config.toml
containerd config default >> /etc/containerd/config.toml
```

修改配置文件 , 修改成如下内容.

```toml
[plugins."io.containerd.grpc.v1.cri".registry]
      config_path = ""
      [plugins."io.containerd.grpc.v1.cri".registry.auths]
      [plugins."io.containerd.grpc.v1.cri".registry.configs]
        [plugins."io.containerd.grpc.v1.cri".registry.configs."192.168.1.235".tls]
          insecure_skip_verify = true #跳过证书认证
        [plugins."io.containerd.grpc.v1.cri".registry.configs."192.168.1.235".auth]
          username = "admin"
          password = "password"
      [plugins."io.containerd.grpc.v1.cri".registry.headers]
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."192.168.1.235"]
          endpoint = ["http://192.168.1.235"]
    [plugins."io.containerd.grpc.v1.cri".x509_key_pair_streaming]
```

重启 Containerd 服务

```bash
sudo systemctl restart containerd.service
```



#### Crictl 命令报错

由于 Kubernetes 不再使用 docker , 我们如何查看主机上运行的容器呢 ? 我们可以使用 `crictl` 命令. 所以我们试试看.

```bash
yuan@k1:~$ crictl ps
FATA[0010] failed to connect: failed to connect: context deadline exceeded
```

Not working ! 它默认去尝试连接 Docker 了 , 更准确的说 , 是去连接套接字 `/var/run/dockershim.sock` 了

我们可以创建一个 containerd 配置文件来解决.

```bash
sudo tee /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 2
debug: false
EOF
```

接着再尝试一下.

```bash
yuan@k1:~$ sudo crictl ps
CONTAINER           IMAGE               CREATED             STATE               NAME                      ATTEMPT             POD ID
bc1e666e11595       a4ca41631cc7a       30 hours ago        Running             coredns                   0                   7cb6a897a9bf5
04b659bcac1de       a4ca41631cc7a       30 hours ago        Running             coredns                   0                   0ef2bf3cd3645
48b23bbf3f6ef       9247abf086779       30 hours ago        Running             kube-flannel              1                   ad54fad8af5ba
f25a2fa039280       77b49675beae1       30 hours ago        Running             kube-proxy                1                   3492b3df36add
ebf31e031a22a       e3ed7dee73e93       30 hours ago        Running             kube-scheduler            1                   9699239b72f34
1db17bf270989       529072250ccc6       30 hours ago        Running             kube-apiserver            1                   0fd527f0a3cc3
1644f3532effe       88784fb4ac2f6       30 hours ago        Running             kube-controller-manager   1                   976b93e9fcda6
0e40c53132c92       aebe758cef4cd       30 hours ago        Running             etcd                      1                   ec31fb7b214b2
yuan@k1:~$
```

查看镜像

```bash
yuan@k1:~$ sudo crictl images
IMAGE                                                             TAG                 IMAGE ID            SIZE
192.168.1.235/invincible/website                                  <none>              89c44430b527d       18.7MB
docker.io/rancher/mirrored-flannelcni-flannel-cni-plugin          v1.0.1              ac40ce6257406       3.82MB
docker.io/rancher/mirrored-flannelcni-flannel                     v0.17.0             9247abf086779       19.9MB
k8s.gcr.io/coredns/coredns                                        v1.8.6              a4ca41631cc7a       13.6MB
registry.aliyuncs.com/google_containers/coredns                   v1.8.6              a4ca41631cc7a       13.6MB
k8s.gcr.io/etcd                                                   3.5.3-0             aebe758cef4cd       102MB
registry.aliyuncs.com/google_containers/etcd                      3.5.3-0             aebe758cef4cd       102MB
k8s.gcr.io/kube-apiserver                                         v1.24.0             529072250ccc6       33.8MB
registry.aliyuncs.com/google_containers/kube-apiserver            v1.24.0             529072250ccc6       33.8MB
k8s.gcr.io/kube-controller-manager                                v1.24.0             88784fb4ac2f6       31MB
registry.aliyuncs.com/google_containers/kube-controller-manager   v1.24.0             88784fb4ac2f6       31MB
k8s.gcr.io/kube-proxy                                             v1.24.0             77b49675beae1       39.5MB
registry.aliyuncs.com/google_containers/kube-proxy                v1.24.0             77b49675beae1       39.5MB
k8s.gcr.io/kube-scheduler                                         v1.24.0             e3ed7dee73e93       15.5MB
registry.aliyuncs.com/google_containers/kube-scheduler            v1.24.0             e3ed7dee73e93       15.5MB
k8s.gcr.io/pause                                                  3.5                 ed210e3e4a5ba       301kB
k8s.gcr.io/pause                                                  3.7                 221177c6082a8       311kB
registry.aliyuncs.com/google_containers/pause                     3.7                 221177c6082a8       311kB
yuan@k1:~$
```



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



