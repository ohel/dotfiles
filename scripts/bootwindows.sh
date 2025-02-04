#!/usr/bin/sh
# Boot to first Windows selection either using legacy GRUB or rEFInd with EFI variables, or rEFInd with default selection override.
# For override, give the location of the default selection override file.

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
elif [ ! "$1" ]
then
    efivar=/sys/firmware/efi/efivars/PreviousBoot-36d08fa7-cf0b-42f5-8f14-68df73ed3740
    [ -e $efivar ] && chattr -i $efivar
    if [ ! -r $efivar ] || [ ! -w $efivar ]
    then
        echo "Unable to modify $efivar."
        exit 1
    fi
    # Makes rEFInd boot to the first selection with "Windows" in it.
    # Note: this doesn't work if using faked Windows boot menu entries, e.g. rEFInd or other EFI boot loader just renamed as Windows boot manager.
    iconv -f UTF-16LE -t UTF-8 $efivar | tr "[:print:]" "X" | sed "s/X\{1,\}/Windows/" | iconv -f UTF-8 -t UTF-16LE > $efivar
else
    efipath="$1"
    separators=$(echo "$efipath" | tr -d -c '/' | wc -m)
    # Note: you must have read access to find the file.
    while [ ! -e "$1" ]
    do
        # Try to mount the EFI partition based on given config file path, until the file exists.
        efipath=$(echo "$efipath" | cut -f -$separators -d '/')
        separators=$(expr $separators - 1)
        [ $separators -eq 1 ] && echo "Nothing mountable found." && exit 1
        mount "$efipath" 2>/dev/null
    done
    start_time=$(date +%H:%M)
    end_time=$(date +%H:%M --date="+2 minutes")
    echo "default_selection Windows $start_time $end_time" > "$1"
    # Leave a mark that override is on for boot scripts to disable it.
    touch /opt/enable_refind_default_selection_override
fi

shutdown -r now
