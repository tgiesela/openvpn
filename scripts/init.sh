#!/bin/bash

set -e

info () {
    echo "[INFO] $@"
}

OPENVPN_NETWORK_IP=10.8.5.0
OPENVPN_NETWORK_MASK=255.255.255.0
DOCKER_IP=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d':' -f 2 | awk {'print $1'})
DOCKER_MASK=$(/sbin/ifconfig eth0 | grep 'Mask:' | cut -d: -f 4)
DOCKER_DOMAIN_NAME=$(dnsdomainname)
CADIR=/etc/easy-rsa/openvpn-ca
KEY_COUNTRY=${KEY_COUNTRY}
KEY_CITY=${KEY_CITY}
KEY_PROVINCE=${KEY_PROVINCE}
KEY_ORG=${KEY_ORG}
KEY_EMAIL=${KEY_EMAIL}
KEY_OU=${KEY_OU}
KEY_NAME=${KEY_NAME}
KEY_COMMON_NAME=${KEY_COMMON_NAME}
DNS_SERVER_IP=${DNS_SERVER_IP}
DOMAIN_NAME=${DOMAIN_NAME:-DOCKER_DOMAIN_NAME}
info "DOMAIN_NAME=${DOMAIN_NAME}"
LOCALNETWORK_IP=${LOCALNETWORK_IP:-DOCKER_IP}
LOCALNETWORK_MASK=${LOCALNETWORK_MASK:-DOCKER_MASK}
ROOT_PASSWORD=${ROOT_PASSWORD:-$(pwgen -cny -c -n -1 12)}

appSetup () {

    rm -rf ${CADIR}
    make-cadir ${CADIR}
    cd ${CADIR}

    echo "root:${ROOT_PASSWORD}" | chpasswd

    [ -n "$KEY_COUNTRY" ] && sed -i '/export KEY_COUNTRY=/c\export KEY_COUNTRY=${KEY_COUNTRY}' ${CADIR}/vars
    [ -n "$KEY_PROVINCE" ] && sed -i '/export KEY_PROVINCE=/c\export KEY_PROVINCE=${KEY_PROVINCE}' ${CADIR}/vars
    [ -n "$KEY_CITY" ] && sed -i '/export KEY_CITY=/c\export KEY_CITY=${KEY_CITY}' ${CADIR}/vars
    [ -n "$KEY_ORG" ] && sed -i '/export KEY_ORG=/c\export KEY_ORG=${KEY_ORG}' ${CADIR}/vars
    [ -n "$KEY_EMAIL" ] && sed -i '/export KEY_EMAIL=/c\export KEY_EMAIL=${KEY_EMAIL}' ${CADIR}/vars
    [ -n "$KEY_OU" ] && sed -i '/export KEY_OU=/c\export KEY_OU=${KEY_OU}' ${CADIR}/vars

    [ -n "$KEY_NAME" ] && sed -i '/export KEY_NAME=/c\export KEY_NAME=${KEY_NAME}' ${CADIR}/vars

    source vars
    info "Cleaning previous easy-rsa folder"
    ./clean-all
    info "Executing ./build-ca"
    expect /tmp/buildca.expect
    info "Building key-server for ${KEY_NAME}"
    expect /tmp/build-key-server.expect
    info "Build Diffie-Hellman keys"
    ./build-dh
    info "Generate openvpn HMAC signature"
    openvpn --genkey --secret keys/ta.key

    info "Copy server keys and certificates to /etc/openvpn"
    cd ${CADIR}/keys
    cp ca.crt ca.key server.crt server.key ta.key dh2048.pem /etc/openvpn

    mv /tmp/server.conf /etc/openvpn/server.conf

    # format the openvpn_ipaddress (zero out non-maskable bytes)
    info "${OPENVPN_NETWORK_IP} ${OPENVPN_NETWORK_MASK}"
    OPENVPN_NETWORK_IP=$(/tmp/networkid.sh ${OPENVPN_NETWORK_IP} ${OPENVPN_NETWORK_MASK} | cut -d'/' -f 1)
    info "Openvpn network ip-address=${OPENVPN_NETWORK_IP}"

    sed -i "s/<dns-server>/${DNS_SERVER_IP}/g" /etc/openvpn/server.conf
    sed -i "s/<domain-name>/${DOMAIN_NAME}/g" /etc/openvpn/server.conf
    sed -i "s/<localnetwork>/${LOCALNETWORK_IP}/g" /etc/openvpn/server.conf
    sed -i "s/<localnetworkmask>/${LOCALNETWORK_MASK}/g" /etc/openvpn/server.conf
    sed -i "s/<openvpnip>/${OPENVPN_NETWORK_IP}/g" /etc/openvpn/server.conf
    sed -i "s/<openvpnmask>/${OPENVPN_NETWORK_MASK}/g" /etc/openvpn/server.conf

    # setup iptables for routing
    mv /tmp/iptables.conf /etc/openvpn/iptables.conf
    # convert ip mask to ip/masklen
    info "NEWIP=$(/tmp/networkid.sh ${OPENVPN_NETWORK_IP} ${OPENVPN_NETWORK_MASK})"
    NEWIP=$(/tmp/networkid.sh ${OPENVPN_NETWORK_IP} ${OPENVPN_NETWORK_MASK})
    sed -i "s'10.8.0.0/24'${NEWIP}'g" /etc/openvpn/iptables.conf
    info "NEWIP=$(/tmp/networkid.sh ${DOCKER_IP} ${DOCKER_MASK})"
    NEWIP=$(/tmp/networkid.sh ${DOCKER_IP} ${DOCKER_MASK})
    sed -i "s'192.168.0.0/24'${NEWIP}'g" /etc/openvpn/iptables.conf

    # Save the iptables setup
    iptables-save > /etc/openvpn/iptables-dump.ipt

    # commands to create client certficate tools
    mkdir -p /etc/openvpn/client-configs/files
    chmod 700 /etc/openvpn/client-configs/files/
    mv /tmp/base.conf /etc/openvpn/client-configs/
    mv /tmp/makeconfig.sh /etc/openvpn/client-configs/

    touch /etc/openvpn/.alreadysetup
}

appStart () {
    [ -f /etc/openvpn/.alreadysetup ] && echo "Skipping setup..." || appSetup

    # Start the services
    /usr/bin/supervisord
}

appHelp () {
	echo "Available options:"
	echo " app:start          - Starts all services needed for Samba AD DC"
	echo " app:setup          - First time setup."
	echo " app:help           - Displays the help"
	echo " [command]          - Execute the specified linux command eg. /bin/bash."
}

case "$1" in
	app:start)
		appStart
		;;
	app:setup)
		appSetup
		;;
	app:help)
		appHelp
		;;
	*)
		if [ -x $1 ]; then
			$1
		else
			prog=$(which $1)
			if [ -n "${prog}" ] ; then
				shift 1
				$prog $@
			else
				appHelp
			fi
		fi
		;;
esac

exit 0
