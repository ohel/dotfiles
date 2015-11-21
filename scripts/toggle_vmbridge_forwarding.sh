#!/bin/bash
oldval=$(cat /proc/sys/net/ipv4/conf/vmbridge/forwarding)
newval=$(expr $(expr $oldval - 1) \* $(expr $oldval - 1))
sysctl -q -e -w net.ipv4.conf.vmbridge.forwarding=$newval
sysctl -q -e -w net.ipv6.conf.vmbridge.forwarding=$newval
echo Forwarding now: $newval
