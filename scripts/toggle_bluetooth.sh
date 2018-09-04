#!/bin/sh
# Toggles bluetooth radio. If $1 == power, toggle power instead of rfkill (block toggle).

if test "X$1" = "Xpower"
then
    powermode="true"
    if test "X$(dbus-send --system --type=method_call --print-reply=literal --dest=org.bluez /org/bluez/hci0 org.freedesktop.DBus.Properties.Get string:org.bluez.Adapter1 string:Powered | grep true)" != "X"
    then
        powermode="false"
    fi
    dbus-send --system --type=method_call --print-reply=literal --dest=org.bluez /org/bluez/hci0 org.freedesktop.DBus.Properties.Set string:org.bluez.Adapter1 string:Powered variant:boolean:$powermode
    exit
fi

if [ $(sudo rfkill list bluetooth | grep yes | wc -l) -gt 0 ]
then
    sudo rfkill unblock bluetooth
else
    sudo rfkill block bluetooth
fi
