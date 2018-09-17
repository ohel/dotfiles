#!/bin/sh
# Simple archive extractor for common archive types.

filename="$1"
type_zip=$(file "$filename" | grep Zip)
type_rar=$(file "$filename" | grep RAR)
type_gzip=$(file "$filename" | grep gzip)
type_tar=$(file "$filename" | grep tar)
type_7z=$(file "$filename" | grep 7-zip)
if [ "$type_zip" ];
then
    unzip -d "$(echo "$filename" | sed "s/.zip//")" -x "$filename"
elif [ "$type_rar" ]
then
    rar x "$filename"
elif [ "$type_gzip" ]
then
    tar xzf "$filename"
elif [ "$type_tar" ]
then
    tar xf "$filename"
elif [ "$type_7z" ]
then
    7z x "$filename"
fi
