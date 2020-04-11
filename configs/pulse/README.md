PulseAudio configuration files for simple ALSA and JACK bridges. The default location for the config files is /etc/pulse.

* client.conf: PulseAudio client configuration. Essentially just disables auto-spawning PulseAudio.
* alsapipe.conf: Sets up PulseAudio as just an inobtrusive pipe. Symlink daemon.conf to this file.
* alsapipe.pa: Loads just the essential ALSA modules for PA to work as an ALSA pipe.
* jackpipe.pa: Loads just the essential JACK modules for PA to work as a JACK pipe.
* pulsejack.sh: Run JACK daemon and PulseAudio as JACK pipe.

Turns out that some USB soundcards (such as the MOTU M4, as of April 2020) don't work in duplex mode with ALSA directly, but work as they should using JACK - which of course still uses ALSA to communicate with the hardware, but go and figure. Many applications (such as common video conferencing software) use PulseAudio. To get your microphone working with playback, one can use a PulseAudio JACK bridge setup. The convenience script pulsejack.sh is for that purpose.
