#!/usr/bin/sh
# Start AudioRelay and automatically connect last used server.
# AudioRelay does not currently have any command line parameters so have to use X automation.

cd /opt/programs/AudioRelay/
./bin/AudioRelay &

tries=10
while [ $tries -gt 0 ]
do
    window_id=$(wmctrl -l | grep " AudioRelay$" | head -n 1 | awk '{print $1}')
    sleep 0.2
    tries=$(expr $tries - 1)
    [ "$window_id" ] && break
done
[ ! "$window_id" ] && echo "AudioRelay window not found." && exit 1

wmctrl -ia "$window_id"

# Select the Player tab.
xdotool key Tab
xdotool key Tab
xdotool key Return

sleep 0.5

# Connect to server.
xdotool key Tab
xdotool key Tab
xdotool key Tab
xdotool key Tab
xdotool key Tab
xdotool key Return
