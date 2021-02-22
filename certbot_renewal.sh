#!/bin/bash

### Certbot Renewal ###

certbot_response=$(sudo certbot renew)

### LOGS ###

NOW=$(date +"%F--%N")
LOGFILENAME="certbot-renewal-log-$NOW.log"
LOGFILE="/var/log/certbot_renewals/$LOGFILENAME"
touch $LOGFILE

echo "$certbot_response" > $LOGFILE