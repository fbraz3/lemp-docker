ARG PHP_VERSION=8.2
ARG BUILD_ARCH="amd64"
ARG BUILD_FLAVOR=""

# Stage 1: Build and download stage
FROM fbraz3/php-nginx:$PHP_VERSION$BUILD_FLAVOR as builder
USER root

ARG PHP_VERSION
ARG BUILD_ARCH
ARG PHPMYADMIN_OLD=4.8.5
ARG PHPMYADMIN=5.2.2
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y && \
    for i in {1..10}; do \
        apt-get install -yq wget unzip && break || sleep 10; \
    done && \
    if [ "$(echo "$PHP_VERSION" | cut -d. -f1)" -lt 8 ]; then \
        PHPMYADMIN="${PHPMYADMIN_OLD}"; \
    else \
        PHPMYADMIN="${PHPMYADMIN}"; \
    fi && \
    cd /var/www/html && \
    wget -q "https://files.phpmyadmin.net/phpMyAdmin/$PHPMYADMIN/phpMyAdmin-$PHPMYADMIN-all-languages.zip" && \
    [ -f "phpMyAdmin-$PHPMYADMIN-all-languages.zip" ] || { echo "phpMyAdmin download failed"; exit 1; } && \
    unzip -oq "phpMyAdmin-$PHPMYADMIN-all-languages.zip" && \
    mv "phpMyAdmin-$PHPMYADMIN-all-languages" pma && \
    rm -f "phpMyAdmin-$PHPMYADMIN-all-languages.zip" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Stage 2: Final runtime stage
FROM fbraz3/php-nginx:$PHP_VERSION$BUILD_FLAVOR
USER root

ARG PHP_VERSION
ARG BUILD_ARCH
ENV DEBIAN_FRONTEND=noninteractive
ENV ENTRYPOINT_COMMAND="/usr/bin/tail -f /var/log/nginx/*.log"

RUN apt-get update && \
    for i in {1..10}; do \
        apt-get install -yq mariadb-server mariadb-client && break || sleep 10; \
    done && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /var/www/html/pma /var/www/html/pma

COPY ../../assets/scripts/docker-entrypoint.sh /entrypoints/3-mariadb-entrypoint.sh
COPY ../../assets/phpmyadmin/config.inc.php /var/www/html/pma/config.inc.php
COPY ../../assets/mariadb/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY ../../assets/nginx/pma.conf /etc/nginx/custom-conf/01-pma.conf
COPY ../../assets/monit/mariadb /etc/monit/conf-enabled/
COPY ../../assets/scripts/build.sql /

# Setup database, create phpMyAdmin session directory with secure permissions, and fix ownership
RUN chmod +x /entrypoints/3-mariadb-entrypoint.sh && \
    /etc/init.d/mariadb start && \
    sleep 5 && \
    mysql < /build.sql && \
    /etc/init.d/mariadb stop && \
    mkdir /tmp/session && chmod 750 /tmp/session && chown www-data:www-data /tmp/session && \
    chown -R www-data. /run/mysqld /usr/lib/mysql /var/log/mysql /var/lib/mysql /lib/mysql/ /etc/mysql/

USER www-data
ENTRYPOINT ["/docker-entrypoint.sh"]
