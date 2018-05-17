#!/bin/bash
# Search stuff using find, then open specified search result if more than one is found.

editor=gvim

if [ "$#" -eq 0 ]
then
    exit
fi

results=($(find ./ | grep -i $1))

if [ ${#results[@]} -eq 0 ]
then
  echo "No matches."
  exit
elif [ ${#results[@]} -eq 1 ]
then
  $editor ${results[0]}
  exit
fi

order=1
for result in ${results[@]}
do
  echo $order: $result
  order=`expr $order + 1`
done

echo -n "Edit the one with order number: "
read -a index

index=$(echo $index | tr -c -d [:digit:])
if test "X$index" = "X"
then
  exit
fi
index=`expr $index - 1`

$editor ${results[$index]}
