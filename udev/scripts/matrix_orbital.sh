#!/bin/bash
# Init the serial bus speed for the Matrix Orbital LK202 LCD display, and empty the display.
# This script should be called from an udev rule for example.

stty -F /dev/serial/matrix_orbital speed 19200 -onlcr
echo -n -e "\xFEX" > /dev/serial/matrix_orbital
