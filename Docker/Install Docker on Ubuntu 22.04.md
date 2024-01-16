# Install Docker on Ubuntu 22.04 / Debian 12

## 更新软件包索引 , 添加 HTTPS 软件源

```bash
sudo apt update -y 

sudo apt upgrade -y

sudo apt full-upgrade -y

sudo apt install curl vim wget gnupg dpkg apt-transport-https lsb-release ca-certificates
```

## 导入源仓库的 GPG Key

### Ubuntu

```bash
curl -sSL https://download.docker.com/linux/debian/gpg | gpg --dearmor > /usr/share/keyrings/docker-ce.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-ce.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -sc) stable" > /etc/apt/sources.list.d/docker.list
```

### Debian

```bash
curl -sSL https://download.docker.com/linux/debian/gpg | gpg --dearmor > /usr/share/keyrings/docker-ce.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-ce.gpg] https://download.docker.com/linux/debian $(lsb_release -sc) stable" > /etc/apt/sources.list.d/docker.list
```

## 添加 Docker 官方库

### Ubuntu

```bash
curl -sS https://download.docker.com/linux/debian/gpg | gpg --dearmor > /usr/share/keyrings/docker-ce.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-ce.gpg] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu $(lsb_release -sc) stable" > /etc/apt/sources.list.d/docker.list
```

### Debian

```bash
curl -sS https://download.docker.com/linux/debian/gpg | gpg --dearmor > /usr/share/keyrings/docker-ce.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-ce.gpg] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/debian $(lsb_release -sc) stable" > /etc/apt/sources.list.d/docker.list
```

## 安装 Docker 最新版本

```bash
sudo apt update -y
sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl status docker
sudo systemctl enable docker
```

### 如果想阻止 Docker 自动更新 , 锁住版本

```bash
sudo apt-mark hold docker-ce
```

### 以非 Root 身份运行 Docker

```bash
sudo usermod -aG docker $USER
```

退出重新登录 , 即可.

## 配置固定子网地址

编辑 `/etc/docker/daemon.json` , 添加如下内容.

```json
{
  "default-address-pools": [
    {
      "base": "172.20.0.0/16",
      "size": 24
    },
    {
      "base": "172.30.0.0/16",
      "size": 24
    },
    {
      "base": "172.40.0.0/16",
      "size": 24
    }
  ]
}
```

重启 Docker 服务

```bash
sudo systemctl restart docker.service
```

使用 `docker info` 命令确认生效.

```bash
...
 Default Address Pools:
   Base: 172.20.0.0/16, Size: 24
   Base: 172.30.0.0/16, Size: 24
   Base: 172.40.0.0/16, Size: 24
```
