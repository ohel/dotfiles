#!/bin/bash
ip=$(ifconfig | grep -A 1 wlp1s0 | tail -n 1 | cut -f 2 -d ":" | cut -f 1 -d " ")
sysctl -q -e -w net.ipv4.conf.wlp1s0.forwarding=0
iptables -t nat -D POSTROUTING -s 10.0.1.0/24 -o wlp1s0 -j SNAT --to-source $ip

sysctl -q -e -w net.ipv4.conf.vmbridge.forwarding=0
iptables -t nat -D POSTROUTING -s 10.0.1.1/32 -o vmbridge -j SNAT --to-source $ip
ip addr del 10.0.1.1/24 dev vmbridge scope host
ip link set vmbridge down
brctl delbr vmbridge
