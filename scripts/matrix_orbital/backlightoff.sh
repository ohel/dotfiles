#!/bin/bash

[ ! -e /dev/serial/matrix_orbital ] && echo No device && exit 1

echo -e "\xFEF" > /dev/serial/matrix_orbital
