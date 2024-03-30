#!/usr/bin/sh
# Argument $1 will be the name of the interface, e.g. tap0
/usr/bin/brctl addif vmbridge $1 && /usr/bin/ip link set $1 up
