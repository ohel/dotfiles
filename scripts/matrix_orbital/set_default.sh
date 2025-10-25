#!/usr/bin/sh
dev=/dev/serial/matrix_orbital

# LK202-24-USB font
#printf "|\xcd/|||\xcd ||/\x60 | ||\xcd ||  ||| \xcd||\xcd_\xba|_|| \xcd|" > $dev
# LK202-25-USB font
printf "|\x5c/|||\x5c ||/\xbf\xb3| ||\x5c ||  ||| \x5c||\x5c_\x5d|_|| \x5c|" > $dev

# set default screen
printf "\xFE@|\x5c/|||\x5c ||/\xbf\xb3| ||\x5c ||  ||| \x5c||\x5c_\x5d|_|| \x5c|" > $dev
