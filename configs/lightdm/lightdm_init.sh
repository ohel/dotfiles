#!/bin/sh
/usr/bin/setxkbmap fi

dbus-send --system --type=method_call --print-reply=literal --dest=org.bluez /org/bluez/hci0 org.freedesktop.DBus.Properties.Set string:org.bluez.Adapter1 string:Powered variant:boolean:true

ps -e | grep bluealsa && bluealsa-aplay --profile-a2dp 00:00:00:00:00:00 -d julia &

lcd=/dev/serial/matrix_orbital
echo -en "\xFEX\xFEG\x07\x01minigun" > $lcd
echo -en "\xFEG\x08\x02login" > $lcd

/opt/lcd_glow.sh &
