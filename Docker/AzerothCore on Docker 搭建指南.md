## AzerothCore via Docker on Linux 搭建指南

<img src="https://camo.githubusercontent.com/d07bedf021e794f271d1d38db0a3dd33a5fa85bcf8957e061453d22d95af0371/68747470733a2f2f7777772e617a65726f7468636f72652e6f72672f696d616765732f6c6f676f2e706e67" alt="avatar" style="zoom:25%;" /> **AzerothCore**



#### Introduction

AzerothCore 是一个开源的 World of Warcraft 游戏服务端 , 目前支持的客户端版本是 3.3.5a . 它基于 MaNGOS , TrinityCore 和 SunwellCore 并由 C++ 语言编写.



#### Requirement

* Docker

* Git 

* [GitHub Hosts](https://raw.hellogithub.com/hosts)

  

#### Getting started

```bash
git clone https://github.com/azerothcore/acore-docker
```



#### Step by step installation

Pull the latest images , 

```bash
docker-compose pull
```

Setup the database

```bash
docker-compose up ac-db-import
```

Start services 

```bash
docker-compose up -d
```



If you're using docker compose V2 , replace  "docker-compose" to "docker compose" from the above command.



#### Game server settings.

Input your server external IP address to Database `acore_auth` Table `realmlist` Column `address` 



#### Open Ports

Allow TCP 8085 , 3724 in firewall rules.