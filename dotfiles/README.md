* `alsoftrc`: OpenAL configuration file, pointing to an MHR file which defines the HRTF.
* `asoundrc`: ALSA's ~/.asoundrc config file. This includes lots of virtual devices, multi-channel devices, LADSPA devices and more. There are also system specific `*_alsa_devices_*.conf` files.
* `bashrc`: ~/.bashrc.
* `conkyrc`: ~/.conkyrc. A minimal config showing a few RSS feeds and if something eats resources.
* `gitconfig`: ~/.gitconfig. Some aliases mainly.
* `inputrc`: ~/.inputrc.
* `profile`: ~/.profile. By default, just reads bashrc if using Bash.
* `profile.env`: ~/.profile.env. Environment variables. Sometimes read by graphical logins even if ~/.profile is not.
* `vimrc`: ~/.vimrc.
* `xbindkeys_mouseemu` and `xbindkeys_mousekeys`: Emulate a mouse using xbindkeys with Vim-style hjkl-mapping.
* `xbindkeysrc`: ~/.xbindkeys.
* `xinitrc`: ~/.xinitrc. On my main rig I start X using a good old xinitrc script.

The linkall.sh script will symlink dotfiles that are identical between the computers I use.
