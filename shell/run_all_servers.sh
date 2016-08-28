#!/bin/bash
/etc/init.d/ssh start
/etc/init.d/mysql start
/etc/init.d/php7.0-fpm start
/usr/sbin/nginx
tail -f /var/log/nginx/error.log
