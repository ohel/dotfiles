#!/bin/bash
ip=$(ifconfig | grep -A 1 wlp1s0 | tail -n 1 | cut -f 2 -d ":" | cut -f 1 -d " ")
sysctl -q -e -w net.ipv4.conf.wlp1s0.forwarding=1
iptables -t nat -A POSTROUTING -s 10.0.1.0/24 -o wlp1s0 -j SNAT --to-source $ip

brctl addbr vmbridge
ip link set vmbridge up
ip addr add 10.0.1.1/24 dev vmbridge scope host
sysctl -q -e -w net.ipv4.conf.vmbridge.forwarding=1
iptables -t nat -A POSTROUTING -s 10.0.1.1/32 -o vmbridge -j SNAT --to-source $ip
