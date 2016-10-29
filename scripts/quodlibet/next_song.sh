#!/bin/sh
# If Quod Libet is running, send next song command.

qlexe="/opt/programs/quodlibet/quodlibet.py"
if ps -ef | grep $qlexe | grep -v grep > /dev/null
then
    $qlexe --next
fi

