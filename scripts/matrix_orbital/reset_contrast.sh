#!/usr/bin/sh
dev=/dev/serial/matrix_orbital && [ ! -e $dev ] && dev=/dev/null

printf "\xFEP\x80" > $dev

# set and save:
#printf "\xFE\x91\x80" > $dev
