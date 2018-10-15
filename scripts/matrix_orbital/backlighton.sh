#!/bin/bash
# last byte = minutes the light is on, 0 = permanently
echo -e "\xFEB\x00" > /dev/ttyUSB0
