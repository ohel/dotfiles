#!/usr/bin/sh
dev=/dev/serial/matrix_orbital && [ ! -e $dev ] && dev=/dev/null

printf "\xFE\x93\x00" > $dev
