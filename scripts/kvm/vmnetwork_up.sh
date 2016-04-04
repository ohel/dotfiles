#!/bin/bash
adapter=$1
if test "X$adapter" == "X"
then
    adapter=eth0
fi

modprobe tun

ip=$(ifconfig | grep -A 1 $adapter | tail -n 1 | cut -f 2 -d ":" | cut -f 1 -d " " | grep "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$")

jump="MASQUERADE"
if test "X$ip" != "X"
then
    jump="SNAT --to-source $ip"
fi

sysctl -q -e -w net.ipv4.conf.$adapter.forwarding=1
iptables -t nat -A POSTROUTING -s 10.0.1.0/24 -o $adapter -j $jump

# Virtual machine bridge.
brctl addbr vmbridge
ip link set vmbridge up
ip addr add 10.0.1.1/24 dev vmbridge scope host
sysctl -q -e -w net.ipv4.conf.vmbridge.forwarding=1

# Virtual localhost. Use this IP within guests to use services running locally on the host.
ip tuntap add mode tap vlocalhost
ip link set vlocalhost up
ip addr add 10.0.1.127/24 dev vlocalhost scope host
iptables -t nat -A PREROUTING -i vlocalhost -j DNAT --to 127.0.0.1

