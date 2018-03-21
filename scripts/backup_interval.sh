#!/bin/bash
# Call system backup script depending on how long it is since last backup.
# Backup is skipped if backup mount point doesn't exist.

backup() {
    userhome=/home/panther
    backupmountpoint=/mnt/raidstorage

    if ! [ -e $backupmountpoint ]
        then return
    fi

    backupdir=backups/misc/home_dirs/$(basename $userhome)
    checkfile=$userhome/.local/share/misc/lastsync/misc
    if ! [ -e $checkfile ]
        then touch $checkfile
    fi
    lastsyncmisc=$(expr $(date +%s) - $(stat -c %Z $checkfile))

    sync=0
    if [ $lastsyncmisc -gt 302400 ]
        then sync=1
    fi

    if [ $sync -eq 1 ]
    then
        backup=$(mount | grep $backupmountpoint)
        if test "empty$backup" == "empty"
            then sudo mount $backupmountpoint
        fi
        backup=$(mount | grep $backupmountpoint)
        if test "empty$backup" == "empty"
        then
            echo "Unable to mount $backupmountpoint! Aborting..."
            sleep 3
            return 1
        fi
        touch $checkfile
        echo "Backing up $userhome/\..*"
        rsync -avz -f "+ /.**" -f "- /**" --delete $userhome/ $backupmountpoint/$backupdir/
        date > $backupmountpoint/$backupdir/last_backup_timestamp.txt
        clear
        echo "Starting general backup"
        sudo $userhome/.scripts/backup_local.sh misconly
    fi
}

backup
