ARG PHP_VERSION=8.2
ARG BUILD_ARCH="amd64"
ARG BUILD_FLAVOR=""

FROM fbraz3/php-nginx:$PHP_VERSION$BUILD_FLAVOR
USER root

ARG PHP_VERSION
ARG BUILD_ARCH
ENV DEBIAN_FRONTEND=noninteractive
ENV ENTRYPOINT_COMMAND="/usr/bin/tail -f /var/log/nginx/*.log"

# Install MariaDB dependencies with retry logic for reliability
RUN apt-get update && apt-get upgrade -y && \
    for i in {1..10}; do \
      apt-get install -yq mariadb-server mariadb-client && break || sleep 10; \
    done && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy configuration files and scripts
COPY ../../assets/scripts/docker-entrypoint-prod.sh /entrypoints/3-mariadb-entrypoint.sh
COPY ../../assets/mariadb/50-server-prod.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY ../../assets/monit/mariadb /etc/monit/conf-enabled/
COPY ../../assets/scripts/build-prod.sql /

# Setup database, create SQL scripts directory, and fix permissions in one optimized layer
RUN chmod +x /entrypoints/3-mariadb-entrypoint.sh && \
    /etc/init.d/mariadb start && \
    sleep 5 && \
    mysql < /build-prod.sql && \
    /etc/init.d/mariadb stop && \
    mkdir /sql-scripts && chmod 755 /sql-scripts && \
    chown -R www-data. /sql-scripts /run/mysqld /usr/lib/mysql /var/log/mysql /var/lib/mysql /lib/mysql/ /etc/mysql/

USER www-data
ENTRYPOINT ["/docker-entrypoint.sh"]
