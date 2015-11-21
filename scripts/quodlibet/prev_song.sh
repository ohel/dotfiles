#!/bin/sh
qlexe="/opt/programs/quodlibet/quodlibet.py"
if ps -ef | grep $qlexe | grep -v grep > /dev/null
 then
  # if running, send some commands
  $qlexe --seek=0:0
  $qlexe --previous
fi
