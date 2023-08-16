FROM ubuntu:22.04

ARG PHP_VERSION=8.2
ARG PHALCON_VERSION="3.4.5-1"
ARG PHPMYADMIN_OLD=4.8.5
ARG PHPMYADMIN=5.2.1

COPY ./scripts/autoclean.sh /root/
COPY ./scripts/docker-entrypoint.sh ./misc/cronfile.final ./misc/cronfile.system ./scripts/build.sql /

RUN echo $PHP_VERSION > /PHP_VERSION; \
    chmod +x /root/autoclean.sh; \
    chmod +x /docker-entrypoint.sh; \
    mkdir /app; \
    mkdir /run/php/; \
    mkdir -p /app/public; \
    apt-get update;

RUN export DEBIAN_FRONTEND=noninteractive; apt-get install -yq software-properties-common apt-transport-https \
    cron vim ssmtp monit wget unzip curl less git; \
    /usr/bin/unattended-upgrades -v;

RUN apt-get install -y nginx;

#oh maria!
RUN export DEBIAN_FRONTEND=noninteractive; apt-get install -yq mariadb-server mariadb-client; \
    if [ $PHP_VERSION \< 8 ]; then \
         PHPMYADMIN="${PHPMYADMIN_OLD}"; \
    fi; \
    cd /var/www/html && ( \
      wget -q https://files.phpmyadmin.net/phpMyAdmin/$PHPMYADMIN/phpMyAdmin-$PHPMYADMIN-all-languages.zip; \
      unzip -oq phpMyAdmin-$PHPMYADMIN-all-languages.zip; \
      mv phpMyAdmin-$PHPMYADMIN-all-languages pma; \
      rm -f phpMyAdmin-$PHPMYADMIN-all-languages.zip; \
    );

#php-base
RUN add-apt-repository -y ppa:ondrej/php;
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get install -yq php$PHP_VERSION php$PHP_VERSION-cli \
    php$PHP_VERSION-common php$PHP_VERSION-curl php$PHP_VERSION-fpm \
    php$PHP_VERSION-mysql php$PHP_VERSION-opcache php$PHP_VERSION-readline \
    php$PHP_VERSION-xml php$PHP_VERSION-xsl php$PHP_VERSION-gd php$PHP_VERSION-intl \
    php$PHP_VERSION-bz2 php$PHP_VERSION-bcmath php$PHP_VERSION-imap php$PHP_VERSION-gd \
    php$PHP_VERSION-mbstring php$PHP_VERSION-pgsql php$PHP_VERSION-sqlite3 \
    php$PHP_VERSION-xmlrpc php$PHP_VERSION-zip php$PHP_VERSION-odbc php$PHP_VERSION-snmp \
    php$PHP_VERSION-interbase php$PHP_VERSION-ldap php$PHP_VERSION-tidy \
    php$PHP_VERSION-memcached php-tcpdf php$PHP_VERSION-redis php$PHP_VERSION-imagick php$PHP_VERSION-mongodb; \
    if [ $PHP_VERSION \< 8 ]; then \
      apt-get install -yq php$PHP_VERSION-json; \
    fi;  \
    if [ $PHP_VERSION != 8.2 ]; then \
      apt remove -fyq php8.2*; apt -fyq autoremove; \
    fi;

#php-phalcon
#RUN if [ $PHP_VERSION \> 7 ]; then \
#        echo 'deb https://packagecloud.io/phalcon/stable/ubuntu/ bionic main' > /etc/apt/sources.list.d/phalcon_stable.list; \
#        echo 'deb-src https://packagecloud.io/phalcon/stable/ubuntu/ bionic main' >> /etc/apt/sources.list.d/phalcon_stable.list; \
#        wget -qO- 'https://packagecloud.io/phalcon/stable/gpgkey' | apt-key add -; \
#        apt-get update; \
#        if [ $PHP_VERSION \< 7.4 ]; then \
#            apt-get install -yq php$PHP_VERSION-phalcon=$PHALCON_VERSION+php$PHP_VERSION; \
#        fi; \
#        if [ $PHP_VERSION \> 7.3 ] && [ $PHP_VERSION \< 8 ]; then \
#            apt-get install -yq php$PHP_VERSION-phalcon php-psr; \
#        fi; \
#    fi;

#wp-cli
RUN mkdir /opt/wp-cli && \
    cd /opt/wp-cli && ( \
        wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
        chmod +x /opt/wp-cli/wp-cli.phar; \
        ln -s /opt/wp-cli/wp-cli.phar /usr/local/bin/wp; \
    )

#let`s compose!
RUN mkdir /opt/composer; \
    cd /opt/composer && ( \
        wget https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer -O - -q | php -- --quiet; \
        ln -s /opt/composer/composer.phar /usr/local/bin/composer; \
    )

#phalcon devtools
#RUN cd /opt && ( \
#        git clone https://github.com/phalcon/phalcon-devtools.git; \
#        cd phalcon-devtools; \
#        chmod +x phalcon; \
#        ln -s /opt/phalcon-devtools/phalcon /usr/local/bin/phalcon; \
#    )
    
## Install Symfony CLI
RUN curl -sS https://get.symfony.com/cli/installer | bash
RUN mv $HOME/.symfony5/bin/symfony /usr/local/bin/symfony

COPY ./conf/ssmtp.conf.template /etc/ssmtp/
COPY ./monit/monitrc /etc/monit/
COPY ./monit/cron ./monit/php-fpm ./monit/nginx /etc/monit/conf-enabled/
COPY ./php/www.conf /etc/php/$PHP_VERSION/fpm/pool.d/
COPY ./php/php-fpm.conf ./php/php.ini ./conf/env.conf /etc/php/$PHP_VERSION/fpm/
COPY ./nginx/default /etc/nginx/sites-enabled/default
COPY ./phpmyadmin/config.inc.php /var/www/html/pma/config.inc.php

ENTRYPOINT ["/docker-entrypoint.sh"]
