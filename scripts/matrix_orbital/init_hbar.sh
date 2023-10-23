#!/bin/bash

[ ! -e /dev/serial/matrix_orbital ] && echo No device && exit 1

# init character set to make horizontal bar graphs
echo -e "\xFE\x68" > /dev/serial/matrix_orbital

# draw horizontal bar at column cc, row r, direction d, of length ll
# ll: 0x00 ... 0x64
# d: 0 = right, 1 = left
#echo -e "\xFE\x7C\xcc\x0r\x0d\xll" > /dev/serial/matrix_orbital
