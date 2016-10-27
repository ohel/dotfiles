#!/bin/bash
# Creates a secondary mouse pointer.
# I used to use this with a Kensington trackball to play World of Goo with two mice using a Wii emulator.

xinput create-master trackball 0
xinput reattach "Primax Kensington Eagle Trackball" "trackball pointer"
