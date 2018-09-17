#!/bin/sh
# Split a FLAC file according to CUE sheet and tag the resulting files.

cuebreakpoints *.cue | shnsplit -o flac *.flac
cuetag.sh *.cue split-track*.flac
