#!/bin/bash

apt-get clean
apt-get autoclean
rm -rf /var/lib/apt/lists/*

truncate -s 0 /var/log/*log
truncate -s 0 /var/log/**/*.log
find /var/log -type f -name '*.[0-99].gz' -exec rm {} +

> /var/log/dmesg
> /root/.bash_history

history -c
