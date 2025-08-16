#!/usr/bin/sh
dev=/dev/serial/matrix_orbital && [ ! -e $dev ] && dev=/dev/null

# xC0 = 192
# x54 = 84
echo -en "\xFE\x99\x54" > $dev

# set and save:
#echo -en "\xFE\x98\xC0" > $dev
