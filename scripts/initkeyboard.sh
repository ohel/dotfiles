#!/bin/sh
# Sometimes at least the Microsoft Natural Ergonomic 4000 keyboard acts weirdly or hangs up.
# Reconnecting it physically works, but I have to set everything anew. This script solves that.

killall -q xbindkeys
setxkbmap fi
xset r rate 200 45
xset b off
setsid xbindkeys
