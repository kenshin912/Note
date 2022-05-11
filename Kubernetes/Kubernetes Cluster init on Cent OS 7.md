# Kubernetes Cluster init on Cent OS 7

## Prepare Cent OS 7

```bash
systemctl stop firewalld.service

swapoff -a

yum install wget -y

wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

yum clean all

yum makecache

vim /etc/fstab
```

shutdown swap

```bash
cat /etc/fstab

/dev/mapper/cl-root     /                       xfs     defaults        0 0
UUID=5fecb240-379b-4331-ba04-f41338e81a6e /boot                   ext4    defaults        1 2
/dev/mapper/cl-home     /home                   xfs     defaults        0 0
#/dev/mapper/cl-swap     swap                    swap    defaults        0 0
```

```bash
vim /etc/sysctl.d/k8s.conf

net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
```

```bash
sysctl --system
```


## Install something useful & Docker-ce

```bash
yum install bash-completion net-tools gcc yum-utils device-mapper-persistent-data lvm2 -y

yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

yum install docker-ce -y
```

## Install kubectl , kubelet , kubeadm

```bash
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

```bash
yum install kubectl kubelet kubeadm -y

systemctl enable --now kubelet

kubeadm init --kubernetes-version=1.22.1 --apiserver-advertise-address=192.168.1.181 --service-cidr=10.10.0.0/16 --pod-network-cidr=10.100.0.0/16
```

POD CIDR: 10.122.0.0/16， apiserver's Address is master's IP Address itself.

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

source <(kubectl completion bash)
```

```bash
[root@kube1 ~]# kubectl get node
NAME            STATUS     ROLES    AGE   VERSION
kube2           NotReady   <none>   17m   v1.19.3
kube1           NotReady   master   52m   v1.19.3

[root@kube1 ~]# kubectl get pod --all-namespaces
NAMESPACE     NAME                            READY   STATUS    RESTARTS   AGE
kube-system   coredns-6d56c8448f-6xrgn        0/1     Pending   0          52m
kube-system   coredns-6d56c8448f-f5fsb        0/1     Pending   0          52m
kube-system   etcd-kube1                      1/1     Running   0          52m
kube-system   kube-apiserver-kube1            1/1     Running   0          52m
kube-system   kube-controller-manager-kube1   1/1     Running   0          52m
kube-system   kube-proxy-4znz9                1/1     Running   0          52m
kube-system   kube-proxy-r5qlq                1/1     Running   0          17m
kube-system   kube-scheduler-kube1            1/1     Running   0          52m

```

NotReady on kube2 node , because corednspod isn't running, miss pod network.

## Install calico network

```bash
[root@kube1 ~]# kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
configmap/calico-config created
customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/bgppeers.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/blockaffinities.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/clusterinformations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworksets.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/hostendpoints.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamblocks.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamconfigs.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamhandles.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ippools.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/kubecontrollersconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networksets.crd.projectcalico.org created
clusterrole.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrolebinding.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrole.rbac.authorization.k8s.io/calico-node created
clusterrolebinding.rbac.authorization.k8s.io/calico-node created
daemonset.apps/calico-node created
serviceaccount/calico-node created
deployment.apps/calico-kube-controllers created
serviceaccount/calico-kube-controllers created
```

Wait for some minutes.

```bash
[root@kube1 ~]# kubectl get pod --all-namespaces
NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-5c6f6b67db-mkznr   1/1     Running   0          6m48s
kube-system   calico-node-4q986                          1/1     Running   0          6m48s
kube-system   calico-node-x48w7                          1/1     Running   0          6m48s
kube-system   coredns-6d56c8448f-6xrgn                   1/1     Running   0          65m
kube-system   coredns-6d56c8448f-f5fsb                   1/1     Running   0          65m
kube-system   etcd-kube1                                 1/1     Running   0          66m
kube-system   kube-apiserver-kube1                       1/1     Running   0          66m
kube-system   kube-controller-manager-kube1              1/1     Running   0          66m
kube-system   kube-proxy-4znz9                           1/1     Running   0          65m
kube-system   kube-proxy-r5qlq                           1/1     Running   0          31m
kube-system   kube-scheduler-kube1                       1/1     Running   0          66m

[root@kube1 ~]# kubectl get node
NAME            STATUS   ROLES    AGE   VERSION
kube2           Ready    <none>   32m   v1.19.3
kube1           Ready    master   66m   v1.19.3
```

## Install kubernetes-dashboard

```bash
wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc7/aio/deploy/recommended.yaml

[root@kube1 ~]# vim recommended.yaml
kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  type: NodePort
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 30000
  selector:
    k8s-app: kubernetes-dashboard

[root@kube1 ~]# kubectl create -f recommended.yaml
namespace/kubernetes-dashboard created
serviceaccount/kubernetes-dashboard created
service/kubernetes-dashboard created
secret/kubernetes-dashboard-certs created
secret/kubernetes-dashboard-csrf created
secret/kubernetes-dashboard-key-holder created
configmap/kubernetes-dashboard-settings created
role.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrole.rbac.authorization.k8s.io/kubernetes-dashboard created
rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
deployment.apps/kubernetes-dashboard created
service/dashboard-metrics-scraper created
deployment.apps/dashboard-metrics-scraper created
[root@kube1 ~]# kubectl get svc -n kubernetes-dashboard
NAME                        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)         AGE
dashboard-metrics-scraper   ClusterIP   10.10.222.66    <none>        8000/TCP        34s
kubernetes-dashboard        NodePort    10.10.227.218   <none>        443:30000/TCP   34s
```