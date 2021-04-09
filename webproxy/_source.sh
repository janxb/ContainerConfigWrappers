#!/bin/bash
set -e

RESOLVER=$(awk 'BEGIN{ORS=" "} $1=="nameserver" {print $2}' /etc/resolv.conf)

function get_cloudflare_ips {
 IPLIST=`wget 'https://www.cloudflare.com/ips-v4' -q -O -`' '`wget 'https://www.cloudflare.com/ips-v6' -q -O -`
for ip in $IPLIST; do
  echo "  set_real_ip_from $ip;";
 done
}
CLOUDFLARE_IPS=$(get_cloudflare_ips)

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
 listen 443 ssl;
 listen [::]:443 ssl;
 server_name $HOSTNAME;
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
 listen 443 ssl http2;
 listen [::]:443 ssl http2;
 server_name $HOSTNAME;
 ssl_certificate $SSL_CONFIG_DIR/$SSLHOSTFILE/fullchain.cer;
 ssl_certificate_key $SSL_CONFIG_DIR/$SSLHOSTFILE/$SSLHOSTFILE.key;
 location / {
  resolver $RESOLVER ipv6=off;
  proxy_pass $TARGET\$request_uri;
  proxy_http_version 1.1;
  proxy_read_timeout 1h;
  proxy_send_timeout 1h;
  proxy_request_buffering off;
  proxy_buffering off;
  proxy_set_header Host $OVERWRITEHOST;
  proxy_set_header X-Real-IP \$remote_addr;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto \$scheme;
  proxy_set_header Accept-Encoding "";
  proxy_set_header Authorization \$http_authorization;
  proxy_set_header Upgrade \$http_upgrade;
  proxy_set_header Connection "upgrade";
  proxy_pass_header Authorization;
  proxy_pass_header Server;
  client_max_body_size 1g;
  client_body_buffer_size 10m;
$CLOUDFLARE_IPS
  real_ip_header CF-Connecting-IP;
 }
}
EOL
}
