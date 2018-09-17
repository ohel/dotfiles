#!/bin/sh
# Boot to first Windows selection using legacy GRUB.

firstwintitle=$(cat /boot/grub/grub.conf | grep title | grep -n . | grep -i windows | head -n 1)
titlenum=$(expr $(echo $firstwintitle | cut -f 1 -d ':') - 1)
sed "s/^[0-9]/$titlenum/" default > /dev/shm/grub_default
cp /dev/shm/grub_default /boot/grub/default
sudo shutdown -r now
