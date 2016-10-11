#!/bin/sh
# Simple archive contents viewer for common archive types.

filename="$1"
type_zip=$(file "$filename" | grep Zip)
type_rar=$(file "$filename" | grep RAR)
type_gzip=$(file "$filename" | grep gzip)
type_tar=$(file "$filename" | grep tar)
if test "X$type_zip" != "X"; then
    unzip -l "$filename" | gvim -R -
elif test "X$type_rar" != "X"; then
    unrar vp "$filename" | gvim -R -
elif test "X$type_gzip" != "X"; then
    tar ztvf "$filename" | gvim -R -
elif test "X$type_tar" != "X"; then
    tar tvf "$filename" | gvim -R -
fi
