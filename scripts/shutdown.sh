#!/bin/bash
# A two-phase shutdown script I use.
# First check if it is OK to shut down.
# Then backup stuff if necessary and shut down.

scriptsdir=/home/panther/.scripts
source $scriptsdir/shutdown_init.sh
source $scriptsdir/shutdown_backup.sh
