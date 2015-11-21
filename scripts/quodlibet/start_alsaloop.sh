#!/bin/sh
qlexe="/opt/programs/quodlibet/quodlibet.py"
if ! ps -e | grep "pyorbital.py" > /dev/null
 then
 /opt/programs/misc/pyorbital.py 2>&1 &
 sleep 1
fi
if ps -ef | grep $qlexe | grep -v grep > /dev/null
 then
  # if running, toggle visibility
  $qlexe --toggle-window
else
 if test "X$(ps -e | grep alsaloopjack.sh)" == "X"
 then
  exec xfce4-terminal -x ~/.scripts/alsaloopjack.sh &
 fi
 sed -i "s/\(^gst_pipeline.*\) device=.*/\1 device=loop/" ~/.quodlibet/config
 # if not running, start it
 $qlexe 2>&1 &
fi

