#!/usr/bin/sh
# Simple archive contents viewer for common archive types.

filename="$1"
type_zip=$(file "$filename" | grep Zip)
type_rar=$(file "$filename" | grep RAR)
type_gzip=$(file "$filename" | grep gzip)
type_bzip=$(file "$filename" | grep bzip2)
type_tar=$(file "$filename" | grep tar)
type_7z=$(file "$filename" | grep 7-zip)
done=""

[ ! "$done" ] && [ "$type_zip" ] && done=1 && unzip -l "$filename" | gvim -R -
[ ! "$done" ] && [ "$type_rar" ] && done=1 && unrar vp "$filename" | gvim -R -
[ ! "$done" ] && [ "$type_gzip" ] && done=1 && tar ztvf "$filename" | gvim -R -
[ ! "$done" ] && [ "$type_bzip" ] && done=1 && tar jtvf "$filename" | gvim -R -
[ ! "$done" ] && [ "$type_tar" ] && done=1 && tar tvf "$filename" | gvim -R -
[ ! "$done" ] && [ "$type_7z" ] && done=1 && 7z l "$filename" | gvim -R -
