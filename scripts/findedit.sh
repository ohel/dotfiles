#!/usr/bin/sh
# List files using find, grepping "$1" from their names, then select a search result to edit.
# If just one result is found, it is opened automatically.

editor=$EDITOR
[ "$(which gedit 2>/dev/null)" ] && editor="gedit"
[ "$(which vim 2>/dev/null)" ] && editor="vim"
[ "$(which gvim 2>/dev/null)" ] && editor="gvim"

[ "$#" -eq 0 ] && echo "Give the search term as a parameter." && exit 1

results=$(find ./ | grep -i "$1")

if [ ! "$results" ]
then
    echo "No matches."
    exit 0
elif [ $(echo "$results" | wc -l) -eq 1 ]
then
    $editor "$results"
    exit 0
fi

count=$(echo "$results" | wc -l)

index=1
while [ $index -le $count ]
do
    echo $index: $(echo "$results" | head -n $index | tail -n 1) :$index
    index=$(expr $index + 1)
done

echo -n "Edit the one with order number: "
read selection

selection=$(echo $selection | tr -c -d [:digit:])
! [ "$selection" ] && exit 1

$editor "$(echo "$results" | head -n $selection | tail -n 1)"
