#!/bin/bash
# You may call mountfat.sh with /dev/sdX, sdX or X, or with no parameters.
if [ "$#" -eq 0 ]; then
    ls -d -1 /dev/s* | grep "/dev/sd[g-z]\{1,1\}[0-9]\{0,1\}$"
    exit
fi
sudo mount -o uid=panther,gid=panther /dev/sd$(echo $1 | sed "s/\(\/dev\/\)\?sd//") $2
