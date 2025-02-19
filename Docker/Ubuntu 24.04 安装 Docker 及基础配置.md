# Ubuntu 24.04 安装 Docker 及基础配置

## 系统更新

```bash
sudo apt update && sudo apt upgrade -y
sudo apt full-upgrade -y
sudo apt install curl vim wget htop iftop iotop zip unzip gnupg dpkg apt-transport-https lsb-release ca-certificates -y
```

​	如果下载或者更新软件的速度比较慢 , 可以更新软件源.

```bash
sudo sed -i -e "s/cn.archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/" /etc/apt/sources.list
sudo sed -i -e "s/security.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/" /etc/apt/sources.list
```

​	关闭 IPV6 ( 如果不使用 IPV6 ) & 开启 BBR , 向 `/etc/sysctl.conf` 追加如下内容.

```bash
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1

net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
```

​	配置执行特权命令免输密码

```bash
echo "`whoami` ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/dont-prompt-$USER-for-sudo-password"
```

​	配置时区为北京时间

```bash
sudo timedatectl set-timezone Asia/Shanghai
```

​	重启使配置生效

```bash
sudo reboot
```

## 安装 Docker

​	添加 Docker 官方库

```bash
sudo apt remove -y docker docker-engine docker.io containerd runc
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

​	如果无法访问官网地址 , 可以将密钥下载地址替换为以下地址.

```bash
# 清华源
https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu/gpg
# 阿里云
https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg
```

​	创建适合当前 CPU 架构和系统的源

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

​	同样 , 如果无法访问官方源 , 替换掉官方地址.

```bash
# 清华源
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu/ \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 阿里云
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu/ \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

​	安装 Docker-CE 及 Docker Compose

```bash
sudo apt update && sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
sudo systemctl status docker && sudo systemctl enable docker
```

​	如果想阻止 Docker 随系统更新 , 可以锁定 Docker 版本

```bash
sudo apt-mark hold docker-ce
```

​	以非 `Root` 身份运行 Docker

```bash
sudo usermod -aG docker $USER
```

​	`Ctrl+D` 退出 , 重新登录即可.

## 配置 Docker

### 安装 Loki

​	安装 Loki 日志驱动 , 详细文档可以访问 [这里](https://grafana.com/docs/loki/latest/send-data/docker-driver/) , 如果服务器在墙内 , 可以使用 `dockerpull.com` 这样的代理

```bash
docker plugin install grafana/loki-docker-driver:3.3.2-amd64 --alias loki --grant-all-permissions
```

​	使用如下命令检查插件是否启用

```bash
docker plugin ls
ID             NAME          DESCRIPTION           ENABLED
468a0671ce2d   loki:latest   Loki Logging Driver   true
```

​	如果 Loki 没有启用 , `ENABLED` 显示为 `false` , 使用如下命令启用.

```bash
docker plugin enable loki
```

### 配置固定子网

​	编辑 `/etc/docker/daemon.json` , 添加如下内容.

```json
{
  "default-address-pools": [
    {
      "base": "172.20.0.0/16",
      "size": 24
    },
    {
      "base": "172.21.0.0/16",
      "size": 24
    },
    {
      "base": "172.22.0.0/16",
      "size": 24
    }
  ]
}
```

​	重启 Docker

```bash
sudo systemctl restart docker.service
```

## 安装 Powerline

​	添加 universe 仓库并安装 powerline

```bash
sudo apt update -y
sudo add-apt-repository universe
sudo apt install powerline -y
```

​	向 `~/.bashrc` 添加如下内容

```bash
# Powerline configuration
if [ -f /usr/share/powerline/bindings/bash/powerline.sh ]; then
  powerline-daemon -q
  POWERLINE_BASH_CONTINUATION=1
  POWERLINE_BASH_SELECT=1
  source /usr/share/powerline/bindings/bash/powerline.sh
fi
```

​	

## VIM 高亮调整 / 配色调整

​	将 `molokai.vim` 上传到 `/usr/share/vim/vim91/colors/` 下 , 并向 `~/.vimrc` 写入以下内容

```bash
syntax enable
colorscheme molokai
set t_Co=256
set background=dark
set showmode
set nocompatible
set encoding=utf-8
set nobackup
set noswapfile
set tabstop=4
set shiftwidth=4
set expandtab
set smarttab
set autoread
set autoindent
set hlsearch
set ruler

python3 from powerline.vim import setup as powerline_setup
python3 powerline_setup()
python3 del powerline_setup

set laststatus=2
```

​	上传 `filetype.vim` 到 `/usr/share/vim/vim91/` 下 ; 

​	上传 `nginx.vim` 到 `/usr/share/vim/vim91/syntax/` 下 , 并检查 `nginx.vim` 中是否包含如下内容 , 如果没有则添加上.

```bash
" Nginx
au BufRead,BufNewFile /etc/nginx/*,/usr/local/nginx/conf/*,/home/config/openresty/* if &ft == '' | setfiletype nginx | endif
```

## 添加 Alias

​	向 `~/.bashrc` 中添加如下 alias

```bash
alias dps='docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
alias dnl='docker network ls -q | xargs -I {} docker network inspect {} --format "{{.Name}}: {{range .IPAM.Config}}{{.Subnet}}{{end}}"'
alias ds='docker stats'
alias dlog='docker logs -f --tail 200'
```

