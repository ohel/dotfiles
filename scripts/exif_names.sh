#!/bin/sh
# Rename all jpg and rw2 files in current directory to format YYYY-mm-dd_HH.MM.SS_.jpg.

exiftool "-FileName<CreateDate" -ext .jpg -ext .rw2 -overwrite_original_in_place -P -d %Y-%m-%d_%H.%M.%S_.jpg .
