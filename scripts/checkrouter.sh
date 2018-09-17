#!/bin/sh
# When using an unstable consumer class router that likes to break down
# every now and then, detect when it's behaving badly and reboot it
# by calling a script with router model parameter.

routermodel=${1:-fast}

routerip=$(ip route | grep default | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")

echo "Pinging router to check if reboot required..."
[ "$(ping -c 10 $routerip | grep ' 0% packet loss')" != "" ] && echo "Router seems OK." && exit

echo "Packet loss detected. Going to reboot router."

scriptsdir=$(dirname "$(readlink -f "$0")")
setsid xfce4-terminal -e "bash -c '$scriptsdir/rebootrouter.sh $routermodel'"
