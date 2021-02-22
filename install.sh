#!/bin/bash

### VARS ###
DOMAIN_NAME=""
CF_INI_FILE=~/.secrets/cloudflare.ini
RENEWAL_SCRIPT=/usr/local/bin/certbot_renewal.sh
SUDO=''

if [[ $EUID -ne 0 ]]; then
   SUDO='sudo'
fi


### Install dependencies ###
${SUDO} apt update -y

read -rp "Remove OS packaged certbot and install snapd ? [y/N] " response
if [[ "${response}" =~ ^([yY]|[yY][eE][sS])$ ]]; then
    ${SUDO} apt remove certbot
    ${SUDO} apt autoremove
    ${SUDO} apt install snapd
fi

${SUDO} snap install core; ${SUDO} snap refresh core
${SUDO} snap install --classic certbot
${SUDO} ln -s /snap/bin/certbot /usr/bin/certbot
${SUDO} snap set certbot trust-plugin-with-root=ok
${SUDO} snap install certbot-dns-cloudflare


### Init files and get required information ###
while [[ -z "${DOMAIN_NAME}" ]]; do
    read -rp "Enter the domain name to be used:"$'\n' dname
    DOMAIN_NAME=${dname}
done

if [[ ! -f "${CF_INI_FILE}" ]]; then
    mkdir ~/.secrets
    touch ${CF_INI_FILE}
fi
chmod 600 ${CF_INI_FILE}
chmod 600 -R ~/.secrets

read -rp "Would you like to reset and enter cloudflare credentials? [y/N] " init_response
if [[ "${init_response}" =~ ^([yY]|[yY][eE][sS])$ ]]; then
    read -rp "Enter your cloudflare API Token:"$'\n' CF_API_TOKEN
    echo "dns_cloudflare_api_token = ${CF_API_TOKEN}" >> ~/.secrets/cloudflare.ini
fi


### Create Certificates ###
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

if [[ ! -f ${RENEWAL_SCRIPT} ]]; then
    cp ${PWD}/certbot_renewal.sh ${RENEWAL_SCRIPT}
    chmod +x ${RENEWAL_SCRIPT}
    chown $USER:$USER ${RENEWAL_SCRIPT}
fi

crontab -u $USER -l | grep -v ${RENEWAL_SCRIPT}  | crontab -u $USER -
{ crontab -l; echo "0 4 * * * sudo bash ${RENEWAL_SCRIPT}"; } | crontab -