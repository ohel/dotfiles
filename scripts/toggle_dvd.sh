#!/bin/bash
# Mount or unmount DVD.

device="/dev/sr0"
mountloc="/mnt/dvd"
if test "X$(mount | grep $device)" != "X"
then
    echo Unmounting $device...
    sudo umount $mountloc
    sudo eject $device
else
    echo "Mounting $device..."
    sudo mount $mountloc
fi
