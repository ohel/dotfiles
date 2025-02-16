#!/usr/bin/sh
# There is the "Force full screen redraws (buffer swap) on repaint" option in Compiz's Workarounds plugin. Sometimes, especially if using two displays or a dock, it is needed for random flickering to stop.
# However, it increases power consumption of the GPU a bit. Hence this toggle. Set the Workarounds plugin config manually beforehand, this only toggles the plugin on and off.
# $1 = "off" will force the Workarounds plugin off,
# $1 = "on" will force the plugin on. Empty $1 toggles current state.
# Editing the Compiz config file (when using flat file backend) updates the running configuration live.

config_file=~/.config/compiz-1/compizconfig/Default.ini

current=$(grep "s0_active_plugins" $config_file | grep -o "workarounds;")

[ "$1" = "off" ] && [ ! "$current" ] && exit 0
[ "$1" = "on" ] && [ "$current" ] && exit 0

if [ "$current" ]
then
    sed -i "s/s0_active_plugins = \(.*\)workarounds;\(.*\)/s0_active_plugins = \1\2/" $config_file
    [ "$(which notify-send 2>/dev/null)" ] && notify-send -h int:transient:1 "Workarounds: off" -t 1000
    exit 0
fi

sed -i "s/s0_active_plugins = \(.*\)/s0_active_plugins = \1workarounds;/" $config_file
[ "$(which notify-send 2>/dev/null)" ] && notify-send -h int:transient:1 "Workarounds: on" -t 1000
