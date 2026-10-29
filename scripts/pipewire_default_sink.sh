#!/usr/bin/sh
# Set PipeWire default sink by matching name to $1.
# To use a Bluetooth device for example, use "bluez".

id=$(wpctl status -n | sed '1,/Sinks:/d' | grep "$1" | grep -o "[0-9]*\." | head -n 1 | tr -d '.')

[ -z "$id" ] && echo "Could not find sink: $1" >&2 && exit 1

wpctl set-default "$id"
name=$(wpctl inspect @DEFAULT_AUDIO_SINK@ | grep node.description | cut -f 2 -d '"')
echo "Default sink: $name"
notify-send -h int:transient:1 "Default sink: $name" -t 1000
