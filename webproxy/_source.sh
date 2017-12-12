#!/bin/bash
set -e

RESOLVER=$(awk 'BEGIN{ORS=" "} $1=="nameserver" {print $2}' /etc/resolv.conf)

function clear_file {
 rm $1 2>/dev/null || true
}

function http_to_https {
HOSTNAME=$1
cat >> $CONFIG <<EOL
server {
 listen 80;
 listen [::]:80;
 server_name $HOSTNAME;
 return 301 https://\$host\$request_uri;
}
EOL
}

function https_wildcard {
 TARGET=$1
 https_generic_overwrite _ \$host $TARGET
}

function https_generic {
 HOSTNAME=$1
 TARGET=$2
 _https $HOSTNAME $HOSTNAME $SSL_DEFAULT_HOST $TARGET
}

function https_generic_overwrite {
 HOSTNAME=$1
 OVERWRITEHOST=$2
 TARGET=$3
 _https $HOSTNAME $OVERWRITEHOST $SSL_DEFAULT_HOST $TARGET
}

function https_dedicated {
 HOSTNAME=$1
 TARGET=$2
 _https $HOSTNAME $HOSTNAME $HOSTNAME $TARGET
}

function https_dedicated_overwrite {
 HOSTNAME=$1
 OVERWRITEHOST=$2
 TARGET=$3
 _https $HOSTNAME $OVERWRITEHOST $OVERWRITEHOST $TARGET
}

function https_dedicated_sslname {
 HOSTNAME=$1
 SSLHOST=$2
 TARGET=$3
 _https $HOSTNAME $HOSTNAME $SSLHOST $TARGET
}

function https_redirect {
 HOSTNAME=$1
 TARGET=$2
cat >> $CONFIG <<EOL
server {
 listen 443;
 listen [::]:443;
 server_name $HOSTNAME;
 ssl on;
 ssl_certificate $SSL_CONFIG_DIR/$SSL_DEFAULT_HOST/fullchain.cer;
 ssl_certificate_key $SSL_CONFIG_DIR/$SSL_DEFAULT_HOST/$SSL_DEFAULT_HOST.key;
 return 302 $TARGET;
}
EOL
}

function _https {
HOSTNAME=$1
OVERWRITEHOST=$2
SSLHOSTFILE=$3
TARGET=$4
cat >> $CONFIG <<EOL
server {
 listen 443;
 listen [::]:443;
 server_name $HOSTNAME;
 ssl on;
 ssl_certificate $SSL_CONFIG_DIR/$SSLHOSTFILE/fullchain.cer;
 ssl_certificate_key $SSL_CONFIG_DIR/$SSLHOSTFILE/$SSLHOSTFILE.key;
 location / {
  resolver $RESOLVER ipv6=off;
  proxy_pass $TARGET\$request_uri;
  set_real_ip_from 103.21.244.0/22;
  set_real_ip_from 103.22.200.0/22;
  set_real_ip_from 103.31.4.0/22;
  set_real_ip_from 104.16.0.0/12;
  set_real_ip_from 108.162.192.0/18;
  set_real_ip_from 131.0.72.0/22;
  set_real_ip_from 141.101.64.0/18;
  set_real_ip_from 162.158.0.0/15;
  set_real_ip_from 172.64.0.0/13;
  set_real_ip_from 173.245.48.0/20;
  set_real_ip_from 188.114.96.0/20;
  set_real_ip_from 190.93.240.0/20;
  set_real_ip_from 197.234.240.0/22;
  set_real_ip_from 198.41.128.0/17;
  set_real_ip_from 199.27.128.0/21;
  set_real_ip_from 2400:cb00::/32;
  set_real_ip_from 2606:4700::/32;
  set_real_ip_from 2803:f800::/32;
  set_real_ip_from 2405:b500::/32;
  set_real_ip_from 2405:8100::/32;
  set_real_ip_from 2c0f:f248::/32;
  set_real_ip_from 2a06:98c0::/29;
  real_ip_header CF-Connecting-IP;
  proxy_set_header Host $OVERWRITEHOST;
  proxy_set_header X-Real-IP \$remote_addr;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header Accept-Encoding "";
  proxy_set_header Authorization \$http_authorization;
  proxy_pass_header Authorization;
 }
}
EOL
}