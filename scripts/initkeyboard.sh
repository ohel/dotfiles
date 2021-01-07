#!/bin/sh
# Sometimes at least the Microsoft Natural Ergonomic 4000 keyboard acts weirdly or hangs up.
# Reconnecting it physically works, but one has to set everything anew. This script solves that.

secs=0
for pid in $(ps -ef | grep "xbindkeys$" | tr -s ' ' | cut -f 2 -d ' ')
do
    kill $pid
    secs=1
done
sleep $secs

setxkbmap fi
xset r rate 200 45
xset b off
xbindkeys
