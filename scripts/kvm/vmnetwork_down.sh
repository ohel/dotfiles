#!/bin/bash
adapter=$1
if test "X$adapter" == "X"
then
    adapter=eth0
fi

ip=$(ifconfig | grep -A 1 $adapter | tail -n 1 | cut -f 2 -d ":" | cut -f 1 -d " " | grep "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$")

jump="MASQUERADE"
if test "X$ip" != "X"
then
    jump="SNAT --to-source $ip"
fi

sysctl -q -e -w net.ipv4.conf.$adapter.forwarding=0
iptables -t nat -D POSTROUTING -s 10.0.1.0/24 -o $adapter -j $jump

sysctl -q -e -w net.ipv4.conf.vmbridge.forwarding=0
ip addr del 10.0.1.1/24 dev vmbridge scope host
ip link set vmbridge down
brctl delbr vmbridge

iptables -t nat -D PREROUTING -i vlocalhost -j DNAT --to 127.0.0.1
ip addr del 10.0.1.127/24 dev vlocalhost scope host
ip link set vlocalhost down 
ip tuntap del mode tap vlocalhost

