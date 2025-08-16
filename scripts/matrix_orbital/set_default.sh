#!/usr/bin/sh
dev=/dev/serial/matrix_orbital

echo -en "|\xcd/|||\xcd ||/\x60 | ||\xcd ||  ||| \xcd||\xcd_\xba|_|| \xcd|" > $dev

# set default screen
echo -en "\xFE@|\xcd/|||\xcd ||/\x60 | ||\xcd ||  ||| \xcd||\xcd_\xba|_|| \xcd|" > $dev
