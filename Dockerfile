FROM ubuntu:18.04

ARG PHP_VERSION=7.3
ARG PHPMYADMIN=4.8.5

COPY ./scripts/autoclean.sh /root/
COPY ./scripts/docker-entrypoint.sh ./misc/cronfile.final ./misc/cronfile.system ./scripts/build.sql /

RUN echo $PHP_VERSION > /PHP_VERSION; \
chmod +x /root/autoclean.sh; \
chmod +x /docker-entrypoint.sh; \
mkdir /app; \
mkdir /run/php/; \
apt-get update; \
apt-get install -y software-properties-common apt-transport-https cron vim ssmtp monit wget unzip curl less git;

RUN add-apt-repository -y ppa:ondrej/php; \
export DEBIAN_FRONTEND=noninteractive; \ 
apt-get install -yq nginx php$PHP_VERSION php$PHP_VERSION-cli php$PHP_VERSION-common php$PHP_VERSION-curl php$PHP_VERSION-fpm php$PHP_VERSION-json php$PHP_VERSION-mysql php$PHP_VERSION-opcache php$PHP_VERSION-readline php$PHP_VERSION-xml php$PHP_VERSION-xsl php$PHP_VERSION-gd php$PHP_VERSION-intl php$PHP_VERSION-bz2 php$PHP_VERSION-bcmath php$PHP_VERSION-imap php$PHP_VERSION-gd php$PHP_VERSION-mbstring php$PHP_VERSION-pgsql php$PHP_VERSION-sqlite3 php$PHP_VERSION-xmlrpc php$PHP_VERSION-zip  php$PHP_VERSION-odbc php$PHP_VERSION-snmp php$PHP_VERSION-interbase php$PHP_VERSION-ldap php$PHP_VERSION-tidy php$PHP_VERSION-memcached php-tcpdf php-redis php-imagick php-mongodb; \
if [ $PHP_VERSION \> 7 ] && [ $PHP_VERSION \< 7.4 ]; then \
    echo 'deb https://packagecloud.io/phalcon/stable/ubuntu/ bionic main' > /etc/apt/sources.list.d/phalcon_stable.list; \
    echo 'deb-src https://packagecloud.io/phalcon/stable/ubuntu/ bionic main' >> /etc/apt/sources.list.d/phalcon_stable.list; \
    wget -qO- 'https://packagecloud.io/phalcon/stable/gpgkey' | apt-key add -; \
    apt-get update; \
    apt-get install php$PHP_VERSION-phalcon; \
fi; \
/usr/bin/unattended-upgrades -v; \
mkdir -p /app/public;

RUN apt-get install -yq mariadb-server mariadb-client; \
cd /var/www/html && ( \
  wget -q https://files.phpmyadmin.net/phpMyAdmin/$PHPMYADMIN/phpMyAdmin-$PHPMYADMIN-all-languages.zip; \
  unzip -oq phpMyAdmin-$PHPMYADMIN-all-languages.zip; \
  mv phpMyAdmin-$PHPMYADMIN-all-languages pma; \
  rm -f phpMyAdmin-$PHPMYADMIN-all-languages.zip; \
);

RUN mkdir /opt/wp-cli && \
cd /opt/wp-cli && ( \
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
chmod +x /opt/wp-cli/wp-cli.phar; \
ln -s /opt/wp-cli/wp-cli.phar /usr/local/bin/wp; \
)

RUN mkdir /opt/composer && \
cd /opt/composer && ( \
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"; \
php -r "if (hash_file('sha384', 'composer-setup.php') === 'a5c698ffe4b8e849a443b120cd5ba38043260d5c4023dbf93e1558871f1f07f58274fc6f4c93bcfd858c6bd0775cd8d1') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"; \
php composer-setup.php; \
php -r "unlink('composer-setup.php');"; \
chmod +x composer.phar; \
ln -s /opt/composer/composer.phar /usr/local/bin/composer \
)

RUN cd /opt && ( \
git clone https://github.com/phalcon/phalcon-devtools.git; \
cd phalcon-devtools; \
chmod +x phalcon; \
ln -s /opt/phalcon-devtools/phalcon /usr/local/bin/phalcon; \
)

COPY ./conf/ssmtp.conf.template /etc/ssmtp/
COPY ./monit/monitrc /etc/monit/
COPY ./monit/cron ./monit/php-fpm ./monit/nginx /etc/monit/conf-enabled/
COPY ./php/www.conf /etc/php/$PHP_VERSION/fpm/pool.d/
COPY ./php/php-fpm.conf ./php/php.ini ./conf/env.conf /etc/php/$PHP_VERSION/fpm/
COPY ./nginx/default /etc/nginx/sites-enabled/default
COPY ./phpmyadmin/config.inc.php /var/www/html/pma/config.inc.php

ENTRYPOINT ["/docker-entrypoint.sh"]
