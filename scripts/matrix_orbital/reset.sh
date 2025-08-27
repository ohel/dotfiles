#!/usr/bin/sh
# Reset, clear (\xFEX), send cursor home (\xFEH) and turn off (\xFEF) LCD.
dev=/dev/serial/matrix_orbital && [ ! -e $dev ] && dev=/dev/null

/usr/bin/stty -F $dev speed 19200 -onlcr

printf "\xFEX\xFEH\xFEF" > $dev
