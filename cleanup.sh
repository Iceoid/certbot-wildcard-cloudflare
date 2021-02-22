#!/bin/bash

# Clean crontab
crontab -u $USER -l | grep -v /usr/local/bin/certbot_renewal.sh | crontab -u $USER -

# Remove cloudflare.ini
rm ~/.secrets/cloudflare.ini
