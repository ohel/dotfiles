#!/bin/bash
# Search stuff using rg or ag, then open filenames containing keywords from the search results.

rg_exe=$(which rg 2>/dev/null)
ag_exe=$(which ag 2>/dev/null)

! [ "$rg_exe$ag_exe" ] && echo "Neither rg or ag was found." && exit 1
[ "$#" -eq 0 ] && exit 1

rg $1 2>/dev/null || ag $1

echo -n "grep+edit: "
read -a words
greps=""
for word in "${words[@]}"
do
    greps="$greps | grep -i $word"
done

if [ "$rg_exe" ]
then
    cmd="rg -l --no-heading --with-filename --color never --column $1 . $greps | xargs gvim -p"
else
    cmd="ag -l --nogroup --nocolor --column $1 . $greps | xargs gvim -p"
fi

eval $(echo $cmd)
