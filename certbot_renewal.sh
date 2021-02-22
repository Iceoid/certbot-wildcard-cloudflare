#!/bin/bash

# ### VARS ###
# LOGDIR=/var/log/certbot_renewals
# ### LOGS ###
# mkdir -p /var/log/certbot_renewals
# NOW=$(date +"%F--%N")
# LOGFILENAME="certbot-renewal-log-$NOW.log"
# touch $LOGDIR/$LOGFILENAME

# ### CERTBOT Renewal ###
# $(sudo certbot renew) > $LOGFILE


############# CERTBOT Renewal ##############

certbot_response=$(certbot renew --renew-by-default)

############# LOGS #########################

NOW=$(date +"%F--%N")
LOGFILENAME="certbot-renewal-log-$NOW.log"
LOGFILE="/var/log/certbot_renewals/$LOGFILENAME"
touch $LOGFILE

echo "$certbot_response" > $LOGFILE