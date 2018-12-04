#!/bin/sh
# A startup script for Quod Libet. Output is redirected to a log file for debug purposes.
#
# By default, starts the player or if it's running, toggles its visibility.
# Can be used to modify audio output settings by parameters. Useful when using multiple soundcards.
#
# Supported parameters, passed on to Quod Libet prefixed with --:
#   toggle-window (default if QL is running; does not start the player if parameter given)
#   play-pause (starts the player if it is not running)
# Parameter to change audio device in the config before launching the player:
#   audio <device> [<gst pipeline file>]
# where <device> is an ALSA device.

qlexe=$(ps -ef | grep -o "[^ ]\{1,\}quodlibet.py$")
[ ! $qlexe ] && qlexe=$(which quodlibet.py)
[ ! $qlexe ] && qlexe=/opt/programs/quodlibet/quodlibet.py

logfile=~/.cache/qllog.txt

if [ "$#" = 0 ]
then
    params="--toggle-window"
else
    [ "$1" = "toggle-window" ] && params="--toggle-window"
    [ "$1" = "play-pause" ] && params="--play-pause"
    if [ "$1" = "audio" ] && [ "$#" -gt 1 ]
    then
        device="$2"
        pipelinefile="$3"
    fi
fi

if ! ps -ef | grep $qlexe | grep -v grep > /dev/null
then
    if [ "$pipelinefile" ]
    then
        if [ ! -e $pipelinefile ]
        then
            echo "Pipeline file $pipelinefile does not exist."
            exit 1
        fi
        pipeline=$(cat $pipelinefile)
        sed -i "s/\(^gst_pipeline = \).*/\1 $pipeline/" ~/.quodlibet/config
    fi
    [ "$device" ] && sed -i "s/\(^gst_pipeline.*\) device=.*/\1 device=$device/" ~/.quodlibet/config

    # Don't start QL if just toggling.
    [ "$params" = "--toggle-window" ] && exit

    params="" # Clear params so that QL may start without --run.
else
    # QL is already running, therefore so is the log file.
    logfile="/dev/null"

    # No audio stuff to set anymore, so toggle by default.
    [ "$device" ] && params="--toggle-window"
fi

$qlexe $params >$logfile 2>&1 &
