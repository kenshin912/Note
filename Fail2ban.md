# Fail2ban

## Check firewall status

```bash
firewall-cmd --state
```

## Start firewalld

```bash
systemctl enable firewalld.service
systemctl start firewalld.service
```

## Update yum source and install epel

```bash
yum install epel-release -y
yum update -y
yum install fail2ban -y
systemctl enable fail2ban
systemctl start fail2ban
```

## Configure file of fail2ban

```bash
cp -pf /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
vim /etc/fail2ban/jail.local
```

## Edit file like this

```bash
[DEFAULT]
ignoreip = 127.0.0.1/8
bantime  = 86400
findtime = 600
maxretry = 5
banaction = firewallcmd-ipset
action = %(action_mwl)s

[sshd]
enabled = true
filter  = sshd
port    = 22
action = %(action_mwl)s
logpath = /var/log/secure
```

## Reload fail2ban

```bash
systemctl restart fail2ban.service
```
