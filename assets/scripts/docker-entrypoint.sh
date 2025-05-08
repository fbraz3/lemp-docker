#!/bin/bash

$(which chmod) 700 /etc/monit/monitrc

# START SERVICES
/etc/init.d/mariadb start
RESTART_MONIT="true"

