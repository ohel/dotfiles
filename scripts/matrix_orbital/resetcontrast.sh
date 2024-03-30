#!/usr/bin/bash

[ ! -e /dev/serial/matrix_orbital ] && echo No device && exit 1

echo -e "\xFEP\x80" > /dev/serial/matrix_orbital

# set and save:
#echo -e "\xFE\x91\x80" > /dev/serial/matrix_orbital
