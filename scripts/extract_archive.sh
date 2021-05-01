#!/bin/sh
# Simple archive extractor for common archive types.

filename="$1"
type_zip=$(file "$filename" | grep Zip)
type_rar=$(file "$filename" | grep RAR)
type_gzip=$(file "$filename" | grep gzip)
type_bzip=$(file "$filename" | grep gzip)
type_tar=$(file "$filename" | grep tar)
type_7z=$(file "$filename" | grep 7-zip)
[ "$type_zip" ] && unzip -d "$(echo "$filename" | sed "s/\.zip$//")" -x "$filename"
[ "$type_rar" ] && rar x "$filename"
[ "$type_gzip" ] && tar xzf "$filename"
[ "$type_bzip" ] && tar xjf "$filename"
[ "$type_tar" ] && tar xf "$filename"
[ "$type_7z" ] && 7z x "$filename"
