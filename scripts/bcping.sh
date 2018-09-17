#!/bin/sh
# If you have IP address x.y.z.q, ping all addresses x.y.z.$1 - x.y.z.$2.
# $1 defaults to 1 and $2 defaults to 254.
# This is effectively a broadcast ping.

first_ip=${1:-1}
last_ip=${2:-254}

for physical_device in $(ls -l /sys/class/net | grep devices\/pci | grep -o " [^ ]* ->" | cut -f 2 -d ' ')
do
    ip=$(ip addr show $physical_device | grep -o "inet [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | cut -f 2 -d ' ')
    if [ "$ip" ]
    then
        subnet=$(echo $ip | cut -f 1-3 -d '.')
        break
    fi
done

echo Pinging subnet $subnet.
ip=$first_ip
while [ $ip -le $last_ip ]
do
    ping -c 1 -n $subnet.$ip 2>/dev/null | grep "64 bytes" &
    ip=$(expr $ip + 1)
done

sleep 0.1 || sleep 1
echo
