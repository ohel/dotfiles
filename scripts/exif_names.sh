#!/usr/bin/sh
# Rename specified types of image files in current directory to format: YYYY-mm-dd_HH.MM.SS_

exiftool '-FileName<${CreateDate}.${FileName;s/.*\.//}' -ext jpg -ext rw2 -ext webp -ext dng -overwrite_original_in_place -P -d %Y-%m-%d_%H.%M.%S_ .
