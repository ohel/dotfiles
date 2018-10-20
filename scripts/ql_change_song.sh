#!/bin/sh
# If Quod Libet is running, send next song command.
# If $1 = "previous", seek to previous song instead.

qlexe=/opt/programs/quodlibet/quodlibet.py

[ ! $(ps -ef | grep $qlexe$) ] && exit 1

if [ "$1" = "previous" ]
then
    $qlexe --seek=0:0
    $qlexe --previous
else
    $qlexe --next
fi
