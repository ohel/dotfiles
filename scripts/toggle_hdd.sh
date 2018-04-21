#!/bin/bash
# Toggle a HDD mounted/unmount+sleeping state. Also supports RAID setups for HDD sleep.
# The first parameter is the mount location as in fstab.
# The second parameter ("sleep" or "mount") is optional, and may be used to select the operation.

mountloc="$1"
uuid=$(cat /etc/fstab | grep $mountloc | tr -d [:space:] | tr '\t' ' ' | cut -f 1 -d '/' | cut -f 2 -d '=' | tr -d '"')
device=$(ls -l /dev/disk/by-uuid/$uuid | cut -f 2 -d '>' | cut -f 3 -d '/')

if test "X$device" = "X"
then
    echo "Device not found."
    exit
fi

mountloc=$(cat /etc/fstab | grep 2a95f4c5-e218-41d0-92b3-9fc904cca974 | tr -s [:space:] | tr '\t' ' ' | cut -f 2 -d ' ')
mounted=0
if [ "X$(mount | grep $mountloc)" != "X" ] && [ "X$2" != "Xmount" ]
then
    mounted=1
    echo "Unmounting $mountloc..."
    sudo umount $mountloc &
fi

if test "raid$(echo $device | grep md)" != "raid"
then
    devices=$(cat /proc/mdstat | grep $device | sed "s/.*\(sd.\).*\(sd.\).*/\1 \2/g")
else
    devices=$(echo $device | tr -d "[:digit:]")
fi

shouldmount=1
if [ $mounted -eq 1 ] || [ "X$2" = "Xsleep" ]
then
    wait
    sleep 2 # Wait for a couple of seconds for the unmount to finish.
    for device in $devices
    do
    	sudo hdparm -Y /dev/$device &
    done
else
    for device in $devices
    do
        if test "X$(sudo hdparm -C /dev/$device | grep standby)" = "X"
        then
            if test "X$(mount | grep /dev/$device)" = "X"
            then
                # The drive is not mounted but not sleeping either. Put it to sleep.
                sudo hdparm -Y /dev/$device &
                shouldmount=0
            fi
        fi
    done
    if [ $shouldmount -eq 1 ] || [ "X$2" = "Xmount" ]
    then
		echo "Mounting $mountloc..."
		sudo mount $mountloc
	fi
fi
sleep 1
