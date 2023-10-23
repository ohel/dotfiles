#!/bin/bash

[ ! -e /dev/serial/matrix_orbital ] && echo No device && exit 1

# init character set to make wide vertical bar graphs
echo -e "\xFE\x76" > /dev/serial/matrix_orbital

# draw vertical bar at column cc of height hh (0x00 ... 0x14)
#echo -e "\xFE\x3D\xcc\xhh" > /dev/serial/matrix_orbital
