#!/bin/bash
# Make an LCD device backlight glow.

dev=/dev/serial/matrix_orbital
int=0.05

while [ 1 ]
do
    echo -en "\xFE\x99\x00" > $dev; sleep $int
    echo -en "\xFE\x99\x0F" > $dev; sleep $int
    echo -en "\xFE\x99\x23" > $dev; sleep $int
    echo -en "\xFE\x99\x37" > $dev; sleep $int
    echo -en "\xFE\x99\x4B" > $dev; sleep $int
    echo -en "\xFE\x99\x5F" > $dev; sleep $int
    echo -en "\xFE\x99\x73" > $dev; sleep $int
    echo -en "\xFE\x99\x87" > $dev; sleep $int
    echo -en "\xFE\x99\x9B" > $dev; sleep $int
    echo -en "\xFE\x99\xAF" > $dev; sleep $int
    echo -en "\xFE\x99\xC3" > $dev; sleep $int
    echo -en "\xFE\x99\xD7" > $dev; sleep $int
    echo -en "\xFE\x99\xEB" > $dev; sleep $int
    echo -en "\xFE\x99\xFF" > $dev; sleep $int
    echo -en "\xFE\x99\xEB" > $dev; sleep $int
    echo -en "\xFE\x99\xD7" > $dev; sleep $int
    echo -en "\xFE\x99\xC3" > $dev; sleep $int
    echo -en "\xFE\x99\xAF" > $dev; sleep $int
    echo -en "\xFE\x99\x9B" > $dev; sleep $int
    echo -en "\xFE\x99\x87" > $dev; sleep $int
    echo -en "\xFE\x99\x73" > $dev; sleep $int
    echo -en "\xFE\x99\x5F" > $dev; sleep $int
    echo -en "\xFE\x99\x4B" > $dev; sleep $int
    echo -en "\xFE\x99\x37" > $dev; sleep $int
    echo -en "\xFE\x99\x23" > $dev; sleep $int
    echo -en "\xFE\x99\x0F" > $dev; sleep $int
done
