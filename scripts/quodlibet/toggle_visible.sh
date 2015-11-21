#!/bin/sh
qlexe="/opt/programs/quodlibet/quodlibet.py"
if ps -ef | grep $qlexe | grep -v grep > /dev/null
 then
  # if running, toggle visibility
  $qlexe --toggle-window
fi
