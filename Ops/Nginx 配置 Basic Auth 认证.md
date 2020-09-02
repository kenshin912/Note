# Nginx Basic Auth

## Why use Basic Auth

We have a reverse proxy to internal kibana , but there's no auth require of kibana basic license , so we need to use nginx basic auth

## Install http-tools

> yum install httpd-tools

## Password generate

> htpasswd -bc /root/auth.db root 123456

## Enable Basic Auth in Nginx

```conf
location / {
        proxy_redirect     off;
        proxy_buffering    off;
        proxy_max_temp_file_size 0;
        proxy_set_header   Host     $host;
        proxy_set_header   X-Real-IP    $remote_addr;
        proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
        auth_basic  "Authorized require";
        auth_basic_user_file    /etc/nginx/ssl/auth.db;
        proxy_pass         http://172.16.159.23:5601/;
        break;
    }
```

## Disable Proxy buffering & temp_file_size

Add `proxy_max_temp_file_size 0;` to Reverse Proxy setting
to avoid warning log like the following code in error_log

```log
an upstream response is buffered to a temporary file
```
