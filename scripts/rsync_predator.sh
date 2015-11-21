#!/bin/sh

put_items=(
    "archive"
    "ebooks"
    "misc"
    "sheetmusic"
)

get_items=(
)

put_items_no_recursive=(
)

get_items_no_recursive=(
)

export RSYNC_PASSWORD='panther'
user="panther"
if [ "$#" = 0 ]; then
    remoteaddr=$(wget 10.0.0.1 -q -O - | grep setDHCPTable | grep -o "predator.*,.*,.*2F:14" | cut -f 2 -d "," | tr -d "'")
    if test "X$remoteaddr" == "X"
    then
        echo "IP address not found or given."
        exit
    fi
else
    remoteaddr="$1"
fi
localdocs="/home/panther/docs"
remotedocs="docs"


for syncitem in "${put_items[@]}"
do
	# first, update remote but skip newer files
	rsync -avzuPL --delete --exclude=.* "$localdocs"/"$syncitem"/ "$user"@"$remoteaddr":"$remotedocs"/"$syncitem"/

done

for syncitem in "${get_items[@]}"
do
	# then, update local (-a implies -rlptgoD)
	rsync -av --exclude=.* "$user"@"$remoteaddr":"$remotedocs"/"$syncitem"/ "$localdocs"/"$syncitem"/
done

for syncitem in "${put_items_no_recursive[@]}"
do
	# first, update remote but skip newer files
	rsync -avzuPL --delete --exclude=.* "$localdocs"/"$syncitem"/* "$user"@"$remoteaddr":"$remotedocs"/"$syncitem"/
done

for syncitem in "${get_items_no_recursive[@]}"
do
	# then, update local
	rsync -lptgoDv --exclude=.* "$user"@"$remoteaddr":"$remotedocs"/"$syncitem"/* "$localdocs"/"$syncitem"/
done

echo ""
echo "Synchronization complete!"

# wait for keypress
read

