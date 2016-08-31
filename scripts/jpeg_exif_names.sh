#!/bin/bash
exiftool "-FileName<CreateDate" -ext .jpg -overwrite_original_in_place -P -d %Y-%m-%d_%H.%M.%S_.jpg .
