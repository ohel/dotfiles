#!/bin/bash
source network_reset
echo -e "" > network_reset

adapter=$1
if test "X$adapter" == "X"
then
    adapter=$(cat default_adapter)
    adapter=${adapter:-eth0}
fi
echo "Using adapter: $adapter"

ip=$(ifconfig | grep -A 1 $adapter | tail -n 1 | cut -f 2 -d ":" | cut -f 1 -d " " | grep "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$")

jump="MASQUERADE"
if test "X$ip" != "X"
then
    jump="SNAT --to-source $ip"
fi

sysctl -q -e -w net.ipv4.conf.$adapter.forwarding=1
iptables -t nat -A POSTROUTING -s 10.0.1.0/24 -o $adapter -j $jump
echo "sudo sysctl -q -e -w net.ipv4.conf.$adapter.forwarding=0" >> network_reset
echo "sudo iptables -t nat -D POSTROUTING -s 10.0.1.0/24 -o $adapter -j $jump" >> network_reset
