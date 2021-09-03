# Docker-compose Install

## Visit compose on Gitlab to get Latest Release

<https://github.com/docker/compose/releases/>

## Download compose on Linux x86_64

```bash
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

chmod a+x /usr/local/bin/docker-compose

ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

docker-compose --version
```
