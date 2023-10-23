#!/bin/bash

[ ! -e /dev/serial/matrix_orbital ] && echo No device && exit 1

echo -e "\xFE\x93\x00" > /dev/serial/matrix_orbital
