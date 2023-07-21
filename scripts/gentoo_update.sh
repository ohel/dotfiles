#!/bin/sh
# Update a Gentoo system: update overlays, update world, rebuild stuff if necessary, clean distfiles.

if test "X$1" != "Xnosync"
then
    which layman >/dev/null 2>&1 && sudo layman -s ALL
    sudo emaint sync --auto
fi
emerge -DNtuvp world
echo "Press return to start merging."
read tmp
sudo emerge -DNju --keep-going --quiet-build world
sudo etc-update
echo Emerging @preserved-rebuild...
sudo emerge @preserved-rebuild -j --keep-going --quiet-build
sudo eclean -d distfiles
sudo emerge --depclean -a
echo
echo "Run if necessary:"
echo "sudo perl-cleaner --reallyall"
echo
echo "********************"
echo "* Update complete! *"
echo "********************"
echo
read tmp
