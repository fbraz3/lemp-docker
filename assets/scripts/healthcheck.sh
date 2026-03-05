#!/bin/bash

# LEMP Docker Healthcheck Script
# Verifies that all essential services are running and responsive

set -e

# Flags for service status
nginx_ok=false
mysql_ok=false

# Check Nginx
if curl -sf http://127.0.0.1/ > /dev/null 2>&1; then
    nginx_ok=true
fi

# Check MariaDB/MySQL
if mysqladmin -h 127.0.0.1 ping > /dev/null 2>&1; then
    mysql_ok=true
fi

# Both services must be healthy
if [ "$nginx_ok" = true ] && [ "$mysql_ok" = true ]; then
    exit 0
else
    echo "Health check failed: nginx=$nginx_ok, mysql=$mysql_ok"
    exit 1
fi
