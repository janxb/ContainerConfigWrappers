#!/bin/bash
set -e

function vhost_end {
cat <<EOF >> $CONFIG
}
EOF
}

C_LOGNAME=""

# domain - vhost_name
function vhost_start {
C_LOGNAME=$(echo $1 | sed 's/[^0-9A-Za-z]*//g' | awk '{print tolower($0)}');
WEBDIR=/var/www/$2/;
if [ ! -d "$WEBDIR" ]; then echo "web dir $WEBDIR not existing!"; exit 1; fi;
cat <<EOF >> $CONFIG
server {
 server_name $1;
 listen *:80;
 listen [::]:80;
 access_log /var/log/nginx/$C_LOGNAME.access.log;
 error_log /var/log/nginx/$C_LOGNAME.error.log;
 root $WEBDIR;
 index index.php index.html;
 try_files \$uri \$uri/ /index.php\$is_args\$args;
 client_max_body_size 1g;
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

# php_version - php_config
function php {
php_extension $1 "fpm $PHPEXTENSIONS"
php_fpm_pool $1 $C_LOGNAME
PHPVALUE=$(sed "s/;/;\\\n/g" <<<"$2")
cat <<EOF >> $CONFIG
 location ~ [^/]\.php(/|$) {
  fastcgi_pass unix:/var/run/php/php-fpm-pool-$C_LOGNAME.sock;
  fastcgi_param PHP_VALUE "$PHPVALUE";
  fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
  include fastcgi.conf;
 }
EOF
}

# php_version - fpm_pool_name
function php_fpm_pool {
POOLNAME=$(echo $2 | sed 's/[^0-9A-Za-z]*//g');
truncate -s0 /etc/php/$1/fpm/pool.d/$POOLNAME.conf &>/dev/null || true
cat <<EOF >> /etc/php/$1/fpm/pool.d/$POOLNAME.conf
[$POOLNAME]
listen = /run/php/php-fpm-pool-\$pool.sock
listen.owner = www-data
listen.group = www-data
user = www-data
group= www-data
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
EOF
service php$1-fpm restart
}

function php_extension {
 PREFIX="php$1-"
 apt-get install -qq -y $(echo "${@:2}" | tr ' ' '\n' | sed -e "s/^/$PREFIX/")
}

function clear_config {
 truncate -s0 $CONFIG
 rm /etc/php/*/fpm/pool.d/*.conf 2>/dev/null || true
 for folder in /etc/php/* ; do php_fpm_pool ${folder##*/} ${folder##*/}-default; done;
}
