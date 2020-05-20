#!/bin/bash
# Given an input Markdown file, create a simple LaTeX file out of it.
# (Sub)titles are converted to (sub)sections, quotes are converted and unordered lists are itemized.
# If $2 = pdf, a PDF is made from the result LaTeX file.

[ ! "$1" ] && echo "Missing Markdown file argument." && exit 1

basename=$(basename -s .md "$1")
texfile="$basename.tex"

cat > "$texfile" << EOF
\def\doctitle{$basename}
\def\docdate{$(date +%d.%m.%Y)}

\RequirePackage{amsmath}
\RequirePackage[utf8]{inputenc}
\RequirePackage{lmodern}
\RequirePackage{ae}
\RequirePackage{textcomp}
\RequirePackage{float}
\RequirePackage{graphicx}
\documentclass[a4paper,12pt]{article}
\begin{document}
\begin{center}\section*{\doctitle\\\{\small\docdate}}\end{center}\vspace{1em}
\renewcommand{\baselinestretch}{1.5}\normalsize

EOF

cat "$1" >> "$texfile"

echo "" >> "$texfile"
echo "\end{document}" >> "$texfile"

sed -i "s/^# \(.*\)/\\\section{\1}/" "$texfile"
sed -i "s/^## \(.*\)/\\\subsection{\1}/" "$texfile"
sed -i "s/\"\([^\"]*\)\"/\`\`\1''/g" "$texfile"

lines=""
linenumbers=$(grep -n "^\* " "$texfile" | cut -f 1 -d ':')
for ln in ${linenumbers[@]}
do
    lines="$lines,$ln,"
done

added_lines=0
for ln in ${linenumbers[@]}
do
    if [ ! "$(echo $lines | grep ",$(expr $ln - 1),")" ]
    then
        sed -i "$(expr $ln + $added_lines) i \\\\\begin{itemize}" "$texfile"
        added_lines=$(expr $added_lines + 1)
    fi
    if [ ! "$(echo $lines | grep ",$(expr $ln + 1),")" ]
    then
        sed -i "$(expr $ln + $added_lines) a \\\\\end{itemize}" "$texfile"
        added_lines=$(expr $added_lines + 1)
    fi
done

sed -i "s/^\* /    \\\\\item /" "$texfile"

if [ "$2" = "pdf" ]
then
    pdflatex "$texfile"
    rm "$basename.aux"
    rm "$basename.log"
fi
