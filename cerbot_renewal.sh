#!/bin/bash

### VARS ###
LOGDIR=/var/log/certbot_renewals
### LOGS ###
mkdir -p /var/log/certbot_renewals
NOW=$(date +"%F--%N")
LOGFILENAME="certbot-renewal-log-$NOW.log"
touch $LOGDIR/$LOGFILENAME

### CERTBOT Renewal ###
$(sudo certbot renew) > $LOGFILE