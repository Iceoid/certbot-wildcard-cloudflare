#!/bin/bash
DOMAIN_NAME=""

while [[ -z "${DOMAIN_NAME}" ]]; do
    read -rp "Enter the domain name to be used:"$'\n' dname
    DOMAIN_NAME=${dname}
done