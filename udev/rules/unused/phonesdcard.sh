#!/bin/bash
mountpoint="/mnt/phone"
partition=/dev/"$1"
sudo mount -o uid=panther,gid=users $partition $mountpoint

export XAUTHORITY=/home/panther/.Xauthority
export DISPLAY=:0.0

/usr/bin/xfce4-terminal -x /home/panther/.scripts/copymusic.sh

exit
