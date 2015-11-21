#!/bin/bash
cuebreakpoints *.cue | shnsplit -o flac *.flac
cuetag.sh *.cue split-track*.flac
