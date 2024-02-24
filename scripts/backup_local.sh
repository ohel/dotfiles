#!/bin/bash
# Backup script for full system, home, and misc backup. Backup process is logged.

# The backup_config should have these four variables (three of them bash arrays) defined:
#    mountables: Mount points needed in backup.
#    systembackupdir: Location where to put full system backups.
#    backup_source_dirs: Source directories for misc backup.
#    backup_dest_dirs: Destination directories for misc backup. Should correspond to source directories.
# Optionally also: systembackupexcludelist: Things to exclude from backup.
#
# Additionally, for home backups each user may have a ~/.config/backup_exclude file.
# It can define paths relative to that home directory for stuff that should be excluded.

backup_config=/opt/backup_config

[ ! -e $backup_config ] && echo "Error: missing backup config $backup_config" && exit 1
. /opt/backup_config
[ ! "$mountables" ] && echo "Error: missing definition for mountables" && exit 1
[ ! "$systembackupdir" ] && echo "Error: missing definition for systembackupdir" && exit 1
[ ! "$backup_source_dirs" ] && echo "Error: missing definition for backup_source_dirs" && exit 1
[ ! "$backup_dest_dirs" ] && echo "Error: missing definition for backup_dest_dirs" && exit 1

# Escape asterisks, otherwise shell expansion is made.
[ ! "$systembackupexcludelist" ] && systembackupexcludelist=(
    "/dev/shm/\*"
    "/home/\*"
    "/mnt/\*/\*"
    "/proc/\*"
    "/sys/\*"
    "/tmp/\*"
    "/var/tmp/\*"
)

logdir="/var/log/backup/"

do_misc_backup=1
do_system_backup=1
do_home_backup=1
wait_at_end=1
[ "$1" == "misconly" ] && do_system_backup=0 && do_home_backup=0 && wait_at_end=0

if [ "$(echo $HOME)" != "/root" ]
then
    echo You must be root to maintain permissions!
    exit 1
fi

echo "Mounting partitions if not already mounted..."
for mountable in ${mountables[@]}
do
    [ ! "$(grep $mountable /etc/mtab)" ] && mount $mountable 2>/dev/null &
done
wait
for mountable in ${mountables[@]}
do
    [ ! "$(grep $mountable /etc/mtab)" ] && echo "Mounting $mountable failed." && sleep 1
done

echo "Starting backup in three seconds..."
sleep 1
echo "Starting backup in two seconds..."
sleep 1
echo "Starting backup in one second..."
sleep 1

parallel=0
# If pigz is found, use threaded compression.
[ "$(which pigz 2>/dev/null)" ] && parallel=1

datestring=$(date +%F)

if [ "$do_system_backup" == 1 ]
then
    if [ ! -e $systembackupdir ]
    then
        echo "Backup directory $systembackupdir does not exist."
        echo "Aborting system backup..."
        exit 1
    fi

    echo
    echo "*******************************************************************************"
    echo "Beginning system backup..."
    echo "To restore: tar -C /[home] -xvpzf archive.tgz"

    systembackupfile="$systembackupdir/$HOSTNAME-system-backup-$datestring.tgz"

    excludelist=""
    for excludeitem in ${systembackupexcludelist[@]}
    do
        # Prefix every item with . so that we may use relative paths with tar.
        excludelist="$excludelist --exclude=.$excludeitem"
    done
    excludelist=$(echo $excludelist | sed "s/\\\\\*/*/g")

    echo
    echo "Creating system backup, see /dev/shm/backup.out for progress."
    if [ $parallel -eq 1 ]
    then
        tar -C / --warning=no-file-ignored --index-file /dev/shm/backup.out $excludelist -cvpf - ./ | pigz -c > $systembackupfile
    else
        tar -C / --warning=no-file-ignored --index-file /dev/shm/backup.out $excludelist -cvpzf $systembackupfile ./
    fi
    echo "Moving log file to $logdir..."
    mv /dev/shm/backup.out $logdir
fi

if [ "$do_home_backup" == 1 ]
then
    if [ ! -e $systembackupdir ]
    then
        echo "Backup directory $systembackupdir does not exist."
        echo "Aborting home backup..."
        exit 1
    fi

    echo
    echo "*******************************************************************************"
    echo "Backing up home directories..."
    homebackupfile="$systembackupdir/$HOSTNAME-home-backup-$datestring.tgz"

    excludelist=""
    for user in $(ls -d /home/* | sed "s/.*\///g")
    do
        excludesfile=/home/$user/.config/backup_exclude
        if [ -e $excludesfile ]
        then
            while read -r excludeitem
            do
                # If excluded item is a directory, include the empty directory.
                [ -d "/home/$user/$excludeitem" ] && excludeitem="$excludeitem/*"
                # Prefix every item with . so that relative paths may be used with tar.
                excludelist="$excludelist --exclude=./home/$user/$excludeitem"
            done < $excludesfile
        fi
    done

    if [ $parallel -eq 1 ]
    then
        tar -C / --warning=no-file-ignored --one-file-system -cpf - $excludelist ./home | pigz -c > $homebackupfile
    else
        tar -C / --warning=no-file-ignored --one-file-system -cpzf $homebackupfile $excludelist ./home
    fi
fi

if [ "$do_misc_backup" == 1 ]
then
    echo
    echo "*******************************************************************************"
    echo "Synchronising misc backup directories..."
    num_of_misc=${#backup_source_dirs[@]}
    if [ $num_of_misc -ne ${#backup_dest_dirs[@]} ]
    then
        echo "The number of misc backup source and destination directories does not match!"
        echo "Aborting..."
        exit 1
    fi
    index=0
    while [ $index -lt $num_of_misc ]
    do
        sourcedir="${backup_source_dirs[$index]}/"
        destdir="${backup_dest_dirs[$index]}/"
        if [ ! -e $destdir ]
        then
            echo "Destination directory $destdir does not exist, skipping..."
        else
            echo
            echo "*******************************************************************************"
            echo "Synchronising $sourcedir with $destdir..."
            rsync -ah --progress --delete --log-file "$logdir""$datestring""_rsync_""$index"".log" $sourcedir $destdir
        fi
        index=$(expr $index + 1)
    done
fi

echo
echo "*******************************************************************************"
echo "Backup complete. Backup virtual machines separately."
echo
[ "$wait_at_end" == 1 ] && read
