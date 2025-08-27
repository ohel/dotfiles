#!/usr/bin/sh
# Mouse emulation and mouse key bindings to keyboard using xbindkeys.
# At least with Compiz, sometimes binding Alt+F4 fails. Trying a second time fixes the issue.
# This script sources the init_keyboard.sh script, so use either on startup, but not both.

scriptsdir=$(dirname "$(readlink -f "$0")")

killall xbindkeys 2>/dev/null
. $scriptsdir/init_keyboard.sh
xbindkeys -f $scriptsdir/../dotfiles/xbindkeys_mousekeys
xbindkeys -fg $scriptsdir/../dotfiles/xbindkeys_mousekeys.scm
xbindkeys -fg $scriptsdir/../dotfiles/xbindkeys_mouseemu.scm

# This is to fix Alt+F4 binding issue. Sometimes it just refuses to bind the first time.
sleep 2
xbkpid=$(ps -ef | grep "xbindkeys$" | tr -s ' ' | cut -f 2 -d ' ')
kill $xbkpid
while [ "$xbkpid" ]
do
    sleep 1
    xbkpid=$(ps -ef | grep "xbindkeys$" | tr -s ' ' | cut -f 2 -d ' ')
done
xbindkeys
