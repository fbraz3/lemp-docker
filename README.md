# LNMP
This is an image with **L**inux (Ubuntu 18.04 LTS), **N**ginx, **M**ySQL and **P**HP-FPM 

## Features
 - *Multi Version:* All supported PHP versions available
 - *Up-to-Date:* Images auto-updated every week
 - *Secure:* Cron job auto installed into containers to apply security updates every night;
 - *Green light to send emails:* PHP mail() working like a charm;
 - *Schedule jobs:* cron command installed;

## Ready-to-go images
Check out on [Docker Hub](https://hub.docker.com/r/fbraz3/lnmp)

Source code on [GitHub](https://github.com/fbraz3/lemp-docker)

# Using this image
Just create a docker-compose.yml on your application root path and run
```sh
docker-compose up -d
```
Configure your **mysql database access** to host **127.0.0.1**, username **root**, **no password** and to database **app**

Your main application will be accessible on **http://localhost/** and phpmyadmin on **http://localhost/pma/**

Note: If you are using **zend framework** 1 or 2, just modify **docker-compose.yml** volume to ./:/app/

### The **docker-compose.yml** file
```yml
services:
  web:
   image: fbraz3/lnmp
   volumes:
   - ./:/app/public/
   ports:
   - "127.0.0.1:80:80"
   - "127.0.0.1:3306:3306"
```

## Sending Emails
First of all, create a network called `dockernet` using range `192.168.0.0/24` to get emails working over ssmtp email proxy.
```
# docker network create --subnet=192.168.0.0/24 dockernet
```
edit `/etc/postfix/main.cf` and add 192.168.0.0/24 on `mynetworks` params.
```
mynetworks = 127.0.0.0/8 192.168.0.0/24 [::ffff:127.0.0.0]/104 [::1]/128
```
Restart postfix
```
systemctl restart postfix
```

## Cronjob

System reads `/cronfile` file and installs using `cron`.

To use it just add your commands to a single file and bind it to `/cronfile` as follows.

```
  [...]
     volumes:
        - /my/app/root/:/app
        - /my/cronfile:/cronfile
  [...]
```

# TAGS

- **tag name**  = PHP Version
- **latest**  = PHP 8.3
