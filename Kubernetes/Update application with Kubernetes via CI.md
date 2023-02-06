### Update application with Kubernetes via CI



#### 准备

我们使用 SPUG ( https://github.com/openspug/spug ) 来作为 CI 工具. 其他 CI 工具可参考流程.

新建 SPUG 的发布环境 **OPS** , 然后以 ERP 前端项目为例. 



#### 自定义发布

自定义发布 , 发布环境 **OPS** , 目标主机 **K8S-Master** 



##### 检出代码

新建本地动作 "Git pull" , 这一步我们将代码从仓库中拷贝一份出来 , 并切换到对应分支后 , 更新代码.

执行内容

```bash
cp -r /data/repos/1 /data/repos/k8s-erp-frontend
cd /data/repos/k8s-erp-frontend
git checkout test && git pull
ln -s /data/repos/node_modules .
```

/data/repos 是 SPUG 容器内的代码仓库目录 , 1 是代表第一个项目 , 关于如何查找项目对应的数字 ID , 可以在该项目的常规发布的 Log 中查找.

可以看到代码中 , 我们拷贝了代码后 , 检出 test 分支并更新.

接着 , 我们将公共依赖的目录 , 软链接到该目录下.



##### 打包代码

新建本地动作 "Dist build" , 这一步 , 我们使用 yarn 打包代码并压缩.

执行内容

```bash
cd /data/repos/k8s-erp-frontend
yarn install --ignore-engines --ignore-platform
yarn build:test
tar zcvf dist.tar.gz dist
```



##### 镜像打包 , 推送 , 清理

新建本地动作 "Image build & Push & Clean" , 这一步 , 我们将打包 Docker 镜像并推送到 Harbor , 然后清理本地的镜像.

执行内容

```bash
cd /data/repos/k8s-erp-frontend
cp /data/repos/docker/erp-frontend/Dockerfile ./ #将 Dockerfile 拷贝过来
docker build -f Dockerfile -t 192.168.1.235/invincible/erp-frontend:$SPUG_RELEASE . #build
docker login http://192.168.1.235 --username Jaina --password Abc,1234 #登录 Harbor
docker push 192.168.1.235/invincible/erp-frontend:$SPUG_RELEASE # Push 镜像
docker rmi 192.168.1.235/invincible/erp-frontend:$SPUG_RELEASE #删除本地镜像
cd /data/repos/
rm -rf /data/repos/k8s-erp-frontend # 清除
```



SPUG 内的 Dockerfile

```dockerfile
FROM nginx:alpine
MAINTAINER Yuan <kenshin912@gmail.com>
ENV TZ=Asia/Shanghai
ADD dist.tar.gz /home/wwwroot/ # ADD 命令会自动解压
```



$SPUG_RELEASE 是执行发布的时候 , 需要填写的值 , 我们以该值来决定打包的项目 Tag .



##### 项目更新

新建目标主机动作 "Application Update" , 这一步 , 我们将操作 K8S 控制平面 , 对应用进行更新.

执行内容

```bash
kubectl set image deployment/erp-frontend-deployment nginx=192.168.1.235/invincible/erp-frontend:$SPUG_RELEASE
```

