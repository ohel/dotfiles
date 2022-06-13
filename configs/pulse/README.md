PulseAudio configuration files for simple ALSA and JACK bridges, to use PulseAudio-only applications without really using PulseAudio. The default location for the config files is /etc/pulse.
PulseAudio seems to have problems with JACK sometimes so the ALSA loopback pipe could be used with `alsa_in, alsa_out` for the same effect.

* client.conf: PulseAudio client configuration. Essentially just disables auto-spawning PulseAudio.
* daemon.conf: Sets up PulseAudio as just an inobtrusive pipe. Override or link daemon.conf to this file.
* alsapipe.pa: Loads just the essential ALSA modules for PA to work as an ALSA pipe.
* looppipe.pa: Loads just the essential ALSA modules for PA to work as an ALSA pipe using the "loop" ALSA device, which should have a hw:Loopback device behind it.
* jackpipe.pa: Loads just the essential JACK modules for PA to work as a JACK pipe.
* pulsejack.sh: Run JACK daemon and PulseAudio as JACK pipe.
