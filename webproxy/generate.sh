#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $DIR/_source.sh

CONFIG=/etc/nginx/sites-enabled/webproxy-generated
SSL_DEFAULT_HOST=root.radiohitwave.com
SSL_CONFIG_DIR=/root/.acme.sh

clear_file $CONFIG

http_to_https _
https_wildcard https://ajenti.lxd

http_to_https ajenti.radiohitwave.com
https_generic ajenti.radiohitwave.com https://ajenti.lxd:8000

http_to_https seafile.radiohitwave.com
https_generic seafile.radiohitwave.com https://seafile.lxd

#http_to_https landscape.radiohitwave.com
#https_generic landscape.radiohitwave.com https://landscape.lxd

#http_to_https cockpit.radiohitwave.com
#https_generic cockpit.radiohitwave.com https://cockpit.lxd:9090

http_to_https webssh.radiohitwave.com
https_generic webssh.radiohitwave.com https://webssh.lxd:4200

http_to_https streamripper.radiohitwave.com
https_generic streamripper.radiohitwave.com http://streamripper.lxd:8000

http_to_https etherpad.radiohitwave.com
https_generic etherpad.radiohitwave.com http://etherpad.lxd:9001

http_to_https teambutler.radiohitwave.com
https_generic_overwrite teambutler.radiohitwave.com radiohitwave.teambutler.net https://radiohitwave.teambutler.net

http_to_https mailcow.radiohitwave.com

https_dedicated mailcow.radiohitwave.com https://mailcow.lxd
#https_dedicated_sslname autoconfig.radiohitwave.com mailcow.radiohitwave.com https://mailcow.lxd
#https_dedicated_sslname autodiscover.radiohitwave.com mailcow.radiohitwave.com https://mailcow.lxd

#https_dedicated mailcow.radiohitwave.com https://mailcow-dockerized.lxd
#https_dedicated_sslname autoconfig.radiohitwave.com mailcow.radiohitwave.com https://mailcow-dockerized.lxd
#https_dedicated_sslname autodiscover.radiohitwave.com mailcow.radiohitwave.com https://mailcow-dockerized.lxd

http_to_https sogo.radiohitwave.com
https_redirect sogo.radiohitwave.com https://mailcow.radiohitwave.com/SOGo

http_to_https mailcow-dockerized.radiohitwave.com
https_dedicated_overwrite mailcow-dockerized.radiohitwave.com mailcow.radiohitwave.com https://mailcow-dockerized.lxd

nginx -t
service nginx reload
echo NGINX config successfully reloaded
