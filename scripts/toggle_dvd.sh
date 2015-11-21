device="/dev/sr0"
mountloc="/mnt/dvd"
if test "X$(mount | grep $device)" != "X"
then
	echo Unmounting $device...
	sudo umount $mountloc
    sudo eject /dev/sr0
else
	echo "Mounting $device..."
	sudo mount $mountloc
fi
sleep 1

