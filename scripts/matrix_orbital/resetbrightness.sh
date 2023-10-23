#!/bin/bash

[ ! -e /dev/serial/matrix_orbital ] && echo No device && exit 1

# xC0 = 192
# x54 = 84
echo -e "\xFE\x99\x54" > /dev/serial/matrix_orbital

# set and save:
#echo -e "\xFE\x98\xC0" > /dev/serial/matrix_orbital
