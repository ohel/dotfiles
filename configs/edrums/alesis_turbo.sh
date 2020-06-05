#!/bin/sh
# Start and connect basic stuff to begin practicing with electric drums:
#   * Start JACK server if not running, with the edrums/$1 preset.
#   * Start mididings to fix MIDI messages.
#   * Start Hydrogen drum machine with a saved song (has drumkits and everything set up).
#   * Connect drums to mididings, and mididings to Hydrogen via MIDI.
#   * Connect Hydrogen to JACK server.
# Some drum sets, such as the Alesis Turbo, send their hi-hat pedal status
# along with the hi-hat note. The mididings script is used to modify the MIDI
# note according to the pedal status; other tweaks are also possible.

DRUMS="Alesis Turbo"
QJACK_PRESET=${1:-edrums}

if [ ! "$(aconnect -i | grep "Alesis Turbo")" ]
then
    echo "Drums not connected? Press return to try again."
    read tmp
fi
[ ! "$(aconnect -i | grep "Alesis Turbo")" ] && exit 1

scriptdir=$(dirname "$(readlink -f "$0")")
HYDROGEN_SONG="$scriptdir/drum_practice.h2song"
MIDIDINGS_SCRIPT="$(echo "$DRUMS" | tr '[:upper:]' '[:lower:]' | sed "s/ /_/g").py"

# Use existing JACK server if running.
jackd_pid=$(ps -e | grep jackd | cut -f 1 -d ' ')

[ "$jackd_pid" ] || qjackctl -p $QJACK_PRESET -s &
[ "$jackd_pid" ] || pid_qjackctrl=$!
sudo -n renice -n -10 $jackd_pid $pid_qjackctrl
sleep 1

hydrogen -s $HYDROGEN_SONG &
pid_hydrogen=$!
sleep 1

md_exe=mididings
# The mididings_script is originally named mididings, but there's a directory by the same name for Python code if installing like I did, i.e. manually to an arbitrary location.
[ -e /opt/programs/mididings/mididings_script ] && md_exe=/opt/programs/mididings/mididings_script
$md_exe -f $MIDIDINGS_SCRIPT &
pid_mididings=$!
sleep 1

echo "Connecting MIDI"
aconnect "$DRUMS" mididings
aconnect mididings:1 Hydrogen
echo "Connecting ALSA/JACK bridge"
alsa_in -j "ALSA output" -d loop_playback_out &
alsa_out -j "ALSA input" -d loop_record_in &
sleep 1
jack_connect "ALSA output:capture_1" system:playback_1
jack_connect "ALSA output:capture_2" system:playback_2

echo
echo Press return twice to quit.
read temp
echo Press return once to quit.
read temp

kill $pid_mididings
kill $pid_hydrogen
[ "$pid_qjackctrl" ] && kill $pid_qjackctrl
[ "$pid_qjackctrl" ] && killall jackd
