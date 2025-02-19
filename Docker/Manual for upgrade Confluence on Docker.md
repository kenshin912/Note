# Manual for upgrade Confluence on Docker

## Introduction

Our internal wiki, Confluence, was hacked during the Chinese New Year vacation in 2025.

Exposing Confluence to the internet is highly unsafe, not only because the version (7.9.3) is outdated, but also due to critical security vulnerabilities, such as [CVE-2023-22518](https://confluence.atlassian.com/security/cve-2023-22518-improper-authorization-vulnerability-in-confluence-data-center-and-server-1311473907.html).

Unfortunately, the worst happened—we got hacked.

As a result , the migration & upgrade plan must be implemented ahead of schedule.

| Type           | Old Version       | New Version                 |
| -------------- | ----------------- | --------------------------- |
| Confluence App | Confluence: 7.9.3 | Confluence: 8.5.19 or Later |
| Database       | MySQL 5.7         | MySQL 8.0                   |

## Backup Confluence

### Backup Application data

The following is the file structure for Confluence container:

```shell
  root  UAT  /  home  confluence  confluence  tree -L 2
.
├── confluence
│   ├── analytics-logs
│   ├── attachments
│   ├── backups
│   ├── bundled-plugins
│   ├── confluence.cfg.xml
│   ├── imgEffects
│   ├── index
│   ├── ..........
├── database
│   ├── auto.cnf
│   ├── ca-key.pem
│   ├── ca.pem
│   ├── client-cert.pem
│   ├── client-key.pem
│   ├── confluence
│   ├── .........
└── docker-compose.yml

 root  UAT  /  home  confluence  zip -r confluence.zip -x "backups/*"
```

To create a compressed archive named `confluence.zip` , use `zip` command while excluding the `backups` directory.

* `zip -r confluence.zip ...` → Recursively compressed the specified files and directories into `confluence.zip`
* `-x "backups/*"` → Excludes the `backups` directory from the archive.

### Backup Database

The following command to backup the Confluence database and save it as `confluence.sql`

```shell
docker exec -i confluence-db mysqldump -u confluence -p --single-transaction --quick --compress --max-allowed-packet=1024M confluence 1>> confluence.sql 2>> /dev/null
```

* `docker exec -i confluence-db mysqldump` → Runs the `mysqldump` command inside the `confluence-db` container . The `-i` flag allows interactive input.
* `-u confluence -p` → Specifies the database username ( confluence) . The password prompt will appear unless provided explicitly.
* `--single-transaction` → Ensures a consistent snapshot while minimizing lock time.
* `--quick` → Streams large tables row by row instead of loading them all into memory.
* `--compress` → Compresses data during transfer to reduce size.
* `--max-allowed-packet=1024M` → Increases the maximum packet size to handle large data.
* `1>> confluence.sql` → Appends the output to `confluence.sql` .
* `2>> /dev/null` → Suppresses error messages by redirecting them to `/dev/null` .



Update `confluence.sql`  , Replace the `CHARACTER SET` and `COLLATE` settings  with `utf8mb4` and `utf8mb4_bin` , `ROW_FORMAT` to `DYNAMIC` ,  which is required by `confluence` and `MySQL 8.0`

```shell
sudo sed -i "s/ROW_FORMAT=COMPACT/ROW_FORMAT=DYNAMIC/g" confluence.sql
sudo sed -i "s/CHARSET=utf8 COLLATE=utf8_bin/CHARSET=utf8mb4 COLLATE=utf8mb4_bin/g" confluence.sql
sudo sed -i "s/COLLATE utf8_bin/COLLATE utf8mb4_bin/g" confluence.sql
sudo sed -i "s/character_set_client = utf8/character_set_client = utf8mb4/g" confluence.sql
```



## Start up new instances of confluence 

Use the following `docker-compose.yml` file to start up new containers.

```yaml
x-logging: &log
    driver: "json-file"
    options:
        max-size: "64m"
        max-file: "1"

services:
    confluence:
        image: haxqer/confluence:8.5.19
        container_name: confluence
        ports:
            - "8090:8090"
        volumes:
            - /home/confluence/confluence:/var/confluence
        environment:
            - TZ=Asia/Shanghai
            - JVM_MINIMUM_MEMORY=2g
            - JVM_MAXIMUM_MEMORY=4g
        restart: always
        logging: *log
        depends_on:
            - mysql
        networks:
            - net

    mysql:
        image: mysql:8.0
        container_name: confluence-db
        volumes:
            - /home/confluence/database:/var/lib/mysql
        environment:
            - TZ=Asia/Shanghai
            - MYSQL_DATABASE=confluence
            - MYSQL_ROOT_PASSWORD=confluence
            - MYSQL_USER=confluence
            - MYSQL_PASSWORD=confluence
        command: >
        	mysqld
        	--character-set-server=utf8mb4
        	--collation-server=utf8mb4_bin
        	--innodb_buffer_pool_size=1G
        	--innodb_flush_log_at_trx_commit=2
        	--innodb_flush_method=O_DIRECT
        	--innodb_log_file_size=256M
        	--join_buffer_size=4M
        	--log_bin_trust_function_creators=1
        	--max_allowed_packet=256M
        	--max_connections=200
        	--max_heap_table_size=64M
        	--query_cache_type=0
        	--query_cache_size=0
        	--skip-log-bin
        	--skip-name-resolve
        	--skip-external-locking
        	--thread_cache_size=16
        	--transaction-isolation=READ-COMMITTED
        	--tmp_table_size=64M
        restart: always
        logging: *log
        networks:
            - net
            
networks:
	net:
		driver: bridge
```



Start up the containers .

```shell
 user  GPU  /  home  confluence  docker compose up -d
```



### Get License key

Run the following command and paste the output in to a text editor

```shell
 user  GPU  /  home  confluence  docker exec confluence java -jar /var/agent/atlassian-agent.jar -d -p conf -m kenshin912@gmail.com -n kenshin912@gmail.com -o NASA -s your-server-id
```



Get MySQL container IP Address

```shell
 user  GPU  /  home  confluence  docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' confluence-db
```



Stop the confluence container

```shell
 user  GPU  /  home  confluence  docker stop confluence
```



Clear confluence data directory

```shell
 user  GPU  /  home  confluence  confluence  sudo rm -rf *
```



### Restore Application data

Upload the  `confluence.zip`  backup file  to  `/home/confluence/confluence` 

Unzip the backup file

```shell
 user  GPU  /  home  confluence  confluence  sudo unzip confluence.zip
```



Edit `/home/confluence/confluence/confluence.cfg.xml` to update the license key and database url

```xml
<property name="atlassian.license.message">YOUR_LICENSE_KEY_HERE</property>
<property name="hibernate.connection.url">jdbc:mysql://MYSQL_CONTAINER_IP:3306/confluence?useSSL=false&amp;allowPublicKeyRetrieval=true</property>
```

Replace `YOUR_LICENSE_KEY_HERE` with the obtained license key and `MYSQL_CONTAINER_IP` with the IP Address of the MySQL container.



### Restore Database

Upload file `confluence.sql` to `/home/confluence/database/` directory 

Access MySQL container and import `confluence.sql`

```shell
user  GPU  /  home  confluence  docker exec -it confluence-db bash
bash-5.1# mysql -u confluence -p
Enter password: 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 5254
Server version: 8.0.41 MySQL Community Server - GPL

Copyright (c) 2000, 2025, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> use confluence;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> source /var/lib/mysql/confluence.sql
...
...
```

Once the import process is completed , open your browser and visit http://your_server_ip:8090 to check if the confluence instance is running successfully.

