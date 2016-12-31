# samba4-ad-dc
Openvpn project for docker with SSH installed.

## First time configuration
Build the docker image:

>docker build -t yourimage.

When starting the image for the first time, some additional parameters are
required to configure the Openvpn server:

```
docker run 
        -h openvpn \
        -v ${PWD}/openvpn/openvpn:/etc/openvpn \
        -v ${PWD}/openvpn/easy-rsa:/etc/easy-rsa \
        -e KEY_COUNTRY="<your-countrycode>" \
        -e KEY_CITY="<your-city>" \
        -e KEY_PROVINCE="<your-province>" \
        -e KEY_ORG="<your-org" \
        -e KEY_EMAIL="<your-email>" \
        -e KEY_OU="<your-ou>" \
        -e KEY_NAME="<your-name>" \
        -e KEY_COMMON_NAME="your-common-name>" \
        -e DNS_SERVER_IP="<your-dns-server>" \
        -e DOMAIN_NAME="<your-domain>" \
        -e LOCALNETWORK_IP="<your-local-network-ip>" \
        -e LOCALNETWORK_MASK="255.255.255.0" \
        -e ROOT_PASSWORD="<your-root-password>" \
        --name openvpn \
        --dns-search=<domain-name> \
        --dns=<your-fixed-ip> \
        --net=<yournet> \
        -p 1197:1197 \
        -d yourimage
```

You can omit the two password environment variables. The init script will 
generate random passwords and display the passwords in the docker logs.

The volume parameters (-v) can be used to store the configuration of openvpn and
the key database. You can also use a data container to persist the data.

Openvpn/easy-rsa will be configured using the environment variables.
All varibales starting with KEY_... are used to initialize the variables which 
are used to generate the certificates. The variables are optional. When omitted
the easy-rsa default values apply.

In the container a script is availabe to generate keys, certificates and client
configurations: 

	/etc/openvpn/client-configs/makeconfig.sh <name>

This will create a ovpn config file which includes the certificates in

	/etc/openvpn/client-configs/files/<name>.ovpn

You can now copy this file from the container to the host:

	docker cp openvpn:/etc/openvpn/client-configs/files/<name>.ovpn

Sometimes during the first time installation, you will have to wait a while when
the Diffie Hellman parameters are generated.

## Environment variables

- KEY_COUNTRY:     (optional) the country abbreviaion ("NL")
- KEY_PROVINCE:    (optional) the name of the province ("Utrecht")
- KEY_ORG:         (optional) the name of your organization
- KEY_OU:	   (optional) the name of your Organizational Unit
- KEY-NAME:	   (optional) the name of the key
- KEY-COMMON-NAME: (optional) the name the user/computer for which the certificate is created
- DNS_SERVER:	   the ip-address of your dns-server. Will be pushed to clients.
- DOMAIN_NAME:     (optional) the domain name that will be pushed to clients.
- LOCALNETWORK_IP  (optional) the ip-address that will be pushed to client together with
			      the LOCALNETWORK_MASK
- LOCALNETWORK_MASK(optional) see LOCALNETWORK_IP
- ROOT_PASSWORD:   (optional) the password for the root user
