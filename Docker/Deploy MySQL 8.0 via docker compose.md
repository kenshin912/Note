### Deploy MySQL 8.0 via docker compose

```yaml
version: '3.9'

services:
	mysql:
		image: mysql8.0
		container_name: mysql
		ports:
			- "3306:3306"
		privileged: true
		environment:
			TZ: "Asia/Shanghai"
            MYSQL_DATABASE: "mysql"
            MYSQL_ROOT_PASSWORD: "root"
            MYSQL_USER: "nacos"
            MYSQL_PASSWORD: "nacos"
        command:
            --character-set-server=utf8mb4
            --collation-server=utf8mb4_general_ci
            --explicit_defaults_for_timestamp=true
            --lower-case-table-names=1
        restart: always
        volumes:
            - "/home/data/mysql:/var/lib/mysql"
            - "/home/config/mysql:/etc/mysql/conf.d"
        logging:
            driver: none
        networks:
            - net
```



MySQL 8.0 不再支持 *password*  函数

>   The PASSWORD() function. Additionally, PASSWORD() removal means that SET PASSWORD ... = PASSWORD('auth_string') syntax is no longer available.



首先 , 使用跳权限命令启动 MySQL 并登录

修改 /home/config/mysql/my.cnf , 添加如下参数.

```ini
skip_grant_tables
```

保存后 , 退出重启 MySQL 容器



我们先将 `authentication_string` 字段设置为空.

>   update mysql.user set authentication_string='' where user='root'
>
>   flush privileges



使用 `set password` 修改密码

```bash
mysql> set password for 'root'@'localhost'='123456';
ERROR 1290 (HY000): The MySQL server is running with the --skip-grant-tables option so it cannot execute this statement
mysql> flush privileges;
Query OK, 0 rows affected (0.13 sec)
mysql> set password for 'root'@'localhost'='123456';
Query OK, 0 rows affected (0.01 sec)
```

第一次执行 set password 命令会失败 , 第二次才会成功.

执行 flush privileges 命令会让 MySQL 实例重新读取授权表并将 initialized 变量设置为 true, 因此第二次的 set password 命令正常执行。
