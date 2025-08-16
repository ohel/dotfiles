#!/usr/bin/sh
dev=/dev/serial/matrix_orbital && [ ! -e $dev ] && dev=/dev/null

# init character set to make wide vertical bar graphs
echo -en "\xFE\x76" > $dev

# draw vertical bar at column cc of height hh (0x00 ... 0x14)
#echo -e "\xFE\x3D\xcc\xhh" > $dev
