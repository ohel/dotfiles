#!/bin/sh
# Check for unnecessary keyword and use configs on a Gentoo system.
# Just to keep things clean every now and then.

# Using "equery m" packages with and without version numbers are both fine.
echo Checking keywords...
grep -v "^#" /etc/portage/package.accept_keywords | grep -v "\*\*" | grep -v "^$" | cut -f 1 -d ' ' | xargs -I {} sh -c "equery -NC m {} | grep -B 10 [^~]amd64 | head -1" equerycmd
echo Done checking keywords.

# Using "equery l" we have to use packages without version numbers.
echo Checking use flags...
grep -v "^#" /etc/portage/package.use | grep -v "^$" | cut -f 1 -d ' ' | grep -v "^>" | grep -v "^=" | grep -v "^\*" | xargs -I {} sh -c "equery -NC l {} | grep \"No installed\"" equerycmd
grep -v "^#" /etc/portage/package.use | grep -v "^$" | cut -f 1 -d ' ' | grep "^>\|=" | cut -f 2 -d '=' | sed "s/-[0-9\.r-]*$//" | xargs -I {} sh -c "equery -NC l {} | grep \"No installed\"" equerycmd
echo Done checking use flags.
