# GitLab Upgrade Documentation

## Overview

This document provides a step-by-step guide for upgrading GitLab from version **11.0.1** to **16.5.1**. The GitLab instance is running inside a **Docker** container, specifically using **Docker version 20.10.4**.

## Determine the Upgrade Path

Refer to the official [Upgrade Path](https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/) to find the correct sequence of versions for a smooth upgrade. Simply:

1. Select your **current GitLab version**.
2. Choose your **target version**.
3. Specify the **Edition** and **Distribution**.
4. Click **Go!**

**Recommendation:** It is best to perform the upgrade on a separate machine first. Once the upgrade is completed successfully, back up the files, transfer them to the original GitLab server, and restore the data.

## Pull the Required GitLab Images

To ensure a smooth upgrade, pull all necessary GitLab images in the correct upgrade sequence:

```shell
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

## Create a `docker-compose.yml` File

The following `docker-compose.yml` file is configured for GitLab with necessary optimizations and feature disablement.

```yaml
version: '3.9'

services:
    gitlab:
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

                # Disable Unused Features
                gitlab_rails['gitlab_default_projects_features_container_registry'] = false
                gitlab_rails['registry_enabled'] = false
                gitlab_rails['packages_enabled'] = false
                gitlab_rails['dependency_proxy_enabled'] = false
                gitlab_rails['usage_ping_enabled'] = false
                gitlab_rails['sentry_enabled'] = false
                grafana['reporting_enabled'] = false
                gitlab_pages['enable'] = false
                pages_nginx['enable'] = false
                gitlab_kas['enable'] = false
                gitlab_rails['gitlab_kas_enabled'] = false
                gitlab_rails['terraform_state_enabled'] = false
                gitlab_rails['kerberos_enabled'] = false
                sentinel['enable'] = false
                mattermost['enable'] = false
                mattermost_nginx['enable'] = false
                prometheus_monitoring['enable'] = false
                alertmanager['enable'] = false
                node_exporter['enable'] = false
                redis_exporter['enable'] = false
                postgres_exporter['enable'] = false
                pgbouncer_exporter['enable'] = false
                gitlab_exporter['enable'] = false
                sidekiq['metrics_enabled'] = false

                # Optimize Puma (Web Server)
                puma['worker_processes'] = 0
                puma['min_threads'] = 2
                puma['max_threads'] = 5

                # Reduce Sidekiq Concurrency
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

## Database Migration Considerations

Refer to the official GitLab documentation on [Batched Background Migrations](https://docs.gitlab.com/ee/update/background_migrations.html?tab=Linux+package+(Omnibus)#for-a-deployment-with-downtime) before proceeding with the upgrade.

### Important Notes

- **When running GitLab version 14.0.12**, **DO NOT** upgrade to **14.3.6** without completing the batched background migrations.
- For **GitLab versions above 14.3.6**, always check the status of background migrations in the **GitLab Admin Area** before proceeding to the next version.

### Run Database Migrations

Execute the following commands inside the running GitLab container to ensure all migrations are completed:

```shell
gitlab-rake db:migrate
gitlab-ctl reconfigure
```

## Conclusion

Following this structured upgrade process will help avoid common pitfalls when upgrading GitLab in a Docker environment. Always verify database migrations at each step and back up your data before proceeding with the next version.
