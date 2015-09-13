* backup.sh: My full system backup script. It creates separate backups for system files, home files, media files, Gentoo's distfiles and virtual machine images.
* copymusic.sh: I use this to copy music to my phone. I just drag'n'drop songs from my media player into a terminal window while the script is running. I store my music in lossless format, so this script calls the copymusic_encode.sh script in parallel to encode files on fly.
* copymusic_encode.sh: Encodes and tags a source audio file to destination file.
* dosbox.sh: Set's CPU affinity and runs DosBox on single core with performance governor.
* kvm: Kernel-based Virtual Machine scripts.
* network_all: An OpenRC script to set up a network interface and a bridge for virtual machines.
