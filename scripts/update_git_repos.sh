#!/bin/bash
# Updates all git repositories inside current directory.
# Useful e.g. when keeping local bare repository backup mirrors of remote git repositories.

cwd=$(pwd)
git_dirs=$(find ./ -type d -name \*.git | sed "s/\/\.git\$//" | sed "s/^\.\///")
for dir in ${git_dirs[@]}
do
    cd $cwd/$dir
    if [ "$1" == "status" ]
    then
        pwd
        git status 2>/dev/null
    elif [ "$1" == "pull" ]
    then
        echo Pulling repository: $dir
        git pull --ff-only -q &
    else
        echo Fetching repository: $dir
        git fetch --all -q -p &
    fi
done
wait
cd $cwd
