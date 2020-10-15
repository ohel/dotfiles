#!/bin/sh
# When using an unstable consumer class router that likes to break down
# every now and then, detect when it's behaving badly and reboot it
# by calling a script with router model parameter.

routermodel=${1:-fast}
autoparam=$2

routerip=$(ip route | grep default | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")

echo "Pinging router to check if reboot required..."
loss=$(ping -c 10 $routerip | grep '% packet loss')
[ "$(echo $loss | grep ' 0%')" != "" ] && echo "Router seems OK." && exit
[ "$(echo $loss | grep '100%')" != "" ] && echo "100% packet loss, is the router connected at all?" && exit

echo "Packet loss detected. Going to reboot router."

scriptsdir=$(dirname "$(readlink -f "$0")")
setsid xfce4-terminal -e "bash -c '$scriptsdir/router_reboot.sh $routermodel $autoparam'"
