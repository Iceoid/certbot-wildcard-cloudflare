#!/bin/bash

### VARS ###
DOMAIN_NAME=""
CF_INI_FILE=~/.secrets/cloudflare.ini
RENEWAL_SCRIPT=/usr/local/bin/certbot_renewal.sh
SUDO=''

if [[ $EUID -ne 0 ]]; then
   SUDO='sudo'
fi

${SUDO} apt remove certbot
${SUDO} apt autoremove
${SUDO} apt update -y
${SUDO} snap install core -y; sudo snap refresh core -y
${SUDO} snap install --classic certbot -y
${SUDO} ln -s /snap/bin/certbot /usr/bin/certbot
${SUDO} snap set certbot trust-plugin-with-root=ok

# For Cloudflare DNS provider
${SUDO} snap install certbot-dns-cloudflare -y

read -rp "Enter the domain name to be used:"$'\n' dname
if [[ ${dname} != "" ]]; then
    DOMAIN_NAME=${dname}
fi

mkdir ~/.secrets
touch ${CF_INI_FILE}
> ${CF_INI_FILE}
chmod 600 ${CF_INI_FILE}
chmod 600 -R ~/.secrets


# read -rp "Enter your cloudflare email:"$'\n' CF_EMAIL
# echo "dns_cloudflare_email = ${CF_EMAIL}" >> ${CF_INI_FILE}

# read -rp "Enter your cloudflare Global API Key:"$'\n' CF_API_KEY
# echo "dns_cloudflare_api_key = ${CF_API_KEY}" >> ${CF_INI_FILE}

read -rp "Enter your cloudflare API Token:"$'\n' CF_API_TOKEN
echo "dns_cloudflare_api_token = ${CF_API_TOKEN}" >> ~/.secrets/cloudflare.ini


### Create Certificates
read -rp "Would you like to use the Let's encrypt production environment? ('No' will use the staging environment instead) [y/N] " init_response
if [[ "${init_response}" =~ ^([yY]|[yY][eE][sS])$ ]]; then
    certbot certonly --dns-cloudflare --dns-cloudflare-credentials ${CF_INI_FILE} -d ${DOMAIN_NAME} -d *.${DOMAIN_NAME}
else
    certbot certonly --dry-run --dns-cloudflare --dns-cloudflare-credentials ${CF_INI_FILE} -d ${DOMAIN_NAME} -d *.${DOMAIN_NAME}
fi

read -rp "Would you like to test the certificate renawal? [y/N] " init_response
if [[ "${init_response}" =~ ^([yY]|[yY][eE][sS])$ ]]; then
    certbot renew --dry-run
fi

cp ${PWD}/certbot_renewal.sh ${RENEWAL_SCRIPT}
chmod +x ${RENEWAL_SCRIPT}
chown $USER:$USER ${RENEWAL_SCRIPT}

crontab -u $USER -l | grep -v ${RENEWAL_SCRIPT}  | crontab -u $USER -
{ crontab -l; echo "0 4 * * sudo bash ${RENEWAL_SCRIPT}"; } | crontab -