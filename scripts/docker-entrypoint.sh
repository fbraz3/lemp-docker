#!/bin/bash

$(which chmod) 700 /etc/monit/monitrc

#CLEAR TMP FILES
/root/autoclean.sh

#ADD CRON
CRONFILE="/cronfile.final"
SYSTEMCRON="/cronfile.system"
USERCRON="/cronfile"

echo > $CRONFILE
if [ -f "$SYSTEMCRON" ]; then
	cat $SYSTEMCRON >> $CRONFILE
fi
if [ -f "$USERCRON" ]; then
	cat $USERCRON >> $CRONFILE
fi
/usr/bin/crontab $CRONFILE

#DECLARE/SET VARIABLES
PHPVERSION=`cat /PHP_VERSION 2>/dev/null`
if [ -z "$PHPVERSION" ]; then
    PHPVERSION=`php -v|grep --only-matching --perl-regexp "7\.\\d+" |head -n1`
fi

if [ -z "$PHPVERSION" ]; then
    PHPVERSION='7.3'
fi

#SORRY FOR THAT =(
if [ -f "/etc/php/fpm/php-fpm.conf" ]; then
    $(which cp) -f /etc/php/fpm/php-fpm.conf /etc/php/$PHPVERSION/fpm/php-fpm.conf
fi

if [ -f "/etc/php/fpm/php.ini" ]; then
    $(which cp) -f /etc/php/fpm/php.ini /etc/php/$PHPVERSION/fpm/php.ini
fi

if [ -f "/etc/php/fpm/pool.d/www.conf" ]; then
    $(which cp) -f /etc/php/fpm/pool.d/www.conf /etc/php/$PHPVERSION/fpm/pool.d/www.conf
fi

#POPULATE ENV
echo > /etc/php/$PHPVERSION/fpm/env.conf
for i in `/usr/bin/env`; do
    PARAM=`echo $i |cut -d"=" -f1`
    VAL=`echo $i |cut -d"=" -f2`
    echo "env[$PARAM]=\"$VAL\"" >> /etc/php/$PHPVERSION/fpm/env.conf
done

#PUPULATE TEMPLATES
cp -f /etc/ssmtp/ssmtp.conf.template /etc/ssmtp/ssmtp.conf
sed -i 's/%MY_HOSTNAME%/'`/bin/hostname`'/g' /etc/ssmtp/ssmtp.conf

$(which sed) -i 's/%PHP_VERSION%/'$PHPVERSION'/g' /etc/monit/conf-enabled/php-fpm
$(which sed) -i 's/%PHP_VERSION%/'$PHPVERSION'/g' /etc/php/$PHPVERSION/fpm/pool.d/www.conf
$(which sed) -i 's/%PHP_VERSION%/'$PHPVERSION'/g' /etc/php/$PHPVERSION/fpm/php-fpm.conf
$(which sed) -i 's/%PHP_VERSION%/'$PHPVERSION'/g' /etc/nginx/sites-available/default


#START SERVICES
/etc/init.d/cron restart
/etc/init.d/php$PHPVERSION-fpm restart
/etc/init.d/mysql restart
/etc/init.d/nginx restart
sleep 1
/etc/init.d/monit restart

#Create mariadb user
mysql < /build.sql

#KEEP CONTAINER ALIVE
/usr/bin/tail -f /var/log/nginx/access.log
