#!/bin/sh
# Play an alert sound if there is a file called alert.set in user's home directory.
# May be used e.g. with an email client which generates the file on certain conditions.
# Use crontab to schedule the alert checking for the user (crontab -e -u user).

wav=${1:-~/.local/share/misc/alert.wav}
alsadev=${2:-hifi}

if [ -e ~/alert.set ]
then
    echo $(date) >> ~/alert.hit
    # Try a specific sound device first, use default device as a fallback.
    if [ "$(aplay -q -D $alsadev $wav)" ]
    then
        aplay -q $wav
    fi
else
    echo $(date) >> ~/alert.pass
fi
