#!/bin/bash
# Given an input Markdown file, create a simple LaTeX file out of it using these rules:
# * Hash-prefixed (sub(sub))titles are converted to (sub(sub))sections.
# * Double quotes are converted to LaTeX style.
# * Unordered lists (by asterisks) are itemized.
# * Ordered lists are enumerated.
# * <hr> elements are converted to pagebreaks.
# * **bold** text is converted to \textbf{bold}.
# * _emphasis_ is converted to \emph{emphasis}.
# The conversion is not perfect by a long shot, but should work for simple short documents quite well.
# If $2 = pdf, a PDF is made from the result LaTeX file and opened with xdg-open.

[ ! "$1" ] && echo "Missing Markdown file argument." && exit 1

basename=$(basename -s .md "$1")
texfile="$basename.tex"
doctitle=$(echo $basename | tr [:lower:] [:upper:] | tr "_" " ")

cat > "$texfile" << EOF
\def\doctitle{$doctitle}
\def\docdate{$(date +%d.%m.%Y)}

\RequirePackage{amsmath}
\RequirePackage[utf8]{inputenc}
\RequirePackage{lmodern}
\RequirePackage{ae}
\RequirePackage{textcomp}
\RequirePackage{float}
\RequirePackage{graphicx}
\documentclass[a4paper,12pt]{article}
\setlength{\parindent}{0pt}
\parskip = \baselineskip
\begin{document}
\begin{center}\section*{\doctitle\\\{\small\docdate}}\end{center}\vspace{1em}
\renewcommand{\baselinestretch}{1.5}\normalsize

EOF

cat "$1" >> "$texfile"

echo "" >> "$texfile"
echo "\end{document}" >> "$texfile"

sed -i "s/^# \(.*\)/\\\section{\1}/" "$texfile"
sed -i "s/^## \(.*\)/\\\subsection{\1}/" "$texfile"
sed -i "s/^### \(.*\)/\\\subsubsection{\1}/" "$texfile"
sed -i "s/\"\([^\"]*\)\"/\`\`\1''/g" "$texfile"

# Convert unordered lists.
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

# Convert ordered lists.
lines=""
linenumbers=$(grep -n "^[1-9]\. " "$texfile" | cut -f 1 -d ':')
for ln in ${linenumbers[@]}
do
    lines="$lines,$ln,"
done

added_lines=0
for ln in ${linenumbers[@]}
do
    if [ ! "$(echo $lines | grep ",$(expr $ln - 1),")" ]
    then
        sed -i "$(expr $ln + $added_lines) i \\\\\begin{enumerate}" "$texfile"
        added_lines=$(expr $added_lines + 1)
    fi
    if [ ! "$(echo $lines | grep ",$(expr $ln + 1),")" ]
    then
        sed -i "$(expr $ln + $added_lines) a \\\\\end{enumerate}" "$texfile"
        added_lines=$(expr $added_lines + 1)
    fi
done
sed -i "s/^\([1-9]\.\) /    \\\\\item /" "$texfile"

sed -i "s/<hr>/\\\pagebreak \[4\]/" "$texfile"
sed -i "s/\*\*\([^*]*\)\*\*/\\\textbf\{\1\}/g" "$texfile"
sed -i "s/_\([^_]*\)_/\\\emph\{\1\}/g" "$texfile"

if [ "$2" = "pdf" ]
then
    pdflatex "$texfile"
    rm "$basename.aux"
    rm "$basename.log"
    which xdg-open 2>&1 >/dev/null && xdg-open "$basename.pdf"
fi
