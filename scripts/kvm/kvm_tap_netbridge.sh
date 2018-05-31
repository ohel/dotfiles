#!/bin/sh
# Argument $1 will be the name of the interface, e.g. tap0
/sbin/brctl addif netbridge $1 && /bin/ip link set $1 up
