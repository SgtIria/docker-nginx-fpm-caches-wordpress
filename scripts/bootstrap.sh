#!/bin/bash

set -e

# setting up default for environment variables
SERVER_NAME=${SERVER_NAME:-example.com}
DB_HOSTNAME=${DB_HOSTNAME:-$DB_PORT_3306_TCP_ADDR}
DB_USER=${DB_USER:-$DB_MYSQL_USER}
DB_PASSWORD=${DB_PASSWORD:-$DB_MYSQL_PASSWORD}
DB_DATABASE=${DB_DATABASE:-$DB_MYSQL_DATABASE}

echo "$(date): Boostraping a new web server instance for $SERVER_NAME"


echo "Replacing the placeholder in nginx config files for server name and cert domain name for $SERVER_NAME"
sed -i -e "s/server_fqdn/$SERVER_NAME/" /etc/nginx/sites-available/default
sed -i -e "s/server_fqdn/$SERVER_NAME/" /etc/nginx/ssl.conf

echo "Creating a config file for letsencrypt for $SERVER_NAME"
sed -i -e "s/server_fqdn/$SERVER_NAME/g" /etc/nginx/le.ini
sed -i -e "s/to_be_replaced_email/$LE_EMAIL/g" /etc/nginx/le.ini

cp /etc/nginx/le.ini /etc/letsencrypt/cli.ini


echo "add server name to /etc/hosts to avoid timeout when code make http call to public url"
EXT_IP=`ip route get 8.8.8.8 | awk '{print $NF; exit}'`
echo "$EXT_IP	$SERVER_NAME" >> /etc/hosts
echo "Wrote in /etc/hosts: $EXT_IP	$SERVER_NAME"

echo "We want to be able to curl the web site from the localhost using https (for purging the cache, and for the cron)"
echo "127.0.0.1	$SERVER_NAME" >> /etc/hosts

echo "boostrapping the logs"

if [ ! -d /root/backups ];then
    mkdir -p /root/backups
fi
touch /root/backups/wordpress.sql

if [ ! -d /var/log/nginx ];then
    mkdir -p /var/log/nginx
fi
chown -R www-front:www-front /var/log/nginx
touch /var/log/nginx/error.log
touch /var/log/nginx/access.log
chown www-front:www-front /var/log/nginx/error.log
chown www-front:www-front /var/log/nginx/access.log
touch /var/log/certs.log
touch /var/log/db-backup.log
touch /var/log/wp-cron.log

echo "bootsrapped on $(date)" > /tmp/last_bootstrap