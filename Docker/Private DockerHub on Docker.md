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
##### on images server
> 