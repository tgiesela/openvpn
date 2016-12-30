FROM ubuntu:16.04
MAINTAINER Tonny Gieselaar <tonny@devosverzuimbeheer.nl>

ENV DEBIAN_FRONTEND noninteractive

VOLUME ["/etc/openvpn","etc/easy-rsa"]

# Setup ssh and install supervisord and some additional tools
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y openssh-server supervisor \
	net-tools nano apt-utils wget rsyslog \
	dnsutils iputils-ping

# Create folder for ssh and supervisor
RUN mkdir -p /var/run/sshd
RUN mkdir -p /var/log/supervisor

# change sshd configuration to allow root login
RUN sed -ri 's/PermitRootLogin prohibit-password/PermitRootLogin Yes/g' /etc/ssh/sshd_config

# install openvpn and its dependencies
RUN apt-get install -y openvpn openvpn-auth-ldap easy-rsa iptables

# Install utilities needed for setup
RUN apt-get install -y expect pwgen

ADD config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD scripts/buildca.expect scripts/build-key-server.expect /tmp/
ADD config/server.conf config/base.conf scripts/makeconfig.sh scripts/networkid.sh /tmp/
ADD iptables/iptables.conf /tmp/
ADD scripts/init.sh /init.sh
RUN chmod 755 /init.sh

RUN apt-get clean

EXPOSE 1197
ENTRYPOINT ["/init.sh"]
CMD ["app:start"]
