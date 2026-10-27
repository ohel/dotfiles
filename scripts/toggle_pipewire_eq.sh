#!/usr/bin/sh
# Toggle PipeWire default sink between ALSA bridge and eq filter.

current_sink=$(wpctl inspect @DEFAULT_AUDIO_SINK@ | grep node.name | cut -f 2 -d '=' | tr -d "\" ")
case "$current_sink" in
    eq-input)
        next_sink="alsa-bridge"
        ;;
    alsa-bridge)
        next_sink="eq-input"
        ;;
    *)
        echo "Unknown default sink: $current_sink" >&2
        exit 1
        ;;
esac

next_id=$(wpctl status -n | grep $next_sink | grep -o '[0-9]\+')

[ -z "$next_id" ] && echo "Could not find sink: $next_sink" >&2 && exit 1

wpctl set-default "$next_id"
echo "Default sink: $next_sink"
notify-send -h int:transient:1 "Default sink: $next_sink" -t 1000
