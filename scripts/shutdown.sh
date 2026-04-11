#!/usr/bin/sh
# A common shutdown script I use.

if [ "$(which zenity 2>/dev/null)" ] && [ "$DISPLAY" ]
then
    ! zenity --question --text="Shut down?" && exit
else
    echo Shut down?
    echo Press return to continue, Ctrl-C to abort.
    read tmp
fi

scriptsdir=$(dirname "$(readlink -f "$0")")

# Check if OK to shut down.
. $scriptsdir/shutdown_init.sh

# Enable Wake-On-Lan.
if command -v ethtool >/dev/null 2>&1
then
    nic=$(ip route show default 2>/dev/null | awk '{print $5}')
    [ "$nic" ] && ethtool -s "$nic" wol g 2>/dev/null
fi

# Do scheduled backups.
. $scriptsdir/backup_interval.sh

echo "Shutting down..."
sudo shutdown -hP now
