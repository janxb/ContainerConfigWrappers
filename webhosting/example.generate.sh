#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/_source.sh

PHPEXTENSIONS="bcmath gd gmp mbstring mysql sqlite3 xml zip apcu curl imagick"
CONFIG=/etc/nginx/sites-enabled/webhosting-generated
clear_config
prepare_php_config
install_packages

php_global_config date.timezone Europe/Berlin
php_global_config memory_limit 256M

vhost_start DEFAULT default
	php 7.4 "max_execution_time=600s;memory_limit=256M"
	ssl /etc/ssl/certs/nginx-selfsigned.crt /etc/ssl/private/nginx-selfsigned.key
	nginx_config default
vhost_end

vhost_start example.com example_htdocs
	php 8.0
	ssl /etc/ssl/certs/nginx-selfsigned.crt /etc/ssl/private/nginx-selfsigned.key
	ftp example-ftp-user my-secure-password example_htdocs
vhost_end

reload
