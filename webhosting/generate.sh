#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/_source.sh

PHPEXTENSIONS="bcmath gd gmp json mbstring mysql sqlite3 xml zip"
CONFIG=/etc/nginx/sites-enabled/webhosting-generated
clear_config

vhost_start DEFAULT html
	php 7.2 "upload_max_filesize=10M;post_max_size=200M;date.timezone=Europe/Berlin;"
vhost_end

vhost_start example.com html2/sub
	php 7.1 "post_max_size=200M;date.timezone=Europe/Berlin;"
vhost_end

nginx -t
service nginx reload
echo "nginx: configuration reloaded!"
