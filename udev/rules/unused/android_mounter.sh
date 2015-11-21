#!/bin/bash
device="$1"
mountpoint="$2"
partition="$device"1

# Try to mount and wait for partition to appear.
# Partition does not appear until one tries to mount the device.
# User has ten seconds to turn on storage in the phone for automatic mount.
iter=0
while [ ! -e $partition ]
do
    sudo mount $device $mountpoint 2>&1
    sleep 1
    iter=`expr $iter + 1`
    if [ $iter -gt 10 ]
        then exit
    fi
done

exit
