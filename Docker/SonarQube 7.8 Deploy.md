# SonarQube 7.8 Deploy on Docker Compose

## Environment Preparation

### Prerequisites

#### System settings

```bash
sudo echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sudo sysctl -p
```

## Create docker-compose.yml

### Create file with the following content

Using named docker volume instead of direct binding. with the declaration of volume list at the end of yaml file.

```yaml
version: '3.9'

x-logging: &sonar-logging
    driver: "json-file"
    options:
        max-size: "64m"
        max-file: "1"

services:
    postgresql:
        image: postgres:11.1
        container_name: postgresql
        volumes:
            - "/home/data/postgresql:/var/lib/postgresql"
        environment:
            TZ: Asia/Shanghai
            POSTGRES_USER: sonar
            POSTGRES_PASSWORD: ppnn13%dkstFeb.1st
            POSTGRES_DB: sonar
        healthcheck:
            test: ["CMD-SHELL", "pg_isready -U postgres"]
            interval: 15s
            timeout: 5s
            retries: 3
            start_period: 10s
        restart: always
        logging: *sonar-logging
        networks:
            - net

    sonarqube:
        image: sonarqube:7.8-community
        container_name: sonarqube
        ports:
            - "9000:9000"
        volumes:
            - "sonarqube_data:/opt/sonarqube/data"
            - "sonarqube_conf:/opt/sonarqube/conf"
            - "sonarqube_extensions:/opt/sonarqube/extensions"
            - "sonarqube_plugins:/opt/sonarqube/lib/bundled-plugins"
        environment:
            TZ: Asia/Shanghai
            SONARQUBE_JDBC_USERNAME: sonar
            SONARQUBE_JDBC_PASSWORD: ppnn13%dkstFeb.1st
            SONARQUBE_JDBC_URL: jdbc:postgresql://postgresql:5432/sonar
        command: -Dsonar.ce.javaOpts=-Xmx1192m -Dsonar.web.javaOpts=-Xmx1192m
        restart: unless-stopped
        logging: *sonar-logging
        depends_on:
            postgresql:
                condition: service_healthy
        networks:
            - net

networks:
    net:
        driver: bridge

volumes:
    sonarqube_data:
    sonarqube_conf:
    sonarqube_extensions:
    sonarqube_plugins:
```

## Startup SonarQube

```bash
docker compose up -d
```

## Chinese Language package install

### Download Language package for SonarQube 7.8

```bash
wget https://github.com/xuhuisheng/sonar-l10n-zh/releases/download/sonar-l10n-zh-plugin-1.28/sonar-l10n-zh-plugin-1.28.jar
```

### Copy Language package to SonarQube Container

```bash
docker cp sonar-l10n-zh-plugin-1.28.jar  sonarqube:/opt/sonarqube/extensions/plugins/
```

### Restart SonarQube

```bash
docker restart sonarqube
```
