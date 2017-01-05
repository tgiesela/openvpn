#!/bin/bash

# First argument: Client identifier

if [ $# eq 0 ]; then
        echo "Please start as $0 <name>" && exit 1
fi

if [ ! -f ${KEY_DIR}/${1}.crt ]; then
	cd /etc/easy-rsa/openvpn-ca
	source vars
	./build-key $1
fi
if [ ! -f ${KEY_DIR}/${1}.crt ]; then
	echo "Keys and certificates not found for ${1}"
	echo "Config file not created"
	exit 1 
fi
OPENVPNDIR=/etc/openvpn
KEY_DIR=/etc/easy-rsa/openvpn-ca/keys
OUTPUT_DIR=${OPENVPNDIR}/client-configs/files
BASE_CONFIG=${OPENVPNDIR}/client-configs/base.conf

cat ${BASE_CONFIG} \
    <(echo -e '<ca>') \
    ${KEY_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${KEY_DIR}/${1}.crt \
    <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/${1}.key \
    <(echo -e '</key>\n') \
    > ${OUTPUT_DIR}/${1}.ovpn

echo "Configuration file ${OUTPUT_DIR}/${1}.ovpn created"
