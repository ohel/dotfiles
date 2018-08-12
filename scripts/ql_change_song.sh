#!/bin/sh
# If Quod Libet is running, send next song command.
# If $1 = "previous", seek to previous song instead.

qlexe=/opt/programs/quodlibet/quodlibet.py
if ps -ef | grep $qlexe | grep -v grep > /dev/null
then
    if test "X$1" = "Xprevious";
    then
        $qlexe --seek=0:0
        $qlexe --previous
    else
        $qlexe --next
    fi
fi
