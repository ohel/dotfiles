#!/usr/bin/sh
# Check for unnecessary keyword and use configs on a Gentoo system.
# Just to keep things clean every now and then.

# Using "equery m" packages with and without version numbers are both fine.
echo Checking keywords...
grep -v "^#" /etc/portage/package.accept_keywords | grep -v "\*\*" | grep -v "^$" | cut -f 1 -d ' ' | xargs -I {} sh -c "equery -NC m {} | grep -B 10 [^~]amd64 | head -1" equerycmd
echo Done checking keywords.

# Using "equery l" we have to search without version numbers.
echo Checking use flags...

if [ -d /etc/portage/package.use ]
then
    cd /etc/portage/package.use
    for usefile in $(ls -1)
    do
        # Packages without version.
        grep -v "\(^#\)\|\(^$\)" $usefile | cut -f 1 -d ' ' | grep -v "\(^>\)\|\(^=\)\|\(^\*\)" | xargs -I {} sh -c "equery -NC l {} | grep \"No installed\"" equerycmd
        # Packages with version.
        grep -v "\(^#\)\|\(^$\)" $usefile | cut -f 1 -d ' ' | grep "\(^>\)\|\(^=\)" | cut -f 2 -d '=' | sed "s/-[0-9\.r-]*$//" | xargs -I {} sh -c "equery -NC l {} | grep \"No installed\"" equerycmd
    done
else
    # Packages without version.
    grep -v "\(^#\)\|\(^$\)" /etc/portage/package.use | cut -f 1 -d ' ' | grep -v "\(^>\)\|\(^=\)\|\(^\*\)" | xargs -I {} sh -c "equery -NC l {} | grep \"No installed\"" equerycmd
    # Packages with version.
    grep -v "\(^#\)\|\(^$\)" /etc/portage/package.use | cut -f 1 -d ' ' | grep "\(^>\)\|\(^=\)" | cut -f 2 -d '=' | sed "s/-[0-9\.r-]*$//" | xargs -I {} sh -c "equery -NC l {} | grep \"No installed\"" equerycmd
fi
echo Done checking use flags.
