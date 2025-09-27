#!/usr/bin/sh
# Toggles bluetooth radio.
# If $1 = power, toggle power instead of rfkill (block toggle).
# If $2 = on|off, set on or off instead of toggling.
# If ~/.config/auto-bluealsa-aplay exists and bluealsa is running, bluealsa-aplay is started/stopped also.

if [ "$1" = "power" ]
then
    powermode="true"
    [ "$(dbus-send --system --type=method_call --print-reply=literal --dest=org.bluez /org/bluez/hci0 org.freedesktop.DBus.Properties.Get string:org.bluez.Adapter1 string:Powered | grep true)" ] && powermode="false"
    [ "$2" = "on" ] && powermode="true"
    [ "$2" = "off" ] && powermode="false"

    dbus-send --system --type=method_call --print-reply=literal --dest=org.bluez /org/bluez/hci0 org.freedesktop.DBus.Properties.Set string:org.bluez.Adapter1 string:Powered variant:boolean:$powermode

    if [ -e ~/.config/auto-bluealsa-aplay ]
    then
        [ "$powermode" = "true" ] && ps -e | grep bluealsa >/dev/null && bluealsa-aplay &
        [ "$powermode" = "false" ] && ps -e | grep bluealsa-aplay >/dev/null && killall bluealsa-aplay
    fi

    [ "$powermode" = "true" ] && powermode="on" || powermode="off"
    [ "$(which notify-send 2>/dev/null)" ] && notify-send -h int:transient:1 "Bluetooth: $powermode" -t 500
    exit 0
fi

cmd=block
[ $(rfkill list bluetooth | grep yes | wc -l) -gt 0 ] && cmd=unblock
[ "$2" = "on" ] && cmd="unblock"
[ "$2" = "off" ] && cmd="block"

sudo rfkill $cmd bluetooth

if [ -e ~/.config/auto-bluealsa-aplay ]
then
    [ "$cmd" = "unblock" ] && ps -e | grep bluealsa >/dev/null && bluealsa-aplay &
    [ "$cmd" = "block" ] && ps -e | grep bluealsa-aplay >/dev/null && killall bluealsa-aplay
fi

cmd="$cmd"ed
[ "$(which notify-send 2>/dev/null)" ] && notify-send -h int:transient:1 "Bluetooth: $cmd" -t 500
