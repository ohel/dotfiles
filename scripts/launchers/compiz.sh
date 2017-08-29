#!/bin/sh
# Compiz 0.9 series installed with prefix /opt/programs/compiz.

if test "$(ps -e | grep compiz)"
    then
    killall -9 compiz
    killall -9 gtk-window-decorator
fi
LD_LIBRARY_PATH=/opt/programs/compiz/lib64:/opt/programs/compiz/lib/compiz exec /opt/programs/compiz/bin/compiz ccp --replace &
exec /opt/programs/compiz/bin/gtk-window-decorator --replace &
#exec /opt/programs/compiz/bin/gtk-window-decorator --metacity-theme "metacity_panther" &
