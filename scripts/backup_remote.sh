#!/bin/bash
# A generic echoing backup script to rsync something to or from a remote location.
# There are four mandatory parameters, the rest are optional rsync excludes.
# The parameters are:
# $1: mode (normal, normaldry, reverse, reversedry)
# $2: localdir (the directory to back up)
# $3: server (SSH)
# $4: target (directory in server under $remotedir)
# The mode parameter may be postfixed with nowait (e.g. normalnowait) to skip the countdown.

remotedir="~/backups" # The target directory should exist in this directory on the server.
countdown=3 # Wait this many seconds before actually starting the operation to prevent accidents.

echo

if [ "$#" -lt 4 ]; then
    echo "Required parameters missing."
    exit
fi

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

if test "X$(echo $mode | grep nowait\$)" != "X"
then
    countdown=0
    mode=$(echo $mode | sed s/nowait\$//)
fi

if test "X$(echo $mode | grep reverse)" != "X"
then
    git_dirs=$(find $localdir -type d -name .git | sed "s/\/\.git\$//" | sed "s/^\.\///")
    for excludeitem in ${git_dirs[@]}
    do
        excludeparams="$excludeparams --exclude=$excludeitem"
        echo "Skipping git working dir: $excludeitem"
    done
fi

echo

if test "$mode" == "normal"
then
    echo "Starting \"$target\" backup *TO* remote in $countdown seconds."
    sleep $countdown
    rsync -avzu --delete $excludeparams $localdir $server:$remotedir/$target
elif test "$mode" == "normaldry"
then
    echo "Dry run backup \"$target\" *TO* remote."
    rsync -avzun --delete $excludeparams $localdir $server:$remotedir/$target
elif test "$mode" == "reverse"
then
    echo "Starting \"$target\" synchronizing *FROM* remote in $countdown seconds."
    sleep $countdown
    rsync -avzu --delete $excludeparams $server:$remotedir/$target/ $localdir
elif test "$mode" == "reversedry"
then
    echo "Dry run synchronize \"$target\" *FROM* remote."
    rsync -avzun --delete $excludeparams $server:$remotedir/$target/ $localdir
else
    echo "Unknown backup mode: $mode. Aborted."
fi
