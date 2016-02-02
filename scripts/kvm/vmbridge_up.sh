#!/bin/bash
ip=$(ifconfig | grep -A 1 wlp1s0 | tail -n 1 | cut -f 2 -d ":" | cut -f 1 -d " " | grep "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$")
if test "X$ip" == "X"
then
    ip=127.0.0.1
    echo "Using localhost as source NAT IP"
fi

sysctl -q -e -w net.ipv4.conf.wlp1s0.forwarding=1
iptables -t nat -A POSTROUTING -s 10.0.1.0/24 -o wlp1s0 -m iprange ! --dst-range 10.0.0.0-10.255.255.255 -m iprange ! --dst-range 127.0.0.1 -j SNAT --to-source $ip

brctl addbr vmbridge
ip link set vmbridge up
ip addr add 10.0.1.1/24 dev vmbridge scope host
sysctl -q -e -w net.ipv4.conf.vmbridge.forwarding=1
iptables -t nat -A POSTROUTING -s 10.0.1.1/32 -o vmbridge -m iprange ! --dst-range 10.0.0.0-10.255.255.255 -m iprange ! --dst-range 127.0.0.1 -j SNAT --to-source $ip

# TODO: a dummy address to redirect to localhost on host
#iptables -t nat -A PREROUTING -m iprange --dst-range 10.0.1.127 -j DNAT --to 127.0.0.1
#iptables -t nat -A POSTROUTING -m iprange --src-range 10.0.0.127 -m iprange --dst-range 10.0.1.0-10.0.1.255 -j SNAT --to 10.0.1.127
#iptables -t nat -A PREROUTING -i vmbridge -m iprange --dst-range 10.0.1.127 -j DNAT --to 127.0.0.1
