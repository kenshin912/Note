### Nginx Ingress 配置 HTTPS

#### 创建 Secret

```bash
kubectl create secret tls ${cert_name} --key ${key_file} --cert ${cert_file} -n ${namespace}
```

> 创建 Secret 的时候 , 尽量和 ingress 实例在一个 namespace 下.

```bash
kubectl create secret tls ingress-tls-cert --key 123.com.key --cert 123.com.pem
```

> 默认 default namespace 的时候 , 不必带 -n 参数.



#### 配置 Ingress 开启 TLS

修改 ingress 的定义文件 , 添加 `tls` 相关内容

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
    name: erp-frontend
    annotations:
        nginx.ingress.kubernetes.io/ssl-redirect: "true" #
spec:
    tls:
    - hosts:
      - k8s.wewoerp.com
      secretName: ingress-tls-cert
    rules:
    - host: k8s.wewoerp.com
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
                name: erp-frontend-service
                port:
                    number: 80
```

根据官方文档 , HTTP 跳转 HTTPS , 默认情况下 , 如果 ingress 启用了 TLS , 则控制器会使用 308 永久重定向响应 , 将 HTTP 重定向到 HTTPS , 如果没有生效 , 可以如上所示 , 将 `nginx.ingress.kubernetes.io/ssl-redirect` 设置为 `true`

修改完成后 , 直接 apply 即可.

```bash
kubectl apply -f ingress.yaml
```

⚠️ 注意 : 一个 ingress 只能使用一个 secret , 也就是说只能使用一个证书 , 如果一个 ingress 里面配置了多个域名 , 那么必须保证该证书支持该 ingress 下所有域名. 并且这个 secretName 一定要放在域名列表的最后位置; 同时上面的 hosts 段域名必须和下方 rules 中完全匹配.