#!/bin/bash
# Helper script for launching DVDs (or DVD image files).
# Unfortunately most media players do not support DVD menus anymore.

if [ "$#" = 0 ]; then
    echo "Usage: media_player_dvd.sh [profile shortcut] <filename> [tracknumber]"
    echo "The script calls media_player.sh with DVD parameters as filename."
    exit
fi

profile="$1"
device="$2"
track=$3

if [ "$#" = 1 ]; then
    profile="sr"
    device="$1"
fi

~/.scripts/launchers/media_player.sh $profile --cache=no dvdread://$track --dvd-device="$device"
