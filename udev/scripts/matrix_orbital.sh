#!/bin/bash
stty -F /dev/serial/matrix_orbital speed 19200 -onlcr
echo -n -e "\xFEX" > /dev/serial/matrix_orbital

