#!/usr/bin/sh
dev=/dev/serial/matrix_orbital && [ ! -e $dev ] && dev=/dev/null

# last byte = minutes the light is on, 0 = permanently
echo -en "\xFEB\x00" > $dev
