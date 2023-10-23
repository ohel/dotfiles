#!/bin/bash
# Make an LCD device backlight glow.

dev=/dev/serial/matrix_orbital

[ ! -e $dev ] && echo No device && exit 1

interval=0.1

while [ 1 ]
do
    echo -en "\xFE\x99\x00" > $dev; sleep $interval
    echo -en "\xFE\x99\x01" > $dev; sleep $interval
    echo -en "\xFE\x99\x03" > $dev; sleep $interval
    echo -en "\xFE\x99\x07" > $dev; sleep $interval
    echo -en "\xFE\x99\x0F" > $dev; sleep $interval
    echo -en "\xFE\x99\x1F" > $dev; sleep $interval
    echo -en "\xFE\x99\x3F" > $dev; sleep $interval
    echo -en "\xFE\x99\x5F" > $dev; sleep $interval
    echo -en "\xFE\x99\x7F" > $dev; sleep $interval
    echo -en "\xFE\x99\xBF" > $dev; sleep $interval
    echo -en "\xFE\x99\xFF" > $dev; sleep $interval
    echo -en "\xFE\x99\xBF" > $dev; sleep $interval
    echo -en "\xFE\x99\x7F" > $dev; sleep $interval
    echo -en "\xFE\x99\x5F" > $dev; sleep $interval
    echo -en "\xFE\x99\x3F" > $dev; sleep $interval
    echo -en "\xFE\x99\x1F" > $dev; sleep $interval
    echo -en "\xFE\x99\x0F" > $dev; sleep $interval
    echo -en "\xFE\x99\x07" > $dev; sleep $interval
    echo -en "\xFE\x99\x03" > $dev; sleep $interval
    echo -en "\xFE\x99\x01" > $dev; sleep $interval
done
