#!/usr/bin/sh
# Split a FLAC file according to CUE sheet and tag the resulting files.
# Uses the cuetools package: https://github.com/svend/cuetools

cuebreakpoints *.cue | shnsplit -o flac *.flac
cuetag.sh *.cue split-track*.flac
