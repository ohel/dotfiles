#!/bin/bash

[ ! -e /dev/serial/matrix_orbital ] && echo No device && exit 1

echo -en "\xFEH" > /dev/serial/matrix_orbital
