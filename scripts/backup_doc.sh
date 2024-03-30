#!/usr/bin/sh
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

[ "$#" -lt 2 ] && echo "Required parameters missing." && exit 1

server=$1
mode=$2
doc=${3:-$2}
[ "$#" -lt 3 ] && mode="normal"

docpath=$(readlink -m $doc | cut -c $(echo $(echo $localdir | wc -c)+1 | bc )-)

if [ "$mode" = "normal" ]
then
    ! [ -e "$localdir/$docpath" ] && echo "Error: file not found under $localdir." && exit 1
    rsync -avzu $localdir/$docpath $server:$remotedir/$docpath
elif [ "$mode" = "normaldry" ]
then
    rsync -avzun $localdir/$docpath $server:$remotedir/$docpath
elif [ "$mode" = "reverse" ]
then
    rsync -avzu $server:$remotedir/$docpath $localdir/$docpath
elif [ "$mode" = "reversedry" ]
then
    rsync -avzun $server:$remotedir/$docpath $localdir/$docpath
else
    echo "Unknown backup mode: $mode. Aborted."
fi
