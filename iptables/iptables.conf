
# Allow traffic initiated from VPN to access LAN
iptables -I FORWARD -i tun0 -o eth0 \
         -s 10.8.5.0/24 -d 172.18.0.0/24 \
         -m conntrack --ctstate NEW -j ACCEPT

# Allow established traffic to pass back and forth
iptables -I FORWARD -m conntrack --ctstate RELATED,ESTABLISHED \
         -j ACCEPT

# Masquerade all traffic from VPN clients -- done in the nat table
iptables -t nat -I POSTROUTING -o eth0 \
          -s 10.8.5.0/24 -j MASQUERADE

