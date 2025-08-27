#!/usr/bin/bash
# Search stuff using rg/ag/grep "$1", then from the search results open filenames matching search terms.

editor=$EDITOR
[ "$(which gedit 2>/dev/null)" ] && editor="gedit"
[ "$(which vim 2>/dev/null)" ] && editor="vim"
[ "$(which gvim 2>/dev/null)" ] && editor="gvim -p"

rg_exe=$(which rg 2>/dev/null)
ag_exe=$(which ag 2>/dev/null)

[ "$#" -eq 0 ] && exit 1

grep_ignore=""
[ -e $HOME/.config/grep_ignore ] && grep_ignore="--ignore-file $HOME/.config/grep_ignore"
rg -S -uu $grep_ignore "$1" 2>/dev/null || ag "$1" 2>/dev/null || grep -n -R -i --color=auto "$1" 2>/dev/null

echo Enter search terms for filenames. All terms must match the name to edit a file.
printf "Search for: "
read -a words
greps=""
for word in "${words[@]}"
do
    greps="$greps | grep -i $word"
done

cmd="grep -l -R \"$1\" . $greps | xargs $editor"
[ "$ag_exe" ] && cmd="ag -l --nogroup --nocolor --column \"$1\" . $greps | xargs $editor"
[ "$rg_exe" ] && cmd="rg -S -uu $grep_ignore -l --no-heading --with-filename --color never --column \"$1\" . $greps | xargs $editor"

eval $(echo $cmd)
