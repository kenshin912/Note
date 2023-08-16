## Install Ingress-nginx via helm on Kubernetes 1.26 



##### 安装包管理器 helm

Helm 是 Kubernetes 的包管理器 , 我们在 Master 节点 K1 上安装 helm.

```bash
wget https://get.helm.sh/helm-v3.10.3-linux-amd64.tar.gz
tar -zxvf helm-v3.10.3-linux-amd64.tar.gz
mv linux-amd64/helm  /usr/local/bin/
```

执行 `helm list` 确认没有错误输出.

获取资源清单

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm pull ingress-nginx/ingress-nginx
tar zxvf ingress-nginx-4.6.0.tgz
```

修改 ingress-nginx/values.yaml

我们需要使用宿主机模式 , 故需要将 hostNetwork 设置为 True , 另外将 kind 设置为 DaemonSet

```yaml
  # -- Required for use with CNI based kubernetes installations (such as ones set up by kubeadm),
  # since CNI and hostport don't mix yet. Can be deprecated once https://github.com/kubernetes/kubernetes/issues/23920
  # is merged
  hostNetwork: true
  ## Use host ports 80 and 443
  ## Disabled by default
  
  # -- Use a `DaemonSet` or `Deployment`
  kind: DaemonSet
  # -- Annotations to be added to the controller Deployment or DaemonSet
  ##
```

然后使用如下命令安装 ingress-nginx 到 **ingress-nginx** 命名空间中

```bash
helm install ingress-nginx ingress-nginx-4.6.0.tgz --create-namespace -n ingress-nginx -f ingress-nginx/values.yaml
```

