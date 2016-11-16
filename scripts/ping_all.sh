#!/bin/bash
# If you have IP address x.y.z.q, ping all addresses x.y.z.$1 - x.y.z.$2.
# $1 defaults to 1 and $2 defaults to 254.
# This is effectively a broadcast ping.

first_ip=${1:-1}
last_ip=${2:-254}
net=$(ifconfig | grep "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | grep -v "127.0.0.1" | head -n 1 | tr -s ' ' | cut -f 3 -d ' ' | cut -f -3 -d .)
ip=$first_ip
while [ $ip -le $last_ip ]
do
    ping -c 1 -n $net.$ip | grep time &
    ip=$(expr $ip + 1)
done
