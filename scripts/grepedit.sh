#!/bin/bash
# Search stuff using rg or ag, then open filenames containing keywords from the search results.

rg_exe=$(which rg 2>/dev/null)
ag_exe=$(which ag 2>/dev/null)

if test "X$rg_exe$ag_exe" = "X"
then
    echo "Neither rg or ag was found."
    exit
fi

if [ "$#" -eq 0 ]
then
    exit
fi

rg $1 2>/dev/null || ag $1

echo -n "grep+edit: "
read -a words
greps=""
for word in "${words[@]}"
do
  greps="$greps | grep -i $word"
done

if test "X$rg_exe" = "X"
then
    cmd="ag -l --nogroup --nocolor --column $1 . $greps | xargs gvim -p"
else
    cmd="rg -l --no-heading --with-filename --color never --column $1 . $greps | xargs gvim -p"
fi

eval $(echo $cmd)
