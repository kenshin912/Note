# GitLab Backup & Restore

## Backup

```bash
# gitlab-rake gitlab:backup:create
```

backup files will be in `/var/opt/gitlab/backups` when default settings.

## Restore(on new server)

```bash
# yum update -y
# yum install -y curl policycoreutils-python openssh-server
# firewall-cmd --permanent --add-service=http
# firewall-cmd --permanent --add-service=https
# systemctl reload firewalld
# curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh | sudo bash
# yum install -y gitlab-ee-12.4.2
# cp gitlab.rb /etc/gitlab/
# cp gitlab-secrets.json /etc/gitlab/
# gitlab-ctl reconfigure
# gitlab-ctl stop unicorn
# gitlab-ctl stop sidekiq
# gitlab-rake gitlab:backup:restore BACKUP=1590460170_2020_05_26_12.4.2-ee
```
