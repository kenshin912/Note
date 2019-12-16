> rpm -qa | grep vsftpd

> yum -y install vsftpd

> yum install -y pam vsftpd db4 db4-utils

> chkconfig vsftpd on

> touch /etc/vsftpd/user_pass.txt

> chmod 600 /etc/vsftpd/user_pass.txt

> db_load -T -t hash -f /etc/vsftpd/user_pass.txt /etc/vsftpd/user_pass.db

> cp /etc/vsftpd/conf/vsftpd.conf /etc/vsftpd/conf/vsftpd.conf.default

> vi /etc/vsftpd/conf/vsftpd.conf

```
anonymous_enable=NO
local_enable=YES
write_enable=YES
allow_writeable_chroot=YES
local_umask=022
dirmessage_enable=YES
connect_from_port_20=YES
listen=YES
userlist_enable=YES
tcp_wrappers=YES
max_per_ip=5
max_clients=200
guest_enable=YES
guest_username=apache
pam_service_name=/etc/pam.d/vsftpd
user_config_dir=/etc/vsftpd/vuser_conf
pasv_enable=YES
pasv_min_port=60001
pasv_max_port=60009
port_enable=YES
```

> vi /etc/pam.d/vsftpd

> auth required /lib64/security/pam_userdb.so db=/etc/vsftpd/user_pass

> account required /lib64/security/pam_userdb.so db=/etc/vsftpd/user_pass

> mkdir /etc/vsftpd/vuser_conf

> touch /etc/vsftpd/vuser_conf/ftp

> vi /etc/vsftpd/vuser_conf/ftp

```
anon_world_readable_only=no
write_enable=yes
anon_upload_enable=yes
anon_mkdir_write_enable=yes
anon_other_write_enable=yes
local_root=/home/web
```