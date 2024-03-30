#!/usr/bin/sh
# Creates a secondary mouse pointer for Kensington Eagle Trackball.
# Can be used for example with a Wii emulator for multiple controllers.

xinput create-master trackball 0
xinput reattach "Primax Kensington Eagle Trackball" "trackball pointer"
