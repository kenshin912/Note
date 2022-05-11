### Deploy Nacos Cluster on Kubernetes with no pvc mode



#### What is Nacos

```
Nacos (official site: nacos.io) is an easy-to-use platform designed for dynamic service discovery and configuration and service management. It helps you to build cloud native applications and microservices platform easily.
```



#### Quick Start

To use Nacos on Kubernetes , we have to figure it out how to use database ; in this case , extenal database (AWS RDS / Aliyun RDS ) could be a better choice . It is simply , more stability for us.

We are showing Nacos being deployed on Kubernetes as StatefulSets.

1. External Database.

   > https://github.com/alibaba/nacos/blob/master/distribution/conf/nacos-mysql.sql

​		Import sql file from the above link.

2. Prepare the yaml file.

   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: nacos-headless
     namespace: nacos
     labels:
       app: nacos-headless
   spec:
     type: ClusterIP
     clusterIP: None
     ports:
       - port: 8848
         name: server
         targetPort: 8848
       - port: 9848
         name: client-rpc
         targetPort: 9848
       - port: 9849
         name: raft-rpc
         targetPort: 9849
         ## 兼容1.4.x版本的选举端口
       - port: 7848
         name: old-raft-rpc
         targetPort: 7848
     selector:
       app: nacos
   ---
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: nacos-cm
     namespace: nacos
   data:
     mysql.host: "192.168.1.202" # Extenal Database IP Address
     mysql.db.name: "nacos_config" 
     mysql.port: "3306"
     mysql.user: "root"
     mysql.password: "ppnn13%dkstFeb.1st"
   ---
   apiVersion: apps/v1
   kind: StatefulSet
   metadata:
     name: nacos
     namespace: nacos
   spec:
     serviceName: nacos-headless
     replicas: 3
     template:
       metadata:
         labels:
           app: nacos
         annotations:
           pod.alpha.kubernetes.io/initialized: "true"
       spec:
         affinity:
           podAntiAffinity:
             requiredDuringSchedulingIgnoredDuringExecution:
               - labelSelector:
                   matchExpressions:
                     - key: "app"
                       operator: In
                       values:
                         - nacos
                 topologyKey: "kubernetes.io/hostname"
         containers:
           - name: k8snacos
             imagePullPolicy: Always
             image: 192.168.1.235/k8s/nacos-server:v2.1.0-slim # the Docker image you have uploaded to Harbor.
             resources:
               requests:
                 memory: "2Gi"
                 cpu: "500m"
             ports:
               - containerPort: 8848
                 name: client
               - containerPort: 9848
                 name: client-rpc
               - containerPort: 9849
                 name: raft-rpc
               - containerPort: 7848
                 name: old-raft-rpc
             env:
               - name: NACOS_REPLICAS
                 value: "3"
               - name: MYSQL_SERVICE_HOST
                 valueFrom:
                   configMapKeyRef:
                     name: nacos-cm
                     key: mysql.host
               - name: MYSQL_SERVICE_DB_NAME
                 valueFrom:
                   configMapKeyRef:
                     name: nacos-cm
                     key: mysql.db.name
               - name: MYSQL_SERVICE_PORT
                 valueFrom:
                   configMapKeyRef:
                     name: nacos-cm
                     key: mysql.port
               - name: MYSQL_SERVICE_USER
                 valueFrom:
                   configMapKeyRef:
                     name: nacos-cm
                     key: mysql.user
               - name: MYSQL_SERVICE_PASSWORD
                 valueFrom:
                   configMapKeyRef:
                     name: nacos-cm
                     key: mysql.password
               - name: MODE
                 value: "cluster"
               - name: NACOS_SERVER_PORT
                 value: "8848"
               - name: PREFER_HOST_MODE
                 value: "hostname"
               - name: NACOS_SERVERS
                 value: "nacos-0.nacos-headless.nacos.svc.cluster.local:8848 nacos-1.nacos-headless.nacos.svc.cluster.local:8848 nacos-2.nacos-headless.nacos.svc.cluster.local:8848" # the "nacos" after "nacos-headless" & before "svc" , is NameSpace. when you defined another name , you should change it as the same.
     selector:
     	matchLabels:
         app: nacos
         
   ---
   # ------------------- App Ingress ------------------- #
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: nacos-headless
     namespace: nacos
   spec:
     rules:
     - host: nacos-k8s.wewoo.testing # Domain for your web access.
       http:
         paths:
         - path: /
           pathType: ImplementationSpecific
           #pathType: Prefix
           backend:
             service:
               name: nacos-headless
               port:
                 number: 8848
   ```

   

   