#!/bin/bash
# A startup script for Quod Libet. Output is redirected to a log file.
#
# By default, starts the player or if it's running, toggles its visibility.
# Also starts up the Matrix Orbital LCD application.
# Can be used to modify audio output settings by parameters. Useful when using multiple soundcards.
#
# Supported parameters, passed on to Quod Libet prefixed with --:
#   toggle-window (default if QL is running; does not start the player if parameter given)
#   play-pause (starts the player if it is not running)
# Parameter to change audio device in the config before launching the player:
#   audio <device>
# where <device> is an ALSA device.

qlexe="/opt/programs/quodlibet/quodlibet.py"
logfile="/dev/shm/qllog.txt"

if ! ps -ef | grep "pyorbital.py" | grep -v grep > /dev/null
then
    /opt/programs/misc/pyorbital.py 2>&1 &
    sleep 1
fi

if [ "$#" = 0 ]; then
    params="--toggle-window"
else
    if [ "$1" = "toggle-window" ]; then
        params="--toggle-window"
    elif [ "$1" = "play-pause" ]; then
        params="--play-pause"
    elif [ "$1" = "audio" ] && [ "$#" -gt 1 ]; then
        device="$2"
        params="--toggle-window"
    fi
fi

if ! ps -ef | grep $qlexe | grep -v grep > /dev/null
then
    if test "X$device" != "X"
    then
        sed -i "s/\(^gst_pipeline.*\) device=.*/\1 device=$device/" ~/.quodlibet/config
    fi

    if [ $params = "--toggle-window" ]; then
        exit # Don't start QL if just toggling.
    fi
    params="" # Clear params so that QL may start without --run.
else
    logfile="/dev/null" # QL is already running, so so is the log file.
fi

$qlexe $params &>$logfile &

