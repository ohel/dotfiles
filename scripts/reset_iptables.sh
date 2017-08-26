#!/bin/bash
# Flushes all iptables rules and accepts all packets.

iptables -F
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
echo -e "\nFlushed iptables rules."
sleep 1
