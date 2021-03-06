#!/bin/bash

### VARS ###
DOMAIN_NAME=""
SECRETDIR=~/.secrets
CF_INI_FILE=${SECRETDIR}/cloudflare.ini
RENEWAL_SCRIPT=/usr/local/bin/certbot_renewal.sh
SUDO=''

if [[ $EUID -ne 0 ]]; then
   SUDO='sudo'
fi


### Install dependencies ###
${SUDO} apt update

read -rp "Remove OS packaged certbot and install snapd ? [y/N] " response
if [[ "${response}" =~ ^([yY]|[yY][eE][sS])$ ]]; then
    ${SUDO} apt remove certbot
    ${SUDO} apt autoremove
    ${SUDO} apt install snapd -y
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

# Making sure log, config and work dirs are set for letsencrypt
#${SUDO} mkdir -p /var/log/letsencrypt

if [[ ! -f "${SECRETDIR}" ]]; then
    mkdir ${SECRETDIR}
fi

touch ${CF_INI_FILE}
chmod 600 ${CF_INI_FILE}

read -rp "Would you like to reset and enter cloudflare credentials? [y/N] " init_response
if [[ "${init_response}" =~ ^([yY]|[yY][eE][sS])$ ]]; then
    > ${CF_INI_FILE}
    read -rp "Enter your cloudflare API Token:"$'\n' CF_API_TOKEN
    echo "dns_cloudflare_api_token = ${CF_API_TOKEN}" >> ~/.secrets/cloudflare.ini
fi


### Create Certificates ###
read -rp "Would you like to use the Let's encrypt production environment? ('No' will use the staging environment instead) [y/N] " init_response
if [[ "${init_response}" =~ ^([yY]|[yY][eE][sS])$ ]]; then
    ${SUDO} certbot certonly --agree-tos --dns-cloudflare --dns-cloudflare-credentials ${CF_INI_FILE} -d ${DOMAIN_NAME} -d *.${DOMAIN_NAME}
else
    ${SUDO} certbot certonly --dry-run --agree-tos --dns-cloudflare --dns-cloudflare-credentials ${CF_INI_FILE} -d ${DOMAIN_NAME} -d *.${DOMAIN_NAME}
    read -rp "Would you now like to create a real certificate? [y/N] " prod_response
    if [[ "${prod_response}" =~ ^([yY]|[yY][eE][sS])$ ]]; then
    	${SUDO} certbot certonly --agree-tos --dns-cloudflare --dns-cloudflare-credentials ${CF_INI_FILE} -d ${DOMAIN_NAME} -d *.${DOMAIN_NAME}
    fi
fi

read -rp "Would you like to test the certificate renawal? [y/N] " renew_response
if [[ "${renew_response}" =~ ^([yY]|[yY][eE][sS])$ ]]; then
    ${SUDO} certbot renew --dry-run
fi

${SUDO} cp ${PWD}/certbot_renewal.sh ${RENEWAL_SCRIPT}
${SUDO} chmod +x ${RENEWAL_SCRIPT}

crontab -u $USER -l | grep -v ${RENEWAL_SCRIPT}  | crontab -u $USER -
{ crontab -l; echo "0 4 * * * sudo bash ${RENEWAL_SCRIPT}"; } | crontab -
