#!/bin/sh
# Toggles bluetooth radio. If $1 = power, toggle power instead of rfkill (block toggle).

if [ "$1" = "power" ]
then
    powermode="true"
    [ "$(dbus-send --system --type=method_call --print-reply=literal --dest=org.bluez /org/bluez/hci0 org.freedesktop.DBus.Properties.Get string:org.bluez.Adapter1 string:Powered | grep true)" ] && powermode="false"
    dbus-send --system --type=method_call --print-reply=literal --dest=org.bluez /org/bluez/hci0 org.freedesktop.DBus.Properties.Set string:org.bluez.Adapter1 string:Powered variant:boolean:$powermode
    exit
fi

cmd=block
[ $(rfkill list bluetooth | grep yes | wc -l) -gt 0 ] && cmd=unblock

sudo rfkill $cmd bluetooth
