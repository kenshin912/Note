# Docker 容器优雅终止方案

FROM : https://blog.true-kubernetes.com/why-does-my-docker-container-take-10-seconds-to-stop/

某些容器需要花费 `10s` 左右才能停止，这是为什么？

1. 容器中的进程没有收到 SIGTERM 信号
2. 容器中的进程收到了 SIGTERM 信号但是忽略了
3. 容器中的应用关闭时间确实就是这么长

本文主要解决 1 ，2 问题。

如果构建新的镜像，肯定希望镜像越小越好，这样下载和启动都很快。一般我们会选择 `Alpine` , `Busybox` 作为基础镜像。

```bash
FROM alpine:3.7
```

问题就在这里，这些基础镜像的 init 系统也被抹掉了。

init 系统特点：

* 系统的第一个进程，负责产生其他所有用户进程
* init 以守护进程方式存在，是所有其他进程的父进程
* 它主要负责：
    * 启动守护进程
    * 回收孤儿进程
    * 将操作系统信号转发给子进程


## Docker 容器停止过程

对于容器来说，init 系统不是必须的，当你通过命令 docker stop mycontainer 来停止容器时，docker CLI 会将 TERM 信号发送给 mycontainer 的 PID 为 1 的进程

* 如果 PID 1 是 init 进程 - 那么 PID 1 会将 TERM 信号转发给子进程，然后子进程开始关闭，最后容器终止。

* 如果没有 init 进程 - 那么容器中的应用进程（Dockerfile 中的 ENTRYPOINT 或 CMD 指定的应用）就是 PID 1，应用进程直接负责响应 TERM 信号。这时又分为两种情况：
    * 应用不处理 SIGTERM - 如果应用没有监听 SIGTERM 信号，或者应用中没有实现处理 SIGTERM 信号的逻辑，应用就不会停止，容器也不会终止。
    * 容器停止时间很长 - 运行命令 docker stop mycontainer 之后，Docker 会等待 10s，如果 10s 后容器还没有终止，Docker 就会绕过容器应用直接向内核发送 SIGKILL，内核会强行杀死应用，从而终止容器。

## 容器进程收不到 SIGTERM 信号？

如果容器中的进程没有收到 SIGTERM 信号，很有可能是因为应用进程不是 PID 1，PID 1 是 shell，而应用进程只是 shell 的子进程。而 shell 不具备 init 系统的功能，也就不会将操作系统的信号转发到子进程上，这也是容器中的应用没有收到 SIGTERM 信号的常见原因。

问题的根源就来自 Dockerfile，例如：

```bash
FROM alpine:3.7
COPY cron.sh
RUN chmod a+x cron.sh
ENTRYPOINT ./cron.sh
```

`ENTRYPOINT` 指令使用的是 *Shell* 模式， 这样 Docker 就会把应用放到 shell 中运行，因此 shell 是 PID 1

## 解决方案：

### 使用 *exec* 模式

```bash
FROM alpine:3.7
COPY cron.sh
RUN chmod a+x cron.sh
ENTRYPOINT ["./cron.sh"]
```

这样 PID 1 就是 `./cron.sh` ，它将负责相应所有发送到容器的信号，至于 `./cron.sh` 是否能够捕捉到系统信号，那是另一回事。

举个例子，假设使用上面的 Dockerfile 来构建镜像，popcorn.sh 脚本每过一秒打印一次日期：

```bash
#!/bin/sh

while true
do
    date
    sleep 1
done
```

构建镜像并创建容器：

```bash
  → docker build -t truek8s/corn .
  → docker run -it --name corny --rm truek8s/corn
```

打开另外一个终端执行停止容器的命令，并计时：

```bash
time docker stop corny
```

因为 `corn.sh` 并没有实现捕获和处理 SIGTERM 信号的逻辑，所以需要 10s 左右才能停止容器。要想解决这个问题，就要往脚本中添加信号处理代码，让它捕获到 SIGTERM 信号时就终止进程：

```bash
#!/bin/sh

# catch the TERM signal and then exit
trap "exit" TERM

while true
do
    date
    sleep 1
done
```

**注意：下面这条指令与 shell 模式的 ENTRYPOINT 指令是等效的：**

```bash
ENTRYPOINT ["/bin/sh", "./corn.sh"]
```

### 直接使用 exec 命令

如果你就想使用 shell 模式的 ENTRYPOINT 指令，也不是不可以，只需将启动命令追加到 exec 后面即可，例如：

```bash
FROM alpine:3.7
COPY corn.sh .
RUN chmod +x corn.sh
ENTRYPOINT exec ./corn.sh
```

这样 exec 就会将 shell 进程替换为 ./popcorn.sh 进程，PID 1 仍然是 ./popcorn.sh。


### 使用 init 系统

如果容器中的应用默认无法处理 SIGTERM 信号，又不能修改代码，这时候方案 1 和 2 都行不通了，只能在容器中添加一个 init 系统。init 系统有很多种，这里推荐使用 tini，它是专用于容器的轻量级 init 系统，使用方法也很简单：

1. 安装 tini
2. 将 tini 设为容器的默认应用
3. 将 corn.sh 作为 tini 的参数

具体的 Dockerfile 如下：

```bash
FROM alpine:3.7
COPY corn.sh .
RUN chmod +x corn.sh
RUN apk add --no-cache tini
ENTRYPOINT ["/sbin/tini", "--", "./corn.sh"]
```

现在 tini 就是 PID 1，它会将收到的系统信号转发给子进程 corn.sh。

**使用 tini 后应用还需要处理 SIGTERM 吗？**

最后一个问题：如果移除 corn.sh 中对 SIGTERM 信号的处理逻辑，容器会在我们执行停止命令后立即终止吗？

答案是肯定的。在 Linux 系统中，PID 1 和其他进程不太一样，准确地说应该是 init 进程和其他进程不一样，它不会执行与接收到的信号相关的默认动作，必须在代码中明确实现捕获处理 SIGTERM 信号的逻辑，方案 1 和 2 干的就是这个事。

普通进程就简单多了，只要它收到系统信号，就会执行与该信号相关的默认动作，不需要在代码中显示实现逻辑，因此可以优雅终止。