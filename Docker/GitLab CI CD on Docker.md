# GitLab CI/CD on Docker

## Install GitLab Runner

```shell
sudo docker pull gitlab/gitlab-runner

sudo docker run -d --name gitlab-runner --restart=always -v /home/kood/docker:/home/kood/docker -v /home/kood/gitlab-runner/config:/etc/gitlab-runner -v /var/run/docker.sock:/var/run/docker.sock gitlab/gitlab-runner:latest
```

mapping *docker directory* to the same path in gitlab-runner container