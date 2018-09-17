#!/bin/bash
# Clear and turn off LCD.

if [ -e /dev/serial/matrix_orbital ]
then
	echo -n -e "\xFEX\xFE\x48\xFE\x46" > /dev/serial/matrix_orbital
fi
