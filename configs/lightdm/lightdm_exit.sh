#!/bin/sh
ps -e | grep bluealsa-aplay && killall bluealsa-aplay

dbus-send --system --type=method_call --print-reply=literal --dest=org.bluez /org/bluez/hci0 org.freedesktop.DBus.Properties.Set string:org.bluez.Adapter1 string:Powered variant:boolean:false &

pid=$(ps -ef | grep lcd_glow.sh$ | tr -s ' ' | cut -f 2 -d ' ')
[ $pid ] && kill -9 $pid

# Set brightness and turn backlight off.
echo -en "\xFE\x99\x54\xFEF" > /dev/serial/matrix_orbital
