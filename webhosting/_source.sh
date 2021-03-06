##!/bin/bash
set -e

C_LOGNAME=""
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# username - password - directory
function ftp {
echo "creating FTP user $1"
dpkg -s pure-ftpd &>/dev/null
(echo $2; echo $2) | pure-pw useradd $1 -u www-data -g www-data -d /var/www/$3 >/dev/null
}

# domain - document_directory
function vhost_start {
echo "creating nginx vhost $1"
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

# target_domain
function redirect {
cat <<EOF >> $CONFIG
return 301 \$scheme://$1\$request_uri;
EOF
}

function vhost_end {
cat <<EOF >> $CONFIG
}
EOF
}

# config_part_filename
function nginx_config {
cat $DIR/parts/$1.conf >> $CONFIG
}

# certificate_path - key_path
function ssl {
cat <<EOF >> $CONFIG
 listen *:443 ssl http2;
 listen [::]:443 ssl http2;
 ssl_certificate $1;
 ssl_certificate_key $2;
EOF
}

# php_version - php_config
function php {
php_fpm_pool $1 $C_LOGNAME
PHPVALUE=$(sed "s/;/;\\\n/g" <<<"$2")
cat <<EOF >> $CONFIG
 location ~ [^/]\.php(/|$) {
  fastcgi_pass unix:/var/run/php/php-fpm-pool-$C_LOGNAME.sock;
  fastcgi_param PHP_VALUE "$PHPVALUE";
  fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
  fastcgi_buffers 16 16k;
  fastcgi_buffer_size 32k;
  fastcgi_read_timeout 600;
  include fastcgi.conf;
 }
EOF
}

# php_version - fpm_pool_name
function php_fpm_pool {
echo "creating PHP-FPM pool $2"
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
pm.max_children = 100
pm.start_servers = 2
pm.min_spare_servers = 2
pm.max_spare_servers = 10
EOF
}

# php_version - php_extension_names
function php_extension {
 echo "installing PHP $1 extensions - $2"
 PREFIX="php$1-"
 apt-get install -qq -y $(echo "${@:2}" | tr ' ' '\n' | sed -e "s/^/$PREFIX/")
}

# config_key - config_value
function php_global_config {
 echo "setting global PHP config $1=$2"
 for filename in /etc/php/*/fpm/conf.d; do
  crudini --set $filename/99-custom.ini '' $1 $2
 done
}

function php_reload {
echo "reloading PHP-FPM"
service php*-fpm reload
}

function ftp_reload {
echo "reloading Pure-FTPd"
pure-pw mkdb
}

function nginx_reload {
echo "reloading NGINX"
service nginx reload
}

function reload {
nginx_reload
php_reload
ftp_reload
echo "DONE."
}

function clear_config {
 truncate -s0 $CONFIG
 truncate -s0 /etc/pure-ftpd/pureftpd.passwd
 rm /etc/php/*/fpm/pool.d/*.conf         2>/dev/null || true
 rm /etc/php/*/fpm/conf.d/99-custom.ini  2>/dev/null || true
}

function prepare_php_config {
 for folder in /etc/php/*/fpm ; do
  VERSION=$(echo $folder | cut -d/ -f4)
  php_fpm_pool $VERSION $VERSION-default
  php_extension $VERSION "fpm $PHPEXTENSIONS"
 done
}

function install_packages {
 apt install pure-ftpd crudini nginx -y
}
