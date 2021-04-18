#!/bin/sh
# Check for unnecessary keyword and use configs on a Gentoo system.
# Just to keep things clean every now and then. Check out the output visually.

# Using "equery m" packages with and without version numbers are both fine.
grep -v "^#" /etc/portage/package.accept_keywords | grep -v "^$" | cut -f 1 -d ' ' | xargs -I {} equery m "{}"

# Using "equery l" we have to use packages without version numbers.
grep -v "^#" /etc/portage/package.use | grep -v "^$" | cut -f 1 -d ' ' | grep -v "^>" | xargs -I {} equery l {}
grep -v "^#" /etc/portage/package.use | grep -v "^$" | cut -f 1 -d ' ' | grep "^>" | cut -f 2 -d '=' | sed "s/-[0-9\.r-]*$//" | xargs -I {} equery l {}
