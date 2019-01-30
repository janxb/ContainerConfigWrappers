#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/_source.sh

CONFIG=/etc/nginx/sites-enabled/webproxy-generated
SSL_DEFAULT_HOST=root.example.com
SSL_CONFIG_DIR=/root/.acme.sh

clear_file $CONFIG

http_to_https _
https_wildcard https://ajenti.lxd

http_to_https example.com
https_generic example.com http://internal.lxd

https_dedicated mail.example.com https://mailcow.lxd

http_to_https sogo.example.com
https_redirect sogo.example.com https://mail.example.com/SOGo

nginx -t
service nginx reload
echo NGINX config successfully reloaded
