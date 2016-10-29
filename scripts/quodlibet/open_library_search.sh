#!/bin/sh
# If Quod Libet is running, send open library search command.

qlexe="/opt/programs/quodlibet/quodlibet.py"
if ps -ef | grep $qlexe | grep -v grep > /dev/null
then
    $qlexe --open-browser=SearchBar
fi
