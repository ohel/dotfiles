#!/bin/bash
# Clear and turn off LCD.

if [ -e /dev/serial/matrix_orbital ]
then
	echo -en "\xFEX\xFEH\xFEF" > /dev/serial/matrix_orbital
fi
