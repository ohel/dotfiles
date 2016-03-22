#!/bin/bash
adapter=wlp1s0
ip=$(ifconfig | grep -A 1 $adapter | tail -n 1 | cut -f 2 -d ":" | cut -f 1 -d " " | grep "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$")
if test "X$ip" == "X"
then
    ip=127.0.0.1
    echo "Using localhost as source NAT IP"
fi

sysctl -q -e -w net.ipv4.conf.$adapter.forwarding=0
iptables -t nat -D POSTROUTING -s 10.0.1.0/24 -o $adapter -m iprange ! --dst-range 10.0.0.0-10.255.255.255 -m iprange ! --dst-range 127.0.0.1 -j SNAT --to-source $ip

sysctl -q -e -w net.ipv4.conf.vmbridge.forwarding=0
iptables -t nat -D POSTROUTING -s 10.0.1.1/32 -o vmbridge -m iprange ! --dst-range 10.0.0.0-10.255.255.255 -m iprange ! --dst-range 127.0.0.1 -j SNAT --to-source $ip
ip addr del 10.0.1.1/24 dev vmbridge scope host
ip link set vmbridge down
brctl delbr vmbridge
