#!/bin/bash
# List files using find grepping $1 from their names, then select a search result to edit.
# If just one result is found, it is opened automatically.

[ "$(which gedit 2>/dev/null)" ] && editor=gedit
[ "$(which vim 2>/dev/null)" ] && editor=vim
[ "$(which gvim 2>/dev/null)" ] && editor=gvim

[ "$#" -eq 0 ] && echo "Give the search term as a parameter." && exit 1

results=($(find ./ | grep -i $1))

if [ ${#results[@]} -eq 0 ]
then
    echo "No matches."
    exit 0
elif [ ${#results[@]} -eq 1 ]
then
    $editor ${results[0]}
    exit 0
fi

order=1
for result in ${results[@]}
do
    echo $order: $result :$order
    order=$(expr $order + 1)
done

echo -n "Edit the one with order number: "
read -a index

index=$(echo $index | tr -c -d [:digit:])
! [ "$index" ] && exit 1
index=$(expr $index - 1)

$editor ${results[$index]}
