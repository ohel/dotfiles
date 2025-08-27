#!/usr/bin/sh
dev=/dev/serial/matrix_orbital && [ ! -e $dev ] && dev=/dev/null

# col, row
printf "\xFEG\x01\x01" > $dev
