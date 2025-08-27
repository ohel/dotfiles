#!/usr/bin/sh
# Compiz 0.9 series installed with custom prefix.

prefix=/opt/programs/compiz

if ps -ef | grep "$prefix/bin/compiz" | grep -qv grep
then
    killall -9 compiz 2>/dev/null
    killall -9 gtk-window-decorator 2>/dev/null
fi
env LD_LIBRARY_PATH=$prefix/lib64:$prefix/lib/compiz $prefix/bin/compiz ccp --replace &

$prefix/bin/gtk-window-decorator --replace &

# This would use the metacity theme /usr/share/themes/current_compiz but it only works if Metacity is installed.
# $prefix/bin/gtk-window-decorator --replace --metacity-theme current_compiz &
