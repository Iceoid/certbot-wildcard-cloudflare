#!/bin/bash

SUDO=''

if [[ $EUID -ne 0 ]]; then
   SUDO='sudo'
fi

### Clean crontab
crontab -u $USER -l | grep -v "/usr/local/bin/certbot_renewal.sh" | crontab -u $USER -

### Remove cloudflare.ini
#rm ~/.secrets/cloudflare.ini

### Remove certbot snap and cloudflare plugin
$SUDO snap remove certbot-dns-cloudflare
$SUDO snap remove certbot



