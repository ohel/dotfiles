#/bin/sh
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
echo "********************"
echo "* Update complete! *"
echo "********************"
echo
echo "Run perl-cleaner and python-updater if necessary."
echo "To remove obsolete packages:"
echo "sudo emerge --depclean -av"
read

