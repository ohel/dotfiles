#!/bin/sh
# Simple mounter for FAT filesystems.
# You may call mountfat.sh with /dev/sdX, sdX or X, or with no parameters.

if [ "$#" -eq 0 ]
then
    # On my system the sd[a-f] used to be permanent drives.
    ls -d -1 /dev/s* | grep "/dev/sd[g-z]\{1,1\}[0-9]\{0,1\}$"
    exit
fi
user=$(whoami)
sudo mount -o uid=$user,gid=$user /dev/sd$(echo $1 | sed "s/\(\/dev\/\)\?sd//") $2
