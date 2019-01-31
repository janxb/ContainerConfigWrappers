#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/_source.sh

PHPEXTENSIONS="bcmath gd gmp json mbstring mysql sqlite3 xml zip"
CONFIG=/etc/nginx/sites-enabled/webhosting-generated
clear_config

vhost_start DEFAULT html
vhost_end

vhost_start example.com html2/sub
	php 7.3 "date.timezone=Europe/Berlin;"
	ssl /etc/ssl/certs/nginx-selfsigned.crt /etc/ssl/private/nginx-selfsigned.key
	nginx_config custom-part
vhost_end

nginx -t
php_reload
ftp_reload
service nginx reload
echo "nginx: configuration reloaded!"
