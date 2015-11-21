mountloc="$1"
uuid=$(cat /etc/fstab | grep $mountloc | tr -d [:space:] | cut -f 1 -d '/' | cut -f 2 -d '=' | tr -d '"')
device=$(ls -l /dev/disk/by-uuid/$uuid | cut -f 2 -d '>' | cut -f 3 -d '/')
mounted=false
if test "skip$(mount | grep $mountloc)" != "skip"
then
    mounted=true
    echo Unmounting $mountloc...
    sudo umount $mountloc &
fi

if test "raid$(echo $device | grep md)" != "raid"
then
    devices=$(cat /proc/mdstat | grep $device | sed "s/.*\(sd.\).*\(sd.\).*/\1 \2/g")
else
    devices=$(echo $device | tr -d "[:digit:]")
fi

shouldmount=1
if $mounted
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
        if test "empty$(sudo hdparm -C /dev/$device | grep standby)" == "empty"
        then
            if test "empty$(mount | grep /dev/$device)" == "empty"
            then
                # No mounted drives were found, however the drive is not sleeping. Put it to sleep.
                sudo hdparm -Y /dev/$device &
                shouldmount=0
            fi
        fi
    done
    if [ $shouldmount -eq 1 ]
    then
		echo "Mounting $mountloc..."
		sudo mount $mountloc
	fi
fi
sleep 1
