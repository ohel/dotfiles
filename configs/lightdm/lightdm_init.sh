#!/bin/sh
/usr/bin/setxkbmap fi

dbus-send --system --type=method_call --print-reply=literal --dest=org.bluez /org/bluez/hci0 org.freedesktop.DBus.Properties.Set string:org.bluez.Adapter1 string:Powered variant:boolean:true 2>/dev/null

if [ "$(cat /proc/asound/cards | grep \\M4)" ]
then
    ps -e | grep bluealsa && bluealsa-aplay --profile-a2dp 00:00:00:00:00:00 -d m4 &
fi

lcd=/dev/serial/matrix_orbital
if [ -e $lcd ]
then
    /bin/echo -en "\xFEX" > $lcd
    /bin/echo -en "\xFEG\x07\x01minigun" > $lcd
    /bin/echo -en "\xFEG\x08\x02login" > $lcd
fi

# Unmount devices if they are mounted.
mount | grep raidstorage && /mnt/raidstorage_toggle.sh >/dev/null
mount | grep stripestorage && /mnt/stripestorage_toggle.sh >/dev/null
mount | grep usb-backup && umount /mnt/usb-backup >/dev/null

[ -e $lcd ] && /opt/lcd_glow.sh &
