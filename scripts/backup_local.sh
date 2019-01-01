#!/bin/bash
# Backup script for full system, home, and misc backup. Backup process is logged.

# Backup drives.
mountables=(
    "/mnt/raidstorage"
    "/mnt/backupmedia"
)

# Source directories for misc backup.
backup_source_dirs=(
    "/home/panther/docs"
    "/home/panther/docs"
    "/home/panther/media/pictures"
    "/home/panther/media/pictures"
    "/mnt/raidstorage/media/audio"
    "/mnt/raidstorage/media/disc_images"
    "/mnt/raidstorage/media/video"
    "/mnt/raidstorage/backups/misc"
)

# Destination directories for misc backup. Should correspond to source directories.
backup_dest_dirs=(
    "${mountables[0]}/backups/docs"
    "${mountables[1]}/backups/docs"
    "${mountables[0]}/backups/media/pictures"
    "${mountables[1]}/backups/media/pictures"
    "${mountables[1]}/backups/media/audio"
    "${mountables[1]}/backups/media/disc_images"
    "${mountables[1]}/backups/media/video"
    "${mountables[1]}/backups/misc"
)

# Locations where to put full system backups. The first one is echoed with deletes to the other.
systembackupdir="${mountables[0]}/backups/system/"
systembackupdir2="${mountables[1]}/backups/system/"

# Escape asterisks, otherwise shell expansion is made.
systembackupexcludelist=(
    "/dev/shm/\*"
    "/home/\*"
    "/mnt/\*/\*"
    "/opt/games/\*"
    "/opt/virtualmachines/\*"
    "/proc/\*"
    "/sys/\*"
    "/tmp/\*"
    "/usr/portage/distfiles/\*"
    "/var/tmp/\*"
)

# Home backup will backup /home/* excluding these.
homebackupexcludelist=(
    "/home/panther/downloads/\*"
    "/home/panther/docs/\*"
    "/home/panther/media/\*"
)

logdir="/var/log/backup/"

if [ "$(echo $HOME)" != "/root" ]
then
    echo You must be root to maintain permissions!
    exit 1
fi

echo "Mounting partitions if not already mounted..."
for mountable in ${mountables[@]}
do
    [ ! "$(cat /etc/mtab | grep $mountable)" ] && mount $mountable 2>/dev/null &
done
wait
for mountable in ${mountables[@]}
do
    [ ! "$(cat /etc/mtab | grep $mountable)" ] && echo "Mounting $mountable failed." && sleep 1
done

echo "Starting backup in three seconds..."
sleep 1
echo "Starting backup in two seconds..."
sleep 1
echo "Starting backup in one second..."
sleep 1

parallel=0
# If pigz is found, use threaded compression.
[ $(which pigz 2>/dev/null) ] && parallel=1

datestring=$(date +%F)
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

[ "$1" == "misconly" ] && exit 0

if [ ! -e $systembackupdir ]
then
    echo "System backup directory $systembackupdir does not exist."
    echo "Aborting system backup..."
    exit 1
fi

if [ "$1" != "synconly" ]
then
    echo
    echo "*******************************************************************************"
    echo "Beginning system backup..."
    echo "To restore: tar -C /[home] -xvpzf archive.tgz"

    mbrbackupfile="$systembackupdir/$HOSTNAME-MBR-backup-$datestring.bak"
    systembackupfile="$systembackupdir/$HOSTNAME-system-backup-$datestring.tgz"
    homebackupfile="$systembackupdir/$HOSTNAME-home-backup-$datestring.tgz"

    dd if=/dev/sda of=$mbrbackupfile bs=512 count=1
    echo
    echo "MBR backup created."

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
        tar -C / --index-file /dev/shm/backup.out $excludelist -cvpf - ./ | pigz -c > $systembackupfile
    else
        tar -C / --index-file /dev/shm/backup.out $excludelist -cvpzf $systembackupfile ./
    fi
    echo "Moving log file to $logdir..."
    mv /dev/shm/backup.out $logdir

    excludelist=""
    for excludeitem in ${homebackupexcludelist[@]}
    do
        # Prefix every item with . so that we may use relative paths with tar.
        excludelist="$excludelist --exclude=.$excludeitem"
    done
    excludelist=$(echo $excludelist | sed "s/\\\\\*/*/g")
    echo
    echo "*******************************************************************************"
    echo "Backing up home directories..."
    if [ $parallel -eq 1 ]
    then
        tar -C / --one-file-system -cpf - $excludelist ./home | pigz -c > $homebackupfile
    else
        tar -C / --one-file-system -cpzf $homebackupfile $excludelist ./home
    fi
fi

if [ "$systembackupdir2" ]
then
    echo
    echo "*******************************************************************************"
    echo "Synchronizing $systembackupdir with $systembackupdir2..."
    if [ ! -e $systembackupdir2 ]
    then
        echo "Destination directory $systembackupdir2 does not exist, skipping..."
    else
        rsync -avh --progress --delete $systembackupdir $systembackupdir2
    fi
fi

echo
echo "*******************************************************************************"
echo "Backup complete. Remember to backup virtual machines separately."
echo
read
