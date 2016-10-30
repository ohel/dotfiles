#!/bin/sh
# Can be used in file managers to batch determine file types.

for arg
do
	file "$arg"
done
read
