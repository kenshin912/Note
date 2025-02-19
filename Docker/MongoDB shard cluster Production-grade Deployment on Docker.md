# MongoDB shard cluster Production-grade Deployment on Docker

## Introduction

This document provides a comprehensive, production-grade deployment solution for a MongoDB sharded cluster.

Below, you'll find a detailed step-by-step guide along with sample configurations for reference.

## Architecture Design

A typical MongoDB sharded cluster consists of the following key components:

- **Shards**: Each shard should ideally be a replica set with at least **three nodes** for redundancy and fault tolerance.
- **Config Servers**: A replica set of at least **three nodes** is required to store metadata and manage cluster configurations.
- **Routing Service (`mongos`)**: Acts as a query router, connecting clients to the appropriate shard in the cluster.

### **Preparation**

1. **Install Docker and Docker Compose**

   Install **Docker** and **Docker Compose** on each node. Ensure that network connectivity between the nodes is properly configured.

2. **Prepare the Keyfile**

   - Generate a shared **keyfile** for all MongoDB instances (e.g., named `keyfile`).
   - The keyfile content can be generated using **OpenSSL** or any other method that produces a random string. You may also manually create it using `vim`.
   - Set the file permissions to **400** and change the file owner to **UID 999**.
   - Store the keyfile in a fixed directory on each node and mount it into the container using **Docker Compose**.

3. **Deployment Plan**

   Since we have only **three nodes**, to ensure that each replica set has **three members**, deploy the following services on each node:

   - **Config Server**: Deploy on each node.
   - **Shard1 Replica Set**: Deploy on each node.
   - **Shard2 Replica Set**: Deploy on each node.
   - **Mongos**: Deploy one or more instances separately as needed.

|  IP Address   |    Config Server    |       Shard 1       |       Shard 2       |       Mongos        |
| :-----------: | :-----------------: | :-----------------: | :-----------------: | :-----------------: |
| 192.168.1.201 | 192.168.1.201:27017 | 192.168.1.201:27020 | 192.168.1.201:27021 | 192.168.1.201:27018 |
| 192.168.1.202 | 192.168.1.202:27017 | 192.168.1.202:27020 | 192.168.1.202:27021 |                     |
| 192.168.1.203 | 192.168.1.203:27017 | 192.168.1.203:27020 | 192.168.1.203:27021 |                     |



## Deploy Config Server replica set

Start a `Config Server` service on each nodes. 

Example `docker-compose.yml` for `Config Server`  on `192.168.1.201` 

```yaml
x-shared-conf: &shared-conf
    image: mongo:4.4
    restart: always
    environment:
        MONGO_INITDB_ROOT_USERNAME: "admin"
        MONGO_INITDB_ROOT_PASSWORD: "NicePassword"
    logging:
        driver: "json-file"
        options:
            max-size: "64m"
            max-file: "1"
    networks:
        - mongo

services:
    configserver:
        <<: *shared-conf
        container_name: mongo-configserver
        volumes:
            - "/home/mongo/configdb:/data/db"
            - "/home/mongo/keyfile:/data/keyfile:ro"
        ports:
            - "27017:27017"
        command: [
            "mongod",
            "--configsvr",
            "--replSet", "ConfigReplSet",
            "--port", "27017",
            "--auth",
            "--keyFile", "/data/keyfile",
            "--bind_ip_all"
        ]
        
networks:
    mongo:
        driver: bridge
```

Repeat the same deployment on `192.168.1.202` and `192.168.1.203`.

### Initialize Config Server Replica Set

1. Start up `Config Server` container on each nodes. ( ensure that  `--replSet` value in each configuration file is set to `ConfigReplSet`)

   ```bash
   docker compose up -d
   ```

2. Choose any node (e.g., `192.168.1.201`) and access the container:

   ```bash
   docker exec -it mongo-configserver mongo --port 27017 -u admin -p NicePassword --authenticationDatabase admin
   ```

3. Initialize the Config Server replica set by running the following command.

   ```javascript
   rs.initiate({
     _id: "ConfigReplSet",
     configsvr: true,
     members: [
       { _id: 0, host: "192.168.1.201:27017" },
       { _id: 1, host: "192.168.1.202:27017" },
       { _id: 2, host: "192.168.1.203:27017" }
     ]
   })
   ```

4. Verify the replica set status: 

   ```javascript
   rs.status()
   ```



## Shard Replica Set Deploy

Deploy a shard replica set on every node for each shard. The following below are configurations for `Shard1` & `Shard2` 

Example `docker-compose.yml` for `Shard` on `192.168.1.201`

```yaml
x-shared-conf: &shared-conf
    image: mongo:4.4
    restart: always
    environment:
        MONGO_INITDB_ROOT_USERNAME: "admin"
        MONGO_INITDB_ROOT_PASSWORD: "NicePassword"
    logging:
        driver: "json-file"
        options:
            max-size: "64m"
            max-file: "1"
    networks:
        - mongo
      
services:
    shard1:
        <<: *shared-conf
        container_name: mongo-shard1
        volumes:
            - "/home/mongo/data/shard1:/data/db"
            - "/home/mongo/keyfile:/data/keyfile:ro"
        ports:
            - "27020:27017"
        command: [
            "mongod",
            "--shardsvr",
            "--replSet", "Shard1ReplSet",
            "--port", "27017",
            "--auth",
            "--keyFile", "/data/keyfile",
            "--bind_ip_all"
        ]

    shard2:
        <<: *shared-conf
        container_name: mongo-shard2
        volumes:
            - "/home/mongo/data/shard2:/data/db"
            - "/home/mongo/keyfile:/data/keyfile:ro"
        ports:
            - "27021:27017"
        command: [
            "mongod",
            "--shardsvr",
            "--replSet", "Shard2ReplSet",
            "--port", "27017",
            "--auth",
            "--keyFile", "/data/keyfile",
            "--bind_ip_all"
        ]
        
networks:
    mongo:
        driver: bridge
```

Repeat the same deployment on `192.168.1.202` , `192.168.1.203`



### Initialize the Shard Replica Set

1. Start up `Shard1` & `Shard2` containers on each node.

   ```shell
   docker compose up -d
   ```

2. Choose any node (e.g., `192.168.1.201`) and access the container:

   ```bash
   docker exec -it shard1 mongo --port 27017 -u admin -p NicePassword --authenticationDatabase admin
   ```

3. Running the following command to initialize `Shard1`

   ```javascript
   rs.initiate({
     _id: "Shard1ReplSet",
     members: [
       { _id: 0, host: "192.168.1.201:27020" },
       { _id: 1, host: "192.168.1.202:27020" },
       { _id: 2, host: "192.168.1.203:27020" }
     ]
   })
   ```

4. Repeat the above command for `Shard2` , changing the replica set name to `Shard2ReplSet` and adjusting the port numbers accordingly .



## Mongos deploy

For a production-grade on MongoDB Shard cluster , it is recommended to deploy **mongos** separately.

Example for `docker-compose.yml` for `mongos`

```yaml
x-shared-conf: &shared-conf
    image: mongo:4.4
    restart: always
    environment:
        MONGO_INITDB_ROOT_USERNAME: "admin"
        MONGO_INITDB_ROOT_PASSWORD: "NicePassword"
    logging:
        driver: "json-file"
        options:
            max-size: "64m"
            max-file: "1"
    networks:
        - mongo

services:
		mongos:
        <<: *shared-conf
        container_name: mongos
        volumes:
            - "/home/mongo/keyfile:/data/keyfile:ro"
        ports:
            - "27018:27017"
        command: mongos --configdb ConfigReplSet/192.168.1.201:27017,192.168.1.202:27017,192.168.1.203:27017 --keyFile /data/keyfile --bind_ip_all
        #Uncomment the following 2 lines when you deploy mongos with shard & configserver together
        #depends_on:
            #- configserver
            
networks:
    mongo:
        driver: bridge
```

Description :

* The `--configdb` parameter specifies `config server` replica set , listing the IP addresses and ports **outside** of the container.

* **Mongos doesn't store any data** by default . For security reasons ,  you should use a **keyfile** to authenticate connections to **mongod** instances.

**Start up mongos**:

```bash
docker compose up -d
```



## Add Shard on Mongos

1. Access the mongos container

   ```bash
   docker exec -it mongos mongo --port 27017 -u admin -p NicePassword --authenticationDatabase admin
   ```

2. Add Shard informations

   ```javascript
   sh.addShard("Shard1ReplSet/192.168.1.201:27020,192.168.1.202:27020,192.168.1.203:27020");
   sh.addShard("Shard2ReplSet/192.168.1.201:27021,192.168.1.202:27021,192.168.1.203:27021");
   ```

3. Verify the cluster status.

   ```javascript
   sh.status();
   ```

This deployment ensures high availability, scalability, and security, making it suitable for a production-grade MongoDB sharded cluster setup using Docker.