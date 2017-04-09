#!/bin/bash
# A generic script to rsync one document file to or from a remote location.
# Document location must correspond to a remote backup location.
# There are three parameters, second one is optional:
# $1: server (SSH)
# $2: mode (normal (default if not given), normaldry, reverse, reversedry)
# $3: the file to synchronize
#
# This is useful with aliases if one often synchronizes just one file.
# alias srv_put_file='~/.scripts/backup_doc.sh srv normal'
# alias srv_get_file='~/.scripts/backup_doc.sh srv reverse'
# And one may use it like: srv_put_file ~/docs/path/to/file

localdir=$(readlink -m $HOME/docs)
remotedir="~/backups/docs"

if [ "$#" -lt 2 ]; then
    echo "Required parameters missing."
    exit
fi
server=$1
mode=$2
doc=${3:-$2}
if [ "$#" -lt 3 ]; then
    mode="normal"
fi

docpath=$(readlink -m $doc | cut -c $(echo $(echo $localdir | wc -c)+1 | bc )-)

if test "$mode" == "normal"
then
    if [ ! -e "$localdir/$docpath" ]; then
        echo "Error: file not found under $localdir."
        exit
    fi
    rsync -avzu $localdir/$docpath $server:$remotedir/$docpath
elif test "$mode" == "normaldry"
then
    rsync -avzun $localdir/$docpath $server:$remotedir/$docpath
elif test "$mode" == "reverse"
then
    rsync -avzu $server:$remotedir/$docpath $localdir/$docpath
elif test "$mode" == "reversedry"
then
    rsync -avzun $server:$remotedir/$docpath $localdir/$docpath
else
    echo "Unknown backup mode: $mode. Aborted."
fi