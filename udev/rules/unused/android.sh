#!/bin/bash
mountpoint="/mnt/phone"
devid="/dev/disk/by-id/usb-SAMSUNG_S5360_Card_0123456789ABCDEF*"

if test "$1" == "device"
then

    # Call mounter helper script. Exit so that udev processing does not hang.
    /home/panther/.scripts/udev/android_mounter.sh /dev/"$2" $mountpoint &

    exit

elif test "$1" == "partition"
then
    partition=/dev/"$2"
    sudo mount -o uid=panther,gid=users $partition $mountpoint

    export XAUTHORITY=/home/panther/.Xauthority
    export DISPLAY=:0.0

    /usr/bin/thunar $mountpoint/ &
    /usr/bin/xfce4-terminal -x /home/panther/.scripts/copymusic.sh &

    exit

else
    # Manual mount. Try to mount the device.
    # The udev system calls this script again with the partition parameter after trying to mount.
    device="/dev/$(ls -la $devid | cut -f 2 -d '>' | cut -f 3 -d '/')"
    sudo mount $device $mountpoint 2>&1

    exit
fi

