#!/bin/sh
# Simple archive contents viewer for common archive types.

filename="$1"
type_zip=$(file "$filename" | grep Zip)
type_rar=$(file "$filename" | grep RAR)
type_gzip=$(file "$filename" | grep gzip)
type_tar=$(file "$filename" | grep tar)
[ "$type_zip" ] && unzip -l "$filename" | gvim -R -
[ "$type_rar" ] && unrar vp "$filename" | gvim -R -
[ "$type_gzip" ] && tar ztvf "$filename" | gvim -R -
[ "$type_tar" ] && tar tvf "$filename" | gvim -R -
