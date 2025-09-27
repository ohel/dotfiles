#!/usr/bin/sh
# Init the serial bus speed for a Matrix Orbital LCD display, and empty the display.
# This script should be called from an udev rule for example.

/usr/bin/stty -F /dev/serial/matrix_orbital speed 19200 -onlcr
printf "\xFEX" > /dev/serial/matrix_orbital
