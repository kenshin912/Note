### 编译 kubeadm 修改证书有效期



#### 基础环境准备

CentOS

```bash
yum install gcc make rsync jq -y
```

Ubuntu

```bash
sudo apt install build-essential rsync jq -y
```

查看 kubectl 版本

```bash
yuan@k1:~$ kubectl version
WARNING: This version information is deprecated and will be replaced with the output from kubectl version --short.  Use --output=yaml|json to get the full version.
Client Version: version.Info{Major:"1", Minor:"24", GitVersion:"v1.24.0", GitCommit:"4ce5a8954017644c5420bae81d72b09b735c21f0", GitTreeState:"clean", BuildDate:"2022-05-03T13:46:05Z", GoVersion:"go1.18.1", Compiler:"gc", Platform:"linux/amd64"}
Kustomize Version: v4.5.4
Server Version: version.Info{Major:"1", Minor:"24", GitVersion:"v1.24.0", GitCommit:"4ce5a8954017644c5420bae81d72b09b735c21f0", GitTreeState:"clean", BuildDate:"2022-05-03T13:38:19Z", GoVersion:"go1.18.1", Compiler:"gc", Platform:"linux/amd64"}
```

下载对应版本的源码

```bash
wget https://github.com/kubernetes/kubernetes/archive/refs/tags/v1.24.0.tar.gz
tar zxvf kubernetes-1.24.0.tar.gz
```

查看 kube-cross 的 Tag 版本号

```bash
yuan@k1:~$ cd kubernetes/
yuan@k1:~/kubernetes$ cat ./build/build-image/cross/VERSION
v1.24.0-go1.18.1-bullseye.0
yuan@k1:~/kubernetes$
```

安装 Go 环境

```bash
wget https://dl.google.com/go/go1.18.1.linux-amd64.tar.gz
tar zxvf go1.18.1.linux-amd64.tar.gz -C /usr/local
export PATH=$PATH:/usr/local/go/bin
```

验证 Go 环境是否正确安装

```bash
yuan@k1:~/kubernetes$ go version
go version go1.18.1 linux/amd64
yuan@k1:~/kubernetes$
```

编译 kubeadm

```bash
yuan@k1:~/kubernetes$ make all WHAT=cmd/kubeadm GOFLAGS=-v
```

备份 & 替换二进制文件

```bash
mv /usr/bin/kubeadm /home/backup/
cp _output/local/bin/linux/amd64/kubeadm /usr/bin/kubeadm
chmod +x /usr/bin/kubeadm
```

续订全部证书

```bash
yuan@k1:~/kubernetes$ sudo kubeadm certs renew all
```

再次查看证书有效期

```bash
yuan@k1:~/kubernetes$ sudo kubeadm certs check-expiration
[sudo] password for yuan:
[check-expiration] Reading configuration from the cluster...
[check-expiration] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'

CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Apr 17, 2122 05:50 UTC   99y             ca                      no
apiserver                  Apr 17, 2122 05:50 UTC   99y             ca                      no
apiserver-etcd-client      Apr 17, 2122 05:50 UTC   99y             etcd-ca                 no
apiserver-kubelet-client   Apr 17, 2122 05:50 UTC   99y             ca                      no
controller-manager.conf    Apr 17, 2122 05:50 UTC   99y             ca                      no
etcd-healthcheck-client    Apr 17, 2122 05:50 UTC   99y             etcd-ca                 no
etcd-peer                  Apr 17, 2122 05:50 UTC   99y             etcd-ca                 no
etcd-server                Apr 17, 2122 05:50 UTC   99y             etcd-ca                 no
front-proxy-client         Apr 17, 2122 05:50 UTC   99y             front-proxy-ca          no
scheduler.conf             Apr 17, 2122 05:50 UTC   99y             ca                      no

CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
ca                      May 08, 2032 03:06 UTC   9y              no
etcd-ca                 May 08, 2032 03:06 UTC   9y              no
front-proxy-ca          May 08, 2032 03:06 UTC   9y              no
yuan@k1:~/kubernetes$
```



