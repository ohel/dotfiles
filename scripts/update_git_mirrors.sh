#!/bin/bash
# Updates all git repositories inside current directory.
# Useful e.g. when keeping local bare repository backup mirrors of remote git repositories.

for dir in $(ls -1d *.git)
do
    echo Updating repository: $dir
    cd $dir
    git remote update -p &
    cd ..
done
wait
