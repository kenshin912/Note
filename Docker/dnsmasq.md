## dnsmasq on Docker

#### Search dnsmasq
`sudo docker search dnsmasq`

#### Pull the image from docker.io to local
`sudo docker pull andyshinn/dnsmasq`

#### Run Container
`sudo docker run -d --restart=always --name dnsmasq -p 53:53/tcp -p 53:53/udp --cap-add=NET_ADMIN andyshinn/dnsmasq`

#### No bash env in this Container
`sudo docker exec -it dnsmasq /bin/sh`

#### Modifiy /etc/dnsmasq.conf
Use `ifconfig` get docker internal IP Address
Listen IP Address of Docker Container itself
```
listen-address=172.17.0.5
server=119.29.29.29
server=223.5.5.5

server=/.bilibili.com/208.67.222.222#5353
server=/.google.com/208.67.222.222#5353
server=/.youtube.com/208.67.222.222#5353
server=/.docker.io/208.67.222.222#5353
server=/.wikipedia.com/208.67.222.222#5353
```
#### save file

#### Docker restart
`sudo docker restart dnsmasq`