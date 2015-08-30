#!/bin/bash
#
# Argument $1 will be the name of the interface (tun0, tun1, ...)

/sbin/brctl addif vmbridge $1
#/usr/bin/tunctl -u root -t $1
/bin/ip link set $1 up
exit 0
