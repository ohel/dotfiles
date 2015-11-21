#!/bin/bash

current_vol=$(amixer -cPCH get 'Soft Master',0 | grep "Front Left:" | sed "s/[^0-9]*\([0-9]*\).*/\1/")

if test "$1" == "up" || test "$1" == "+"; then
    new_vol=$(expr $current_vol + 5)
    if [ $new_vol -gt 255 ]; then
        new_vol=255
    fi
elif test "$1" == "down" || test "$1" == "-"; then
    new_vol=$(expr $current_vol - 5)
    if [ $new_vol -lt 5 ]; then
        new_vol=5
    fi
fi

amixer -cPCH set 'Soft Master',0 $new_vol
