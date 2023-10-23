#!/bin/bash

[ ! -e /dev/serial/matrix_orbital ] && echo No device && exit 1

echo -e "\xFEX" > /dev/serial/matrix_orbital
