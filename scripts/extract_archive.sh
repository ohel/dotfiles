#!/bin/sh
# Simple archive extractor for common archive types.

filename="$1"
type_zip=$(file "$filename" | grep Zip)
type_rar=$(file "$filename" | grep RAR)
type_gzip=$(file "$filename" | grep gzip)
type_tar=$(file "$filename" | grep tar)
type_7z=$(file "$filename" | grep 7-zip)
if test "X$type_zip" != "X"; then
    unzip -d "$(echo "$filename" | sed "s/.zip//")" -x "$filename"
elif test "X$type_rar" != "X"; then
    rar x "$filename"
elif test "X$type_gzip" != "X"; then
    tar xzf "$filename"
elif test "X$type_tar" != "X"; then
    tar xf "$filename"
elif test "X$type_7z" != "X"; then
    7z x "$filename"
fi
