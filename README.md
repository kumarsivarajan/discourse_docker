# Introduction

This repo is used to build the form service in `discussions.youdaxue.com`.

It use the open source discourse docker distribution https://github.com/discourse/discourse_docker

Please take a look at the doc above, it contains key informations about the general management.

In China, we have some custom settings that is alreay changed for China specific.

The directory in ec2 instance is `/var/discourse`

# Key configuration

- `/var/discourse/containers/app.yml`

    This is the container configuration to start containers



- `/var/discourse/templates/web.china.template.yml`

   Modify the gem source in China


 # Architecture

 Take a look at `/var/discourse/containers/app.yml` and `matrix/app.tf`

 We have a postgres in RDS, redis in ElastiCache.


# Admiistration task

- Backup db http://discussions.youdaxue.com/admin/backups
- Discoruse plugin: http://discussions.youdaxue.com/admin/plugins
