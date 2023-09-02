#!/bin/sh
# Sometimes a keyboard acts weird or hangs up.
# Reconnecting it physically usually works, but everything must be set anew. This script solves that.

secs=0
for pid in $(ps -ef | grep "xbindkeys$" | tr -s ' ' | cut -f 2 -d ' ')
do
    kill $pid
    secs=1
done
sleep $secs

[ !"$DISPLAY" ] && DISPLAY=:0.0
setxkbmap fi
xset r rate 200 45
xset b off
xbindkeys
