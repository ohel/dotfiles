#!/usr/bin/bash
# A generic echoing backup script to rsync something to or from a remote location.
# There are four mandatory parameters and the rest are optional rsync excludes.
# The parameters are:
# $1: mode (normal, dry, reverse, reversedry)
# $2: localdir (the directory to back up)
# $3: server (SSH)
# $4: target (directory in server, usually backups/$localdir)
# The mode parameter may include:
#   * nowait (e.g. normalnowait) to skip the countdown
#   * git (e.g. reversegit) to include git directories
# By default git working directories are skipped when syncing from a remote location.

countdown=3 # Wait this many seconds before actually starting the operation to prevent accidents.

[ "$#" -lt 4 ] && echo "Required parameters missing." && exit 1

mode=$1
localdir=$2
server=$3
target=$4
shift; shift; shift; shift
excludelist=("$@")

excludeparams=""
for excludeitem in ${excludelist[@]}
do
    excludeparams="$excludeparams --exclude=$excludeitem"
    echo "Excluding: $excludeitem"
done

use_normal_mode="" && [ "$(echo $mode | grep normal)" ] && use_normal_mode=yes
use_reverse_mode="" && [ "$(echo $mode | grep reverse)" ] && use_reverse_mode=yes
use_dryrun_mode="" && [ "$(echo $mode | grep dry)" ] && use_dryrun_mode=yes
[ ! "$use_reverse_mode" ] && [ "$use_dryrun_mode" ] && use_normal_mode=yes
[ "$(echo $mode | grep nowait)" ] && countdown=0

if [ "$use_reverse_mode" ] && [ ! "$(echo $mode | grep git)" ]
then
    git_dirs=$(find $localdir -type d -name .git | sed "s/\/\.git\$//" | sed "s/^\.\///")
    for excludeitem in ${git_dirs[@]}
    do
        excludeparams="$excludeparams --exclude=$excludeitem"
        echo "Skipping git working dir: $excludeitem"
    done
fi

echo

rsync_options="-avzu --delete"
if [ "$use_normal_mode" ] && [ ! "$use_dryrun_mode" ]
then
    echo "Backup \"$localdir\" *TO* remote \"$target\" in $countdown seconds."
    sleep $countdown
    rsync $rsync_options $excludeparams $localdir $server:$target
elif [ "$use_normal_mode" ] && [ "$use_dryrun_mode" ]
then
    echo "Dry run backup \"$localdir\" *TO* remote \"$target\"."
    rsync -n $rsync_options $excludeparams $localdir $server:$target
elif [ "$use_reverse_mode" ] && [ ! "$use_dryrun_mode" ]
then
    echo "Synchronize \"$target\" *FROM* remote to local \"$localdir\" in $countdown seconds."
    sleep $countdown
    rsync $rsync_options $excludeparams $server:$target/ $localdir
elif [ "$use_reverse_mode" ] && [ "$use_dryrun_mode" ]
then
    echo "Dry run synchronize \"$target\" *FROM* remote to local \"$localdir\"."
    rsync -n $rsync_options $excludeparams $server:$target/ $localdir
else
    echo "Unknown mode parameter: $mode"
    exit 1
fi
