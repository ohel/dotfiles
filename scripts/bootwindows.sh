#!/bin/sh
# Boot to first Windows selection using legacy GRUB.

grubdefault=/boot/grub/default
if [ ! -r $grubdefault ] || [ ! -w $grubdefault ]
then
    echo "Check file permissions for $grubdefault, needs o+rw."
    exit 1
fi

firstwintitle=$(cat /boot/grub/grub.conf | grep title | grep -n . | grep -i windows | head -n 1)
titlenum=$(expr $(echo $firstwintitle | cut -f 1 -d ':') - 1)
sed "s/^[0-9]/$titlenum/" $grubdefault > /dev/shm/grub_default
cp /dev/shm/grub_default $grubdefault
sudo shutdown -r now
