#!/usr/bin/bash

[ ! -e /dev/serial/matrix_orbital ] && echo No device && exit 1

# last byte = minutes the light is on, 0 = permanently
echo -e "\xFEB\x00" > /dev/serial/matrix_orbital
