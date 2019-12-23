## Build Private DockerHub on Docker

#### Create directory
> sudo mkdir -p /home/yuan/DockerRegistry

#### Download image registry
> $ sudo docker pull registry

#### Start up Container
> $ sudo docker run -d -p 5000:5000 --restart=always --name=registry -v /home/yuan/DockerRegistry:/var/lib/registry registry

```
-d: running in background
-p: port mapping
--restart: always restart this container after docker service restart
--name: container name
-v: mapping "/var/lib/registry" in container to /home/yuan/DockerRegister in Local

```

#### http protocol support

##### On images server
```
sudo touch /etc/docker/daemon.json
```

```
 { "insecure-registries": ["192.168.1.228:5000"] }
```
##### Restart Docker Service
```
sudo systemctl restart docker.service
```

#### Upload images

##### Docker tag & push
```
sudo docker tag {DockerImageID} {Registry_Server_IP}:{Registry_Server_Port}/yuan/nginx
```

```
sudo docker push {Registry_Server_IP}:{Registry_Server_Port}/yuan/nginx
```
##### test
```
curl -X GET http://192.168.1.228:5000/v2/_catalog
```

##### if return content like the following code , it works
```
{"repositories":["yuan/nginx","yuan/php"]}
```