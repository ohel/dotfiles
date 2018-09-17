#!/bin/sh
# Rename all jpeg files in current directory to format YYYY-mm-dd_HH.MM.SS_.jpg.

exiftool "-FileName<CreateDate" -ext .jpg -overwrite_original_in_place -P -d %Y-%m-%d_%H.%M.%S_.jpg .
