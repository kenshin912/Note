## Install Docker on Ubuntu 20.04



更新软件包索引 , 添加 HTTPS 软件源

```bash
sudo apt update

sudo apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
```



使用 `curl` 导入源仓库的 GPG Key

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
```



将 Docker APT 源添加到系统中

```bash
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
```



安装 Docker 最新版本

```bash
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io
sudo systemctl status docker
sudo systemctl enable docker
```



如果想阻止 Docker 自动更新 , 锁住版本

```bash
sudo apt-mark hold docker-ce
```



以非 Root 身份运行 Docker

```bash
sudo usermod -aG docker $USER
```

退出重新登录 , 即可.