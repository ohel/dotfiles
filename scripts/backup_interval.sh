#!/bin/bash
# Backup user home directories and call system backup script
# depending on how long it is since last backup.
# The backup schedule timestamp checkfile is called backup_interval_checkfile,
# and for root script user it is read from /opt, for normal users from ~/.config/.
# Rsync excludes are read from ~/.config/backup_exclude.

backup() {
    scriptsdir=${1:-$HOME}
    backupmountpoint=/mnt/raidstorage
    backupdir=backups/misc/home_dirs/

    if ! [ -e $backupmountpoint ]
        then return
    fi

    if test "$(whoami)" == "root"
    then
        checkfile=/opt/backup_interval_checkfile
    else
        checkfile=~/.config/backup_interval_checkfile
    fi

    if ! [ -e $checkfile ]
        then touch $checkfile
    fi
    lastsyncmisc=$(expr $(date +%s) - $(stat -c %Z $checkfile))

    sync=0
    # 302400 seconds = 84 hours, or 3½ days.
    if [ $lastsyncmisc -gt 302400 ]
        then sync=1
    fi

    if [ $sync -eq 1 ]
    then
        backup=$(mount | grep $backupmountpoint)
        if test "empty$backup" == "empty"
        then
            echo "Mounting $backupmountpoint..."
            sudo mount $backupmountpoint
        fi
        backup=$(mount | grep $backupmountpoint)
        if test "empty$backup" == "empty"
        then
            echo "Unable to mount $backupmountpoint! Aborting backup."
            sleep 3
            return 1
        fi
        touch $checkfile

        if test "$(whoami)" == "root"
        then
            users=$(ls -1 /home)
        else
            users=$(whoami)
        fi

        for user in ${users[@]}
        do
            userbackupdir=$backupmountpoint/$backupdir/$user

            excludes=/home/$user/.config/backup_exclude
            if [ -e $excludes ]
            then
                excludes="--exclude-from=$excludes"
            else
                excludes=""
            fi

            echo "Backing up $user's home directory..."
            rsync -a $excludes --delete /home/$user/ $userbackupdir/
            date > $userbackupdir/last_backup_timestamp.txt
            chown $user:$user $userbackupdir $userbackupdir/last_backup_timestamp.txt
        done

        clear
        echo "Starting general backup."
        sudo $scriptsdir/backup_local.sh misconly
    fi
}

backup $(dirname "$(readlink -f "$0")")
