ARG PHP_VERSION=8.2
ARG BUILD_ARCH="amd64"
ARG BUILD_FLAVOR=""
FROM fbraz3/php-nginx:$PHP_VERSION$BUILD_FLAVOR
USER root

ARG PHP_VERSION
ARG BUILD_ARCH
ENV DEBIAN_FRONTEND=noninteractive
ENV ENTRYPOINT_COMMAND="/usr/bin/tail -f /var/log/nginx/*.log"

ARG PHPMYADMIN_OLD=4.8.5
ARG PHPMYADMIN=5.2.2

# TODO list
# Rearrange directory structure                | OK
# filter entrypoint to mysql/pma stuff only    | OK
# copy entrypoint to /entrypoints folder       | OK
# refactor dockerfile to use php-fpm image     | OK
# compile and test loccaly                     | OK
# add code of conduct and contributing.md      | OK
# remove unused files                          | OK
# Create gh actions for build and push         | OK
# Define tests for each flavor                 | OK
# Implement tests for each flavor              | OK
# refactor README.md                           | OK
# add both lemp and lnmp variants              | OK
# enable cron build                            | OK
# remove alpha suffix from tags                | OK
# Update readme with deepwiki link             | OK
# Create build status badges                   | OK
# merge to main branch                         |
# Create deepwiki page                         |
# Enable funding on github                     | OK
# Update dockerhub images description          |


COPY ../../assets/scripts/docker-entrypoint.sh /entrypoints/3-mariadb-entrypoint.sh
RUN chmod +x /entrypoints/3-mariadb-entrypoint.sh

#oh maria!
RUN for i in {1..10}; do \
      apt-get install -yq mariadb-server mariadb-client && break || sleep 10; \
    done

#phpmyadmin
RUN if [ $PHP_VERSION \< 8 ]; then \
         PHPMYADMIN="${PHPMYADMIN_OLD}"; \
    fi; \
    cd /var/www/html && ( \
      wget -q https://files.phpmyadmin.net/phpMyAdmin/$PHPMYADMIN/phpMyAdmin-$PHPMYADMIN-all-languages.zip; \
      unzip -oq phpMyAdmin-$PHPMYADMIN-all-languages.zip; \
      mv phpMyAdmin-$PHPMYADMIN-all-languages pma; \
      rm -f phpMyAdmin-$PHPMYADMIN-all-languages.zip; \
      mkdir /tmp/session && chmod 777 /tmp/session; \
    );

COPY ../../assets/phpmyadmin/config.inc.php /var/www/html/pma/config.inc.php
COPY ../../assets/mariadb/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY ../../assets/nginx/pma.conf /etc/nginx/custom-conf/01-pma.conf
COPY ../../assets/monit/mariadb /etc/monit/conf-enabled/

# try to install buils.sql in execution time
COPY ../../assets/scripts/build.sql /

# Create app user and database
RUN /etc/init.d/mariadb start || exit 1; \
    sleep 5; \
    mysql < /build.sql; \
    /etc/init.d/mariadb stop

RUN chown -R www-data. /run/mysqld; \
    chown -R www-data. /usr/lib/mysql; \
    chown -R www-data. /var/log/mysql; \
    chown -R www-data. /var/lib/mysql; \
    chown -R www-data. /lib/mysql/; \
    chown -R www-data. /etc/mysql/;

USER www-data
ENTRYPOINT ["/docker-entrypoint.sh"]