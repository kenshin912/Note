# Docker 相关问题

### Dockerfile 中 ADD 和 COPY 的区别是什么？
```
都可以添加本地目录/文件到镜像中 ，ADD 允许使用 URL 作为 SRC 参数 ，可以自动解压文件 (tar,gzip,bzip2...)

COPY 不支持 URL，也不会特别对待压缩文件。如果 build 上下文件中没有指定解压的话，那么就不会自动解压，只复制压缩文件到容器中.
```

### Dockerfile 中 build context dockerfile 参数分别是做什么的？
```
build 参数: 在镜像启动之前执行构建任务
context 参数: 可以是 Dockerfile 的文件路径，也可以是 git 仓库的 URL
dockerfile 参数: 使用此 Dockerfile 来构建

Warning: Compose 文件在 Swarm 模式下部署 stack 时 (Version:3+)， 该选项会被忽略，因为 docker stack 命令只接受预先构建的镜像. 
```

