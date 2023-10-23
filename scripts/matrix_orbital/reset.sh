#!/bin/bash
# Reset, clear (\xFEX), send cursor home (\xFEH) and turn off (\xFEF) LCD.

[ ! -e /dev/serial/matrix_orbital ] && echo No device && exit 1

/bin/stty -F /dev/serial/matrix_orbital speed 19200 -onlcr

echo -en "\xFEX\xFEH\xFEF" > /dev/serial/matrix_orbital
