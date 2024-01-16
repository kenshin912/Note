# Documentation of upgrading GitLab running on Docker

## Attention

FYI: The following content is Upgrade version about GitLab 11.0.1 to 16.5.1 . The GitLab is running on Docker version: 20.10.4 .

## Find Upgrade Path

[Upgrade Path](https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/)

Here is the link about how to upgrade gitlab step by step , just choose your current gitlab version and the target version you need.

remember select "Edition" , "Distro" , and ... "Go!"

BTW , you'd better use another machine to do Upgrade . when your upgrading is completed. Backup the files & transfer to the original GitLab server , restore data . then you got finished.

## Pull the images to the localhost

```bash
docker pull gitlab/gitlab-ce:16.5.1-ce.0
docker pull gitlab/gitlab-ce:16.3.6-ce.0
docker pull gitlab/gitlab-ce:16.1.5-ce.0
docker pull gitlab/gitlab-ce:15.11.13-ce.0
docker pull gitlab/gitlab-ce:15.4.6-ce.0
docker pull gitlab/gitlab-ce:15.0.5-ce.0
docker pull gitlab/gitlab-ce:14.10.5-ce.0
docker pull gitlab/gitlab-ce:14.9.5-ce.0
docker pull gitlab/gitlab-ce:14.3.6-ce.0
docker pull gitlab/gitlab-ce:14.0.12-ce.0
docker pull gitlab/gitlab-ce:13.12.15-ce.0
docker pull gitlab/gitlab-ce:13.8.8-ce.0
docker pull gitlab/gitlab-ce:13.1.11-ce.0
docker pull gitlab/gitlab-ce:13.0.14-ce.0
docker pull gitlab/gitlab-ce:12.10.14-ce.0
docker pull gitlab/gitlab-ce:12.1.17-ce.0
docker pull gitlab/gitlab-ce:12.0.12-ce.0
docker pull gitlab/gitlab-ce:11.11.8-ce.0
docker pull gitlab/gitlab-ce:11.0.1-ce.0
```

## Add docker-compose.yml

```yaml
version: '3.9'
  
services:
    gitlab:
        #image: gitlab/gitlab-ce:11.0.1-ce.0
        #image: gitlab/gitlab-ce:11.11.8-ce.0
        #image: gitlab/gitlab-ce:12.0.12-ce.0
        #image: gitlab/gitlab-ce:12.1.17-ce.0
        #image: gitlab/gitlab-ce:12.10.14-ce.0
        #image: gitlab/gitlab-ce:13.0.14-ce.0
        #image: gitlab/gitlab-ce:13.1.11-ce.0
        #image: gitlab/gitlab-ce:13.8.8-ce.0
        #image: gitlab/gitlab-ce:13.12.15-ce.0
        #image: gitlab/gitlab-ce:14.0.12-ce.0
        #image: gitlab/gitlab-ce:14.3.6-ce.0
        #image: gitlab/gitlab-ce:14.9.5-ce.0
        #image: gitlab/gitlab-ce:14.10.5-ce.0
        #image: gitlab/gitlab-ce:15.0.5-ce.0
        #image: gitlab/gitlab-ce:15.4.6-ce.0
        #image: gitlab/gitlab-ce:15.11.13-ce.0
        #image: gitlab/gitlab-ce:16.1.5-ce.0
        #image: gitlab/gitlab-ce:16.3.6-ce.0
        image: gitlab/gitlab-ce:16.5.1-ce.0
        container_name: gitlab
        ports:
            - "22:22"
            - "80:80"
            - "443:443"
        volumes:
            - /home/config/gitlab:/etc/gitlab
            - /home/gitlab/data:/var/opt/gitlab
            - /home/gitlab/logs:/var/log/gitlab
        environment:
            TZ: "Asia/Shanghai"
            GITLAB_OMNIBUS_CONFIG: |
                external_url "http://192.168.1.211"
                gitlab_rails['time_zone'] = "Asia/Shanghai"

                # Disable Email Feature
                gitlab_rails['smtp_enable'] = false
                gitlab_rails['gitlab_email_enabled'] = false
                gitlab_rails['incoming_email_enabled'] = false

                ## Disable Container Registry
                gitlab_rails['gitlab_default_projects_features_container_registry'] = false
                gitlab_rails['registry_enabled'] = false
                registry['enable'] = false
                registry_nginx['enable'] = false

                ## Disable Package Repository
                gitlab_rails['packages_enabled'] = false
                gitlab_rails['dependency_proxy_enabled'] = false

                # Disable Usage Statistics
                gitlab_rails['usage_ping_enabled'] = false
                gitlab_rails['sentry_enabled'] = false
                grafana['reporting_enabled'] = false

                ## Disable GitLab Pages
                gitlab_pages['enable'] = false
                pages_nginx['enable'] = false

                # Disable GitLab KAS
                gitlab_kas['enable'] = false
                gitlab_rails['gitlab_kas_enabled'] = false

                # Disable Terraform
                gitlab_rails['terraform_state_enabled'] = false

                # Disable Kerberos , it says EE only in Document，but still be true in default.
                gitlab_rails['kerberos_enabled'] = false

                # Disable Sentinel
                sentinel['enable'] = false

                # Disable Mattermost
                mattermost['enable'] = false
                mattermost_nginx['enable'] = false

                # Disable Prometheus & exporters , Performance standard etc.
                prometheus_monitoring['enable'] = false
                alertmanager['enable'] = false
                node_exporter['enable'] = false
                redis_exporter['enable'] = false
                postgres_exporter['enable'] = false
                pgbouncer_exporter['enable'] = false
                gitlab_exporter['enable'] = false
                sidekiq['metrics_enabled'] = false
                #grafana['enable'] = false

                # Disable PUMA cluster Mode.
                puma['worker_processes'] = 0
                puma['min_threads'] = 2
                puma['max_threads'] = 5

                # Decrease max_concurrency
                sidekiq['max_concurrency'] = 6
        privileged: true
        restart: always
        logging:
            driver: "json-file"
            options:
                max-size: "64m"
                max-file: "1"
        networks:
            - net

networks:
    net:
        driver: bridge
```

## DB Migration Attention

[Links](https://docs.gitlab.com/ee/update/background_migrations.html?tab=Linux+package+%28Omnibus%29#for-a-deployment-with-downtime)

```quote
To run all the batched background migrations, it can take a significant amount of time depending on the size of your GitLab installation.

Check the status of the batched background migrations in the database, and manually run them with the appropriate arguments until the status query returns no rows.
When the status of all of all them is marked as complete, re-run migrations for your installation.
Complete the database migrations from your GitLab upgrade:
......
```

When you running GitLab with version: 14.0.12 , DO NOT UPGRADE TO 14.3.6 WITHOUT "Batched background migrations" FINISHED!

At every step of running GitLab container when the version is above 14.3.6 , check the status about the "Background Migrations" in GitLab Admin Area , waiting for migrate queue finished. Run the following command below in GitLab Container.

```bash
gitlab-rake db:migrate

gitlab-ctl reconfigure
```
