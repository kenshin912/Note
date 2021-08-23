## Timezone set on Docker images

#### 宿主机为 Linux 操作系统

```bash
-v /etc/timezone:/etc/timezone:ro -v /etc/localtime:/etc/localtime:ro
```



#### 传递环境变量改变容器时区

```bash
-e TZ=Asia/Shanghai
```

example:

```bash
docker run --name test -e TZ=Asia/Shanghai --rm -it debian /bin/bash
/# date
Fri Nov 29 18:46:18 CST 2019
```



#### 制作镜像时调整时区

1. Alpine 

   ```bash
   ENV TZ Asia/Shanghai
   
   RUN apk add tzdata && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
       && echo ${TZ} > /etc/timezone \
       && apk del tzdata
   ```

   

2. Debian

   ```bash
   ENV TZ=Asia/Shanghai \
       DEBIAN_FRONTEND=noninteractive
   
   RUN ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
       && echo ${TZ} > /etc/timezone \
       && dpkg-reconfigure --frontend noninteractive tzdata \
       && rm -rf /var/lib/apt/lists/*
   ```

   

3. Ubuntu

   ```bash
   ENV TZ=Asia/Shanghai \
       DEBIAN_FRONTEND=noninteractive
   
   RUN apt update \
       && apt install -y tzdata \
       && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
       && echo ${TZ} > /etc/timezone \
       && dpkg-reconfigure --frontend noninteractive tzdata \
       && rm -rf /var/lib/apt/lists/*
   ```

   

4. Cent OS

   ```bash
   ENV TZ Asia/Shanghai
   
   RUN ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime \
       && echo ${TZ} > /etc/timezone
   ```

   