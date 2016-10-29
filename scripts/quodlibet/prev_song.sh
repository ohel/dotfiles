#!/bin/sh
# If Quod Libet is running, send commands to go to previous song.

qlexe="/opt/programs/quodlibet/quodlibet.py"
if ps -ef | grep $qlexe | grep -v grep > /dev/null
then
    $qlexe --seek=0:0
    $qlexe --previous
fi
