#!/usr/bin/sh
dev=/dev/serial/matrix_orbital && [ ! -e $dev ] && dev=/dev/null

# xc0 bright but not too bright
# x54 good default
# x40 for a darker backlight
printf "\xFE\x99\x54" > $dev

# set and save:
#printf "\xFE\x98\xC0" > $dev
