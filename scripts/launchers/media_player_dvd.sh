#!/usr/bin/sh
# Helper script for launching DVDs (or DVD image files).
# Unfortunately most media players do not support DVD menus anymore.

if [ "$#" = 0 ]
then
    echo "Usage: media_player_dvd.sh [profile shortcut] <filename> [tracknumber]"
    echo "The script calls media_player.sh with DVD parameters as filename."
    exit
fi

device=${2:-$1}
profile="$1"
[ "$#" = 1 ] && profile="sr"

scriptdir=$(dirname "$(readlink -f "$0")")
$scriptdir/media_player.sh $profile \
    --cache=no \
    --deinterlace=auto \
    dvd://$3 --dvd-device="$device"
