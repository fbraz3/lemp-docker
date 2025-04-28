FROM php:8.2-cli AS php-tools

RUN apt-get update && apt-get install -y curl unzip wget git \
 && mkdir -p /opt/tools

# Composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /opt/tools/composer && \
    ln -s /opt/tools/composer /usr/local/bin/composer

# WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && mv wp-cli.phar /opt/tools/wp && \
    ln -s /opt/tools/wp /usr/local/bin/wp

# Symfony CLI
RUN curl -sS https://get.symfony.com/cli/installer | bash && \
    mv $HOME/.symfony*/bin/symfony /opt/tools/symfony && \
    ln -s /opt/tools/symfony /usr/local/bin/symfony


FROM ubuntu:22.04

ARG TARGETPLATFORM
ARG PHP_VERSION=5.6
ARG PHALCON_VERSION="3.4.5-1"
ARG PHPMYADMIN_OLD=4.8.5
ARG PHPMYADMIN=5.2.2

ENV DEBIAN_FRONTEND=noninteractive

COPY ./scripts/docker-entrypoint.sh ./misc/cronfile.final ./misc/cronfile.system ./scripts/build.sql /

RUN echo $PHP_VERSION > /PHP_VERSION; \
    chmod +x /docker-entrypoint.sh; \
    mkdir /app; \
    mkdir /run/php/; \
    mkdir -p /app/public; \
    apt-get update;

RUN apt-get install -yq software-properties-common \
    apt-transport-https cron vim ssmtp monit wget unzip curl less git

RUN apt-get install -y nginx;

#oh maria!
RUN apt-get install -yq mariadb-server mariadb-client; \
    if [ $PHP_VERSION \< 8 ]; then \
         PHPMYADMIN="${PHPMYADMIN_OLD}"; \
    fi; \
    cd /var/www/html && ( \
      wget -q https://files.phpmyadmin.net/phpMyAdmin/$PHPMYADMIN/phpMyAdmin-$PHPMYADMIN-all-languages.zip; \
      unzip -oq phpMyAdmin-$PHPMYADMIN-all-languages.zip; \
      mv phpMyAdmin-$PHPMYADMIN-all-languages pma; \
      rm -f phpMyAdmin-$PHPMYADMIN-all-languages.zip; \
      mkdir /tmp/session && chmod 777 /tmp/session; \
    );

#php-base
RUN add-apt-repository -y ppa:ondrej/php; \
    apt-get install -yq php$PHP_VERSION php$PHP_VERSION-cli \
    php$PHP_VERSION-common php$PHP_VERSION-curl php$PHP_VERSION-fpm \
    php$PHP_VERSION-mysql php$PHP_VERSION-opcache php$PHP_VERSION-readline \
    php$PHP_VERSION-xml php$PHP_VERSION-xsl php$PHP_VERSION-gd php$PHP_VERSION-intl \
    php$PHP_VERSION-bz2 php$PHP_VERSION-bcmath php$PHP_VERSION-imap php$PHP_VERSION-gd \
    php$PHP_VERSION-mbstring php$PHP_VERSION-pgsql php$PHP_VERSION-sqlite3 \
    php$PHP_VERSION-xmlrpc php$PHP_VERSION-zip php$PHP_VERSION-odbc php$PHP_VERSION-snmp \
    php$PHP_VERSION-interbase php$PHP_VERSION-ldap php$PHP_VERSION-tidy \
    php$PHP_VERSION-memcached php$PHP_VERSION-redis php$PHP_VERSION-imagick php$PHP_VERSION-mongodb;

RUN if dpkg --compare-versions "${PHP_VERSION}" gt "7.1" && dpkg --compare-versions "${PHP_VERSION}" lt "8.0"; then \
      apt-get install -y "php${PHP_VERSION}-phalcon4"; \
    else \
      apt-get install -y "php${PHP_VERSION}-phalcon"; \
    fi; \
    if dpkg --compare-versions "${PHP_VERSION}" eq "7.2"; then \
      apt-get remove -y "php${PHP_VERSION}-phalcon4"; \
      apt-get install -y "php${PHP_VERSION}-phalcon3"; \
    fi

# Copy Tools
COPY --from=php-tools /usr/local/bin/composer /usr/local/bin/composer
COPY --from=php-tools /usr/local/bin/wp /usr/local/bin/wp
COPY --from=php-tools /usr/local/bin/symfony /usr/local/bin/symfony

RUN update-alternatives  --set php /usr/bin/php$PHP_VERSION

# Ensure PHP version is the correct one
RUN if [ $PHP_VERSION != $(php -v |head -n1 | awk '{print $2}' | awk -F'.' '{print $1"."$2}') ]; then exit 1; fi

COPY ./conf/ssmtp.conf.template /etc/ssmtp/
COPY ./monit/monitrc /etc/monit/
COPY ./monit/cron ./monit/php-fpm ./monit/nginx /etc/monit/conf-enabled/
COPY ./php/www.conf /etc/php/$PHP_VERSION/fpm/pool.d/
COPY ./php/php-fpm.conf ./php/php.ini ./conf/env.conf /etc/php/$PHP_VERSION/fpm/
COPY ./nginx/default /etc/nginx/sites-enabled/default
COPY ./phpmyadmin/config.inc.php /var/www/html/pma/config.inc.php

ENTRYPOINT ["/docker-entrypoint.sh"]