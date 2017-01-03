#!/bin/bash
# A generic echoing backup script to rsync something to a remote location.
# There are three mandatory parameters, the rest are optional rsync excludes.

remotedir="~/backups"

if [ "$#" -lt 3 ]; then
    echo "Required parameters missing."
    exit
fi

sourcedir=$1
server=$2
target=$3
shift; shift; shift
excludelist=("$@")

excludeparams=""
for excludeitem in ${excludelist[@]}
do
    excludeparams="$excludeparams --exclude=$excludeitem"
done

echo "Backing up $target..."
rsync -avzu --delete $excludeparams $sourcedir $server:$remotedir/$target

