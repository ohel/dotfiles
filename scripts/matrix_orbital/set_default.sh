#!/usr/bin/sh
dev=/dev/serial/matrix_orbital

printf "|\xcd/|||\xcd ||/\x60 | ||\xcd ||  ||| \xcd||\xcd_\xba|_|| \xcd|" > $dev

# set default screen
printf "\xFE@|\xcd/|||\xcd ||/\x60 | ||\xcd ||  ||| \xcd||\xcd_\xba|_|| \xcd|" > $dev
