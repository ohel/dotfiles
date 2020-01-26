#!/bin/sh
# Simple archive contents viewer for common archive types.

filename="$1"
type_zip=$(file "$filename" | grep Zip)
type_rar=$(file "$filename" | grep RAR)
type_gzip=$(file "$filename" | grep gzip)
type_tar=$(file "$filename" | grep tar)
done=""

[ ! "$done" ] && [ "$type_zip" ] && done=1 && unzip -l "$filename" | gvim -R -
[ ! "$done" ] && [ "$type_rar" ] && done=1 && unrar vp "$filename" | gvim -R -
[ ! "$done" ] && [ "$type_gzip" ] && done=1 && tar ztvf "$filename" | gvim -R -
[ ! "$done" ] && [ "$type_tar" ] && done=1 && tar tvf "$filename" | gvim -R -
