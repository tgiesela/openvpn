#!/bin/bash
DEFAULT_DOMAIN="test.local"
DEFAULT_DATAFOLDER=/dockerdata

read -p "Password for root user: " ROOT_PASSWORD

read -p "Domain (${DEFAULT_DOMAIN}): " SAMBA_DOMAIN
if [ -z $SAMBA_DOMAIN ]; then
     SAMBA_DOMAIN=${DEFAULT_DOMAIN}
fi

read -p "Name of folder to store persistent data (${DEFAULT_DATAFOLDER}): " DATAFOLDER
if [ -z $DATAFOLDER ]; then
    DATAFOLDER=${DEFAULT_DATAFOLDER}
fi

read -p "Do you want to use custom network? (y/n) " yn
case $yn in
    [Yy]* )
            read -p "Custom network name : " CUSTOMNETWORKNAME
	    LOCALNETWORK_IP=$(docker network inspect \
		${CUSTOMNETWORKNAME} | grep Subnet | sed 's/\"//g' | cut -d: -f2 | cut -d/ -f1)
	    MASK_LEN=$(docker network inspect \
                ${CUSTOMNETWORKNAME} | grep Subnet | sed 's/\"//g' | cut -d/ -f2 | cut -d, -f1)

	    ONES=1111111111111111111111111111111111111111
	    ZEROES=0000000000000000000000000000000000000000
	    BITMAP_MASK=${ONES:0:${MASK_LEN}}${ZEROES:0:((24-$MASK_LEN))}
	    LOCALNETWORK_MASK="$((2#${BITMAP_MASK:0:8}))"."$((2#${BITMAP_MASK:8:8}))"."$((2#${BITMAP_MASK:16:8}))"."$((2#${BITMAP_MASK:24:8}))"
            if [ ! -z $CUSTOMNETWORKNAME ]; then CUSTOMNETWORKNAME=--net=${CUSTOMNETWORKNAME}; fi
            ;;
        * ) CUSTOMNETWORKNAME=
            ;;
esac

if [ -z LOCALNETWORK_IP ]; then
    read -p "Local network IP address for OpenVPN: " LOCALNETWORK_IP
fi
if [ -z LOCALNETWORK_MASK ]; then
    read -p "Local network Mask for OpenVPN: " LOCALNETWORK_MASK
fi

read -p "ip-address DNS-server: " DNS_IP_ADDRESS
if [ -z $DNS_IP_ADDRESS ]; then
    DNS_IP_ADDRESS=localhost
else
    DNS_IP_ADDRESS=${DNS_IP_ADDRESS}
fi

read -p "fixed ip-address OPENVPN-server: " FIXED_IP_ADDRESS
if [ -z $FIXED_IP_ADDRESS ]; then
    FIXED_IP_ADDRESS=
else
    FIXED_IP_ADDRESS="--ip=${FIXED_IP_ADDRESS}"
fi

echo "Please enter information used for the certificates"
read -p "Country (2 characters): " KEY_COUNTRY
read -p "City:                   " KEY_CITY
read -p "State or province:      " KEY_PROVINCE
read -p "Organisation name:      " KEY_ORG
read -p "E-mail address:         " KEY_EMAIL
read -p "Organisational unit:    " KEY_OU
read -p "Common name:            " KEY_COMMON_NAME

#docker rm openvpn
#rm openvpn/openvpn/.alreadysetup
docker run \
	--privileged \
	-h openvpn \
	-v ${DATAFOLDER}/openvpn/openvpn:/etc/openvpn \
	-v ${DATAFOLDER}/openvpn/easy-rsa:/etc/easy-rsa \
	-e KEY_COUNTRY="${KEY_COUNTRY}" \
	-e KEY_CITY="${KEY_CITY}" \
	-e KEY_PROVINCE="${KEY_PROVINCE}" \
	-e KEY_ORG="${KEY_ORG}" \
	-e KEY_EMAIL="${KEY_EMAIL}" \
	-e KEY_OU="${KEY_OU}" \
	-e KEY_NAME="server" \
	-e KEY_COMMON_NAME="${KEY_COMMON_NAME}" \
	-e NAME="openvpn" \
        -e DNS_SERVER_IP="${DNS_IP_ADDRESS}" \
        -e DOMAIN_NAME="${SAMBA_DOMAIN}" \
	-e LOCALNETWORK_IP="${LOCALNETWORK_IP}" \
	-e LOCALNETWORK_MASK="${LOCALNETWORK_MASK}" \
	-e ROOT_PASSWORD="${ROOT_PASSWORD}" \
	${FIXED_IP_ADDRESS} \
	--name openvpn \
	--dns-search=${SAMBA_DOMAIN} \
	--dns=${DNS_IP_ADDRESS} \
	${CUSTOMNETWORKNAME} \
	-p 1197:1197 \
	-d tgiesela/openvpn:v0.1


