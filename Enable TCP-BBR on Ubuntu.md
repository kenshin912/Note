# Enable TCP-BBR in Ubuntu Server

## TCP-BBR is available for Linux Kernel v4.9

## This is a quick start guide for the TCP-BBR implementation

- ### Download Kernel

```bash
wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.9/linux-image-4.9.0-040900-generic_4.9.0-040900.201612111631_amd64.deb
```

- ### Install Kernel

```bash
dpkg -i linux-image-4.9.0*.deb
```

- ### Removal Old Kernel (Optional)

```bash
dpkg -l|grep linux-image | awk '{print $2}' | grep -v 'linux-image-4.9.0-040900-generic'
apt-get purge OLD KERNEL NAME
```

- ### Update GRUB

```bash
update-grub
reboot
```

- ### Confirm Kernel Version

```bash
root@ubuntu:~# uname -r
4.9.0-040900-generic
```

- ### Enable TCP-BBR

```bash
echo "net.core.default_qdisc=fq" >> /etc/sysctl.con
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.con
sysctl -p
```

- ### Confirm TCP-BBR is enabled

```bash
sysctl net.ipv4.tcp_available_congestion_control

sysctl net.ipv4.tcp_congestion_control
```

#### if "bbr" in both 2 command result ,then TCP-BBR is enabled

```bash
lsmod | grep bbr
```

#### if return "tcp_bbr" , then TCP-BBR is start up