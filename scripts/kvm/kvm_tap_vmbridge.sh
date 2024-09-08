#!/usr/bin/sh
# Argument $1 will be the name of the interface, e.g. tap0
ip link set $1 master vmbridge
ip link set $1 up
