#!/bin/sh
# Link commonly used dotfiles from correct locations to the ones in this directory.

echo "Warning! Original files will be overwritten. Press a key to continue."
read tmp

ln -sf $(readlink -f ./profile) ~/.profile
ln -sf $(readlink -f ./profile.env) ~/.profile.env
ln -sf $(readlink -f ./bashrc) ~/.bashrc
ln -sf $(readlink -f ./gitconfig) ~/.gitconfig
ln -sf $(readlink -f ./inputrc) ~/.inputrc
ln -sf $(readlink -f ./vimrc) ~/.vimrc
ln -sf $(readlink -f ./xbindkeysrc) ~/.xbindkeysrc
ln -sf $(readlink -f ./zathurarc) ~/.config/zathura/zathurarc
ln -sf $(readlink -f ./xinitrc) ~/.xinitrc

# This is for display managers to read common environment variables.
ln -sf ~/.profile.env ~/.xprofile
