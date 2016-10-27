#/bin/bash
# A three-phase shutdown script I use.
# First check if it is OK to shut down.
# Then backup stuff if necessary.
# Finally call the actual shutdown.

scriptsdir=/home/panther/.scripts
source $scriptsdir/shutdown_init.sh
source $scriptsdir/shutdown_backup.sh
source $scriptsdir/shutdown_poweroff.sh

