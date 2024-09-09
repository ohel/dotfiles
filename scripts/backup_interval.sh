#!/usr/bin/sh
# Backup user home directories and call system backup script
# depending on how long it is since last backup.
# The backup schedule timestamp checkfile is called backup_interval_checkfile,
# and for root script user it is read from /opt, for normal users from ~/.config/.
# Rsync excludes are read from ~/.config/backup_exclude.

backup() {
    scriptsdir=${1:-$HOME}
    backupmountpoint=/mnt/raidstorage
    backupdir=backups/misc/home_dirs

    [ ! -e $backupmountpoint ] && return

    if [ "$(whoami)" = "root" ]
    then
        checkfile=/opt/backup_interval_checkfile
    else
        checkfile=~/.config/backup_interval_checkfile
    fi

    [ ! -e $checkfile ] && touch $checkfile
    lastsyncmisc=$(expr $(date +%s) - $(stat -c %Z $checkfile))

    sync=0
    # 302400 seconds = 84 hours, or 3½ days.
    [ $lastsyncmisc -gt 302400 ] && sync=1

    if [ $sync -eq 1 ]
    then
        backup=$(mount | grep $backupmountpoint)
        if [ ! "$backup" ]
        then
            echo "Mounting $backupmountpoint..."
            sudo mount $backupmountpoint
        fi
        backup=$(mount | grep $backupmountpoint)
        if [ ! "$backup" ]
        then
            echo "Unable to mount $backupmountpoint! Aborting backup."
            sleep 3
            return 1
        fi
        touch $checkfile

        if test "$(whoami)" = "root"
        then
            dircmd="find /home/ -maxdepth 1 -mindepth 1 -type d"
        else
            dircmd="ls -d /home/$(whoami)"
        fi

        for user in $($dircmd | sed "s/.*\///g")
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
            echo
        done

        echo "Starting general backup."
        sudo $scriptsdir/backup_local.sh misconly
    fi
}

backup $(dirname "$(readlink -f "$0")")
