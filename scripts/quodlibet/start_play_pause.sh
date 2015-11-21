#!/bin/sh
qlexe="/opt/programs/quodlibet/quodlibet.py"
if ! ps -e | grep "pyorbital.py" > /dev/null
 then
 /opt/programs/misc/pyorbital.py 2>&1 &
 sleep 1
fi
if ps -ef | grep $qlexe | grep -v grep > /dev/null
 then
  # if running, send play/pause command
  $qlexe --play-pause
else
 # if not running, start it
 $qlexe 2>&1 &
fi
