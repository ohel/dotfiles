#!/bin/bash
# Search stuff using the silver searcher (ag), then open filenames containing keywords from the search results.
ag $1
echo -n "grep+gvim: "
read -a words
greps=""
for word in "${words[@]}"
do
  greps="$greps | grep -i $word"
done
cmd="ag -l --nogroup --nocolor --column $1 . $greps | xargs gvim -p"
eval $(echo $cmd)
