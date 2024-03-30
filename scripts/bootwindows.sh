#!/usr/bin/sh
# Boot to first Windows selection either using legacy GRUB or rEFInd with EFI variables.

if [ "$(which zenity 2>/dev/null)" ] && [ "$DISPLAY" ]
then
    ! zenity --question --text="Boot to Windows?" && exit
else
    echo Boot to Windows?
    echo Press return to continue, Ctrl-C to abort.
    read tmp
fi

grubdefault=/boot/grub/default
if [ -e $grubdefault ]
then
    if [ ! -r $grubdefault ] || [ ! -w $grubdefault ]
    then
        echo "Check file permissions for $grubdefault, needs +rw."
        exit 1
    fi

    firstwintitle=$(grep title /boot/grub/grub.conf | grep -n . | grep -i windows | head -n 1)
    titlenum=$(expr $(echo $firstwintitle | cut -f 1 -d ':') - 1)
    sed "s/^[0-9]/$titlenum/" $grubdefault > /dev/shm/grub_default
    cp /dev/shm/grub_default $grubdefault
else
    efivar=/sys/firmware/efi/efivars/PreviousBoot-36d08fa7-cf0b-42f5-8f14-68df73ed3740
    [ -e $efivar ] && chattr -i $efivar
    if [ ! -r $efivar ] || [ ! -w $efivar ]
    then
        echo "Unable to modify $efivar."
        exit 1
    fi
    # Makes rEFInd boot to the first selection with "Windows" in it.
    iconv -f UTF-16LE -t UTF-8 $efivar | tr "[:print:]" "X" | sed "s/X\{1,\}/Windows/" | iconv -f UTF-8 -t UTF-16LE > $efivar
fi

sudo shutdown -r now
