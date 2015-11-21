#!/bin/sh
exiftool -ext .jpg "-filename<CreateDate" -d %Y-%m-%d_%H.%M.%S.jpg .
