#!/bin/sh
killall -q xbindkeys
setxkbmap fi
xset r rate 200 45
xset b off
setsid xbindkeys
