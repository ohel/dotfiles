#!/usr/bin/sh
# Compiz 0.9 series installed with prefix /opt/programs/compiz.

if [ "$(ps -e | grep compiz)" ]
then
    killall -9 compiz
    killall -9 gtk-window-decorator
fi
env LD_LIBRARY_PATH=/opt/programs/compiz/lib64:/opt/programs/compiz/lib/compiz /opt/programs/compiz/bin/compiz ccp --replace &

/opt/programs/compiz/bin/gtk-window-decorator --replace &

# This would use the metacity theme /usr/share/themes/current_compiz but it only works if Metacity is installed.
# /opt/programs/compiz/bin/gtk-window-decorator --replace --metacity-theme current_compiz &
