#!/usr/bin/sh
# Backup user home directories and call system backup script
# depending on how long it is since last backup.
# The backup schedule timestamp checkfile is called backup_interval_checkfile,
# and for root script user it is read from /opt, for normal users from ~/.config/.
# Rsync excludes are read from ~/.config/backup_exclude.

backup() {
    scriptsdir=${1:-$HOME}
    backupdir=/mnt/local-backup/home_dirs

    [ ! -e $backupdir ] && return

    whoami=$(whoami)
    if [ "$whoami" = "root" ]
    then
        checkfile=/opt/backup_interval_checkfile
        dircmd="find /home/ -maxdepth 1 -mindepth 1 -type d"
    else
        checkfile=~/.config/backup_interval_checkfile
        dircmd="ls -d /home/$whoami"
    fi

    [ ! -e $checkfile ] && touch $checkfile
    last_backup=$(expr $(date +%s) - $(stat -c %Z $checkfile))

    should_backup=""
    # 302400 seconds = 84 hours, or 3½ days.
    [ $last_backup -gt 302400 ] && should_backup=yes

    if [ "$should_backup" ]
    then
        touch $checkfile

        for user in $($dircmd | sed "s/.*\///g")
        do
            userbackupdir=$backupdir/$user

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
