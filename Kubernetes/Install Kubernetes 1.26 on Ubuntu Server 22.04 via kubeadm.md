### Install Kubernetes 1.26 on Ubuntu Server 22.04 via kubeadm

>   ⚠️ The following commands of this article are **Only work without GreatFirewall of China** 
>
>   ⚠️ 本文档的安装步骤及命令**仅适用于不受防火长城**限制的情况下.



##### Configure host names and machine ids.

If you have created the virtual machines with cloning , then you have to **make sure that its machine have a unique machine id**

```bash
sudo hostnamectl set-hostname k1.kubernetes.lab
sudo rm -rf /etc/machine-id
sudo dbus-uuidgen --ensure=/etc/machine-id
```

And update the entries in `/etc/hosts` in every node.

```bash
sudo tee /etc/hosts<<EOF
192.168.1.221 k1
192.168.1.222 k2
192.168.1.223 k3
EOF
```

>   Obviously you have to replace the hostnames and IP addresses with the ones of yours.
>
>   Remember that you need to set the **Static** IP addresses.

Restart **all** the machines.

```bash
sudo reboot
```

 

------

Perform the following steps **on every node**

##### Update Ubuntu

```bash
sudo apt update -y
sudo apt upgrade -y
```

##### Calibrate system time

```bash
sudo apt install ntpdate -y
sudo ntpdate ntp.aliyun.com
sudo timedatectl set-timezone Asia/Shanghai
```

##### Disable swap

```bash
sudo sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab
sudo swapoff -a
sudo reboot
```

##### Add Kubernetes repositories

```bash
sudo apt-get install apt-transport-https ca-certificates curl -y
curl -fsSL  https://packages.cloud.google.com/apt/doc/apt-key.gpg|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/k8s.gpg
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update -y
```

##### Install Kubernetes tools

```bash
sudo apt install kubelet kubeadm kubectl kubernetes-cni -y
sudo apt-mark hold kubelet kubeadm kubectl
kubectl version --client && kubeadm version
```

##### Load Kernel modules & settings

Add the following Kernel modules

```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

Set the following Kernel parameters

```bash
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
```

Reload the changes to take effect

```bash
sudo sysctl --system
```

##### Install Containerd

```bash
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update -y
sudo mkdir -p /etc/apt/keyrings
sudo apt remove containerd 
sudo apt update
sudo apt install containerd.io -y
```

##### Configure containerd and start service

```bash
# Configure containerd and start service
sudo su -
mkdir -p /etc/containerd
containerd config default>/etc/containerd/config.toml
```

##### Modify Containerd config file

```bash
sudo vim  /etc/containerd/config.toml
```

To use the systemd cgroup driver, set **plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options** `SystemdCgroup = true` in `/etc/containerd/config.toml`. When using kubeadm, manually configure the cgroup driver for kubelet

```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          base_runtime_spec = ""
          cni_conf_dir = ""
          cni_max_conf_num = 0
          container_annotations = []
          pod_annotations = []
          privileged_without_host_devices = false
          runtime_engine = ""
          runtime_path = ""
          runtime_root = ""
          runtime_type = "io.containerd.runc.v2"
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            BinaryName = ""
            CriuImagePath = ""
            CriuPath = ""
            CriuWorkPath = ""
            IoGid = 0
            IoUid = 0
            NoNewKeyring = false
            NoPivotRoot = false
            Root = ""
            ShimCgroup = ""
            SystemdCgroup = true # Change the value to "true"
```

##### Restart Containerd

```bash
sudo systemctl daemon-reload
sudo systemctl restart containerd
```

##### Initialize the cluster with kubeadm

Make sure `kubelet` daemon is enabled

```bash
sudo systemctl enable kubelet
```

And then pull the images & initialize the cluster

```bash
sudo kubeadm config images pull --cri-socket /run/containerd/containerd.sock
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --cri-socket /run/containerd/containerd.sock --control-plane-endpoint=k1
```

>   The CIDR **10.244.0.0/16** is **the default one that is used form flannel**

##### Configure kubectl

```bash
sudo mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

##### Apply flannel

```bash
wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml  # Download Flannel
vim kube-flannel.yml # Find "--kube-subnet-mgr" , Add the following line "- --iface-regex=eth*|en*"
kubectl apply -f ./kube-flannel.yml
```

