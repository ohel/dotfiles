#!/usr/bin/sh
dev=/dev/serial/matrix_orbital && [ ! -e $dev ] && dev=/dev/null

# init character set to make horizontal bar graphs
echo -en "\xFE\x68" > $dev

# draw horizontal bar at column cc, row r, direction d, of length ll
# ll: 0x00 ... 0x64
# d: 0 = right, 1 = left
#echo -en "\xFE\x7C\xcc\x0r\x0d\xll" > $dev
