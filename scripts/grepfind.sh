#!/bin/bash
# Search stuff using find, then open specified search result if more than one is found.

editor=gvim

if [ "$#" -eq 0 ]
then
    echo "Give the search term as a parameter."
    exit 1
fi

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
    order=`expr $order + 1`
done

echo -n "Edit the one with order number: "
read -a index

index=$(echo $index | tr -c -d [:digit:])
if test "X$index" = "X"
then
    exit 1
fi
index=`expr $index - 1`

$editor ${results[$index]}
