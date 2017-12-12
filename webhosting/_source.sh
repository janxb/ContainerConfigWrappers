#!/bin/bash
set -e

function vhost_end {
cat <<EOF >> $CONFIG
}
EOF
}

function vhost_start {
LOGNAME=$(echo $1 | sed 's/[^0-9A-Za-z]*//g');
WEBDIR=/var/www/$LOGNAME/;
if [ ! -d "$WEBDIR" ]; then echo "web dir $WEBDIR not existing!"; exit 1; fi;
cat <<EOF >> $CONFIG
server {
 server_name $@;
 listen *:80;
 listen [::]:80;
 access_log /var/log/nginx/$LOGNAME.access.log;
 error_log /var/log/nginx/$LOGNAME.error.log;
 root /var/www/$LOGNAME;
 index index.php index.html;
 try_files \$uri \$uri/ /index.php\$is_args\$args;
 client_max_body_size 100m;
EOF
}

function ssl {
cat <<EOF >> $CONFIG
 listen *:443 ssl;
 listen [::]:443 ssl;
 ssl_certificate $1;
 ssl_certificate_key $2;
EOF
}

function php {
php_extension $1 "fpm $PHPEXTENSIONS"
PHPVALUE=$(sed "s/;/;\\\n/g" <<<"$2")
cat <<EOF >> $CONFIG
 location ~ [^/]\.php(/|$) {
  fastcgi_pass unix:/var/run/php/php$1-fpm.sock;
  fastcgi_param PHP_VALUE "$PHPVALUE";
  fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
  include fastcgi.conf;
 }
EOF
}

function php_extension {
 PREFIX="php$1-"
 apt-get install -qq -y $(echo "${@:2}" | tr ' ' '\n' | sed -e "s/^/$PREFIX/")
}

function clear_config {
 truncate -s0 $CONFIG
}
