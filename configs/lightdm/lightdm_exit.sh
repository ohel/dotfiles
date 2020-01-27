#!/bin/sh
ps -e | grep bluealsa-aplay && killall bluealsa-aplay

dbus-send --system --type=method_call --print-reply=literal --dest=org.bluez /org/bluez/hci0 org.freedesktop.DBus.Properties.Set string:org.bluez.Adapter1 string:Powered variant:boolean:false 2>/dev/null &

pid=$(ps -ef | grep lcd_glow.sh$ | tr -s ' ' | cut -f 2 -d ' ')
[ $pid ] && kill -9 $pid

while [ $pid ] && [ $pid = $(ps -ef | grep lcd_glow.sh$ | tr -s ' ' | cut -f 2 -d ' ') ]
do
    sleep 1
done

# Mount the device if not mounted already.
mount | grep raidstorage || /mnt/raidstorage_toggle.sh >/dev/null

# Reset brightness and turn backlight off.
[ -e /dev/serial/matrix_orbital ] && /bin/echo -en "\xFE\x99\x54\xFEF" > /dev/serial/matrix_orbital
