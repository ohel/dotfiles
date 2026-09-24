#!/usr/bin/sh
# Update a Gentoo system: update overlays, update world, rebuild stuff if necessary, clean distfiles.

if test "X$1" != "Xnosync"
then
    command -v layman >/dev/null && layman -s ALL
    emaint sync --auto
fi
emerge -DNtuvp world

echo "Press return to start merging."
read tmp
old_perl=$(qlist -ICv dev-lang/perl)
emerge -DNju --keep-going --quiet-build world
new_perl=$(qlist -ICv dev-lang/perl)
if [ "$old_perl" != "$new_perl" ]
then
    echo Perl was updated, running perl-cleaner...
    perl-cleaner --reallyall
fi

etc-update
echo Emerging @preserved-rebuild...
emerge @preserved-rebuild -j --keep-going --quiet-build

eclean -d distfiles
emerge --depclean -a

flatpak_user=$(logname 2>/dev/null)
if command -v flatpak >/dev/null && [ -e /home/$flatpak_user/.var/app ]
then
    echo "Checking Flatpak updates for $flatpak_user..."
    if ! sudo -u "$flatpak_user" flatpak update --no-pull --no-deploy | grep -q "^Nothing to update\.$"
    then
        sudo -u "$flatpak_user" flatpak update --noninteractive
    fi
fi

echo
echo "********************"
echo "* Update complete! *"
echo "********************"
echo
read tmp
