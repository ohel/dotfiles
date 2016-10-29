#/bin/sh
# Update a Gentoo system: update overlays, update world, rebuild stuff if necessary, clean distfiles.

if test "X$1" != "Xnosync"
then
    sudo layman -s ALL
    sudo emerge --sync
fi
emerge -DNtuvp world
echo "Press return to start merging."
read
sudo emerge -DNju --keep-going --quiet-build world
sudo etc-update
echo Emerging @preserved-rebuild...
sudo emerge @preserved-rebuild -vj --keep-going --quiet-build
sudo eclean -d distfiles
sudo emerge --depclean -av
echo "********************"
echo "* Update complete! *"
echo "********************"
echo
echo "Run perl-cleaner and python-updater if necessary."
read

