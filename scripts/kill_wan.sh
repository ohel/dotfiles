#!/bin/bash
# Prevent all network connections except those to LAN. Forwarding IPv4 is also disabled.

if test "X$(which iptables 2>/dev/null)" = "X"
then
    echo "Executable iptables not in path. Do you have (root) access?"
    exit
fi

for physical_device in $(ls -l /sys/class/net | grep devices\/pci | grep -o " [^ ]* ->" | cut -f 2 -d ' ')
do
    ip=$(ip addr show $physical_device | grep -o "inet [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | cut -f 2 -d ' ')
    if test "X$ip" != "X"
    then
        IF=$physical_device
        subnet=$(echo $ip | cut -f 1 -d '.')
        break
    fi
done

if test "X$1" = "Xrestore"
then
    iptables -F
    iptables -P INPUT ACCEPT
    iptables -P OUTPUT ACCEPT

    sysctl -q -e -w net.ipv4.conf.$IF.forwarding=1

    echo "Flushed iptables rules. WAN connections are allowed."
    sleep 1
    exit
fi

iptables -F
iptables -P INPUT DROP
iptables -P OUTPUT DROP

lan_net=0
if test "X$subnet" = "X192"
then
    lan_net=168
fi
iptables -A INPUT -s $subnet.$lan_net.0.0/16 -d $ip/32 -j ACCEPT
iptables -A OUTPUT -s $ip/32 -d $subnet.$lan_net.0.0/16 -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

vmbridge_net=$(ip addr show vmbridge | grep "inet " | tr -s ' ' | cut -f 3 -d ' ' | cut -f 1 -d '/' | cut -f 1-3 -d '.')

if test "X$vmbridge_net" != "X"
then
    iptables -A INPUT -s $vmbridge_net.0/24 -d $vmbridge_net.0/24 -j ACCEPT
    iptables -A INPUT -s $vmbridge_net.0/24 -d $subnet.$lan_net.0.0/16 -j ACCEPT
    iptables -A OUTPUT -s $vmbridge_net.0/24 -d $vmbridge_net.0/24 -j ACCEPT
    iptables -A OUTPUT -s $subnet.$lan_net.0.0/16 -d $vmbridge_net.0/24 -j ACCEPT
fi

sysctl -q -e -w net.ipv4.conf.$IF.forwarding=0

echo "WAN connections are prevented."
sleep 1
