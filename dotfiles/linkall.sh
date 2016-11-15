#!/bin/bash
# Link commonly used dotfiles from correct locations to the ones in this directory.

echo "Warning! Original files will be overwritten. Press a key to continue."
read

ln -sf $(readlink -f ./bashrc) ~/.bashrc
ln -sf $(readlink -f ./inputrc) ~/.inputrc
ln -sf $(readlink -f ./vimrc) ~/.vimrc
ln -sf $(readlink -f ./xbindkeysrc) ~/.xbindkeysrc
ln -sf $(readlink -f ./zathurarc) ~/.config/zathura/zathurarc