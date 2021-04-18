#!/bin/sh
# Toggle a HDD mounted/unmount+sleeping state. Also supports RAID setups for HDD sleep.
# The first parameter is the mount location as in fstab.
# The second parameter ("sleep" or "mount") is optional, and may be used to select the operation.

[ "$#" -eq 0 ] && echo "Usage: toggle_hdd.sh <mount location> [sleep|mount]" && exit 1

mountloc="$1"
uuid=$(grep $mountloc /etc/fstab | tr -d [:space:] | tr '\t' ' ' | cut -f 1 -d '/' | cut -f 2 -d '=' | tr -d '"')
device=$(ls -l /dev/disk/by-uuid/$uuid | cut -f 2 -d '>' | cut -f 3 -d '/')

[ ! "$device" ] || [ ! "$uuid" ] && echo "Device not found." && exit 1

mountloc=$(grep $uuid /etc/fstab | tr -s [:space:] | tr '\t' ' ' | cut -f 2 -d ' ')
mounted=0
if [ "$(mount | grep $mountloc)" ] && [ "$2" != "mount" ]
then
    mounted=1
    echo "Unmounting $mountloc..."
    sudo umount $mountloc &
fi

if [ "$(echo $device | grep md)" ]
then
    devices=$(grep $device /proc/mdstat | sed "s/.*\(sd.\).*\(sd.\).*/\1 \2/g")
else
    devices=$(echo $device | tr -d "[:digit:]")
fi

shouldmount=1
if [ $mounted -eq 1 ] || [ "$2" = "sleep" ]
then
    wait
    sleep 2 # Wait for a couple of seconds for the unmount to finish.
    for device in $devices
    do
    	sudo hdparm -Y /dev/$device &
    done
else
    if [ "$2" != "mount" ]
    then
        for device in $devices
        do
            if [ ! "$(sudo hdparm -C /dev/$device | grep standby)" ] && \
               [ ! "$(mount | grep /dev/$device)" ]
                then
                # The drive is not mounted but not sleeping either. Put it to sleep.
                sudo hdparm -Y /dev/$device &
                shouldmount=0
            fi
        done
    fi
    if [ $shouldmount -eq 1 ]
    then
		echo "Mounting $mountloc..."
		sudo mount $mountloc
	fi
fi
sleep 1
