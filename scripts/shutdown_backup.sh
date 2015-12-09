#/bin/bash
userhome=/home/panther
backupmountpoint=/mnt/raidstorage
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
        exit 1
    fi
    touch $checkfile
    echo "Backing up $userhome/\..*"
    rsync -avz -f "+ /.**" -f "- /**" --delete $userhome/ $backupmountpoint/backups/home/$(basename $userhome)/
    date > $backupmountpoint/backups/misc_home/$(basename $userhome)/last_backup_timestamp.txt
    clear
    echo "Starting general backup"
    sudo $userhome/.scripts/backup.sh misconly
fi
echo "Shutting down..."
sudo shutdown -hP now
