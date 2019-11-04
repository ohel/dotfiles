#!/bin/sh
# Boot to first Windows selection using legacy GRUB.

if [ "$(which zenity 2>/dev/null)" ] && [ "$DISPLAY" ]
then
    ! zenity --question --text="Boot to Windows?" && exit
else
    echo Boot to Windows?
    echo Press return to continue, CTRL-C to abort.
    read tmp
fi

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
