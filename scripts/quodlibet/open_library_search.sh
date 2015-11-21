#!/bin/sh
qlexe="/opt/programs/quodlibet/quodlibet.py"
if ps -ef | grep $qlexe | grep -v grep > /dev/null
 then
  # if running, send open library search command
  $qlexe --open-browser=SearchBar
fi
