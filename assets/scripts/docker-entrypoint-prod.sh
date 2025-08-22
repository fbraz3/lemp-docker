#!/bin/bash

$(which chmod) 700 /etc/monit/monitrc

# Set MySQL root password if not already set
if [ ! -f /var/lib/mysql/.mysql_configured ]; then
    # Check if MYSQL_ROOT_PASSWORD is set, if not use default
    MYSQL_DEFAULT_PASSWORD="defaultrootpassword"
    if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
        echo "Error: MYSQL_ROOT_PASSWORD must be set."
        exit 1
    fi

    echo "Configuring MySQL for production..."
    /etc/init.d/mariadb start
    sleep 5

    # fail if password is the repository default
    if [ "$MYSQL_ROOT_PASSWORD" = "$MYSQL_DEFAULT_PASSWORD" ]; then
        echo "Error: MYSQL_ROOT_PASSWORD is set to the default value. Please set a secure one"
        exit 1
    fi

    if [ -n "$MYSQL_APP_DATABASE" ]; then
        echo "Creating database: $MYSQL_APP_DATABASE"
        mysql -u root -e "CREATE DATABASE IF NOT EXISTS \`$MYSQL_APP_DATABASE\`;"
    fi

    if [ -n "$MYSQL_APP_USER" ] && [ -n "$MYSQL_APP_USER_PASSWD" ]; then
        echo "Creating user: $MYSQL_APP_USER"
        mysql -u root -e "CREATE USER IF NOT EXISTS '$MYSQL_APP_USER'@'%' IDENTIFIED BY '$MYSQL_APP_USER_PASSWD';"
        if [ -n "$MYSQL_APP_DATABASE" ]; then
          mysql -u root -e "GRANT ALL PRIVILEGES ON \`$MYSQL_APP_DATABASE\`.* TO '$MYSQL_APP_USER'@'localhost';"
          mysql -u root -e "GRANT ALL PRIVILEGES ON \`$MYSQL_APP_DATABASE\`.* TO '$MYSQL_APP_USER'@'%';"
          mysql -u root -e "FLUSH PRIVILEGES;"
        fi
    fi

    # read all .sql files from /sql directory and execute them
    for sql_file in /sql-scripts/*.sql; do
        if [ -f "$sql_file" ]; then
            echo "Executing SQL file: $sql_file"
            mysql -u root < "$sql_file"
        fi
    done

    mysql -u root -e "CREATE DATABASE IF NOT EXISTS app;"
    mysql -u root -e "ALTER USER 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"

    # Mark as configured
    touch /var/lib/mysql/.mysql_configured
fi

# START SERVICES
/etc/init.d/mariadb start
RESTART_MONIT="true"
