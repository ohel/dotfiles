#!/usr/bin/sh
# Launch portals for flatpak.

[ -e /usr/libexec/flatpak-portal ] && /usr/libexec/flatpak-portal -r &
[ -e /usr/libexec/xdg-desktop-portal-gtk ] && /usr/libexec/xdg-desktop-portal-gtk -r &
[ -e /usr/libexec/xdg-desktop-portal ] && /usr/libexec/xdg-desktop-portal -r &
