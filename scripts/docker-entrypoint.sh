#!/bin/bash

$(which chmod) 700 /etc/monit/monitrc

# CLEAR TMP FILES
/root/autoclean.sh

# ADD CRON
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

# DECLARE/SET VARIABLES
PHPVERSION=`cat /PHP_VERSION 2>/dev/null`
if [ -z "$PHPVERSION" ]; then
    PHPVERSION=`php -v|grep --only-matching --perl-regexp "7\.\\d+" |head -n1`
fi

if [ -z "$PHPVERSION" ]; then
    PHPVERSION='7.3'
fi

# SET CUSTOM ID FOR www-data USER
if  [[ ! -z "$DATA_UID" ]] && [[ $DATA_UID =~ ^[0-9]+$ ]] ; then
	$(which usermod) -u $DATA_UID www-data;
fi

# SET CUSTOM ID FOR www-data GROUP
if  [[ ! -z "$DATA_GUID" ]] && [[ $DATA_GUID =~ ^[0-9]+$ ]] ; then
	$(which groupmod) -g $DATA_GUID www-data;
fi

# SORRY FOR THAT =(
if [ -f "/etc/php/fpm/php-fpm.conf" ]; then
    $(which cp) -f /etc/php/fpm/php-fpm.conf /etc/php/$PHPVERSION/fpm/php-fpm.conf
fi

if [ -f "/etc/php/fpm/php.ini" ]; then
    $(which cp) -f /etc/php/fpm/php.ini /etc/php/$PHPVERSION/fpm/php.ini
fi

if [ -f "/etc/php/fpm/pool.d/www.conf" ]; then
    $(which cp) -f /etc/php/fpm/pool.d/www.conf /etc/php/$PHPVERSION/fpm/pool.d/www.conf
fi

# POPULATE TEMPLATES
cp -f /etc/ssmtp/ssmtp.conf.template /etc/ssmtp/ssmtp.conf
sed -i 's/%MY_HOSTNAME%/'`/bin/hostname`'/g' /etc/ssmtp/ssmtp.conf

$(which sed) -i 's/%PHP_VERSION%/'$PHPVERSION'/g' /etc/monit/conf-enabled/php-fpm
$(which sed) -i 's/%PHP_VERSION%/'$PHPVERSION'/g' /etc/php/$PHPVERSION/fpm/pool.d/www.conf
$(which sed) -i 's/%PHP_VERSION%/'$PHPVERSION'/g' /etc/php/$PHPVERSION/fpm/php-fpm.conf
$(which sed) -i 's/%PHP_VERSION%/'$PHPVERSION'/g' /etc/nginx/sites-available/default

# POPULATE VARIABLES
echo > /etc/php/$PHPVERSION/fpm/env.conf
echo > /etc/php/$PHPVERSION/fpm/overrides.conf
echo > /etc/php/$PHPVERSION/fpm/pool-overrides.conf
echo > /etc/php/$PHPVERSION/fpm/phpconf.conf
for i in `/usr/bin/env`; do
    PARAM=`echo $i |cut -d"=" -f1`
    VAL=`echo $i |cut -d"=" -f2`

    if [[ "$PARAM" == "_" ]]; then
        continue
    fi

    if [[ $PARAM =~ ^PHPADMIN_.+ ]]; then
        PHPPARAM=`echo $PARAM |sed 's/PHPADMIN_//g' | sed 's/__/./g' | awk '{print tolower($0)}'`
        echo "PHPADMIN   :: $PHPPARAM => $VAL"
        echo "php_admin_value[$PHPPARAM] =\"$VAL\"" >> /etc/php/$PHPVERSION/fpm/phpconf.conf

    elif [[ $PARAM =~ ^PHPFLAG_.+ ]]; then
        PHPPARAM=`echo $PARAM |sed 's/PHPFLAG_//g' | sed 's/__/./g' | awk '{print tolower($0)}'`
        echo "PHPFLAG    :: $PHPPARAM => $VAL"
        echo "php_flag[$PHPPARAM]=\"$VAL\"" >> /etc/php/$PHPVERSION/fpm/phpconf.conf

    elif [[ $PARAM =~ ^FPMCONFIG_.+ ]]; then
        FPMPARAM=`echo $PARAM |sed 's/FPMCONFIG_//g' | sed 's/__/./g' | awk '{print tolower($0)}'`
        echo "FPMCONFIG  :: $FPMPARAM => $VAL"
        echo "$FPMPARAM = $VAL" >> /etc/php/$PHPVERSION/fpm/overrides.conf

    elif [[ $PARAM =~ ^POOLCONFIG_.+ ]]; then
        FPMPARAM=`echo $PARAM |sed 's/POOLCONFIG_//g' | sed 's/__/./g' | awk '{print tolower($0)}'`
        echo "POOLCONFIG :: $FPMPARAM => $VAL"
        echo "$FPMPARAM = $VAL" >> /etc/php/$PHPVERSION/fpm/pool-overrides.conf

    elif [[ $PARAM =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo "ENV :: $PARAM => $VAL"
        echo "env[$PARAM]=\"$VAL\"" >> /etc/php/$PHPVERSION/fpm/env.conf
    fi
done

# START SERVICES
/etc/init.d/cron restart
/etc/init.d/php$PHPVERSION-fpm restart
/etc/init.d/mariadb restart
/etc/init.d/nginx restart
sleep 1
/etc/init.d/monit restart

# CREATE MARIADB USER
mysql < /build.sql

# KEEP CONTAINER ALIVE
/usr/bin/tail -f /var/log/nginx/access.log
