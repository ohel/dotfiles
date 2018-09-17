#!/bin/sh
# Simple archive contents viewer for common archive types.

filename="$1"
type_zip=$(file "$filename" | grep Zip)
type_rar=$(file "$filename" | grep RAR)
type_gzip=$(file "$filename" | grep gzip)
type_tar=$(file "$filename" | grep tar)
if [ "$type_zip" ]
then
    unzip -l "$filename" | gvim -R -
elif [ "$type_rar" ]
then
    unrar vp "$filename" | gvim -R -
elif [ "$type_gzip" ]
then
    tar ztvf "$filename" | gvim -R -
elif [ "$type_tar" ]
then
    tar tvf "$filename" | gvim -R -
fi
