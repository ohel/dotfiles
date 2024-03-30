#!/usr/bin/sh
# Flushes all iptables rules and accepts all packets.

iptables -F
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
echo ""
echo "Flushed iptables rules."
sleep 1
