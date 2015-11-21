#!/bin/sh
qlexe="/opt/programs/quodlibet/quodlibet.py"
if ps -ef | grep $qlexe | grep -v grep > /dev/null
 then
  # if running, send play/pause command
  $qlexe --next
fi

