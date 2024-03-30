#!/usr/bin/sh
# Mount or unmount DVD.

device="/dev/sr0"
mountloc="/mnt/dvd"
if [ "$(mount | grep $device)" ]
then
    echo Unmounting $device...
    sudo umount $mountloc
    sudo eject $device
else
    echo "Mounting $device..."
    sudo mount $mountloc
fi
