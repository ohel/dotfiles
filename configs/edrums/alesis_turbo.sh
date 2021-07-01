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

if [ ! "$(aconnect -i | grep "$DRUMS")" ]
then
    echo "Drums not connected? Press return to try again."
    read tmp
fi
[ ! "$(aconnect -i | grep "$DRUMS")" ] && exit 1

scriptdir=$(dirname "$(readlink -f "$0")")
HYDROGEN_SONG="$scriptdir/drum_practice.h2song"
MIDIDINGS_SCRIPT="$scriptdir/$(echo "$DRUMS" | tr '[:upper:]' '[:lower:]' | sed "s/ /_/g").py"

# Use existing JACK server if running.
jackd_pid=$(ps -e | grep jackd | grep -o "^[ 0-9]*" | tr -d ' ')

if [ ! "$jackd_pid" ]
then
    qjackctl -p $QJACK_PRESET -s &
    pid_qjackctrl=$!
    sleep 1
fi
sudo -n renice -n -10 $jackd_pid $pid_qjackctrl

if [ ! "$(ps -e | grep hydrogen)" ]
then
    hydrogen -s $HYDROGEN_SONG &
    pid_hydrogen=$!
    sleep 1
fi

md_exe=mididings
# The mididings_script is originally named mididings, but there's a directory by the same name for Python code if installing like I did, i.e. manually to an arbitrary location.
[ -e /opt/programs/mididings/mididings_script ] && md_exe=/opt/programs/mididings/mididings_script
if [ ! "$(ps -ef | grep $md_exe | grep -v grep)" ]
then
    $md_exe -f $MIDIDINGS_SCRIPT &
    pid_mididings=$!
    sleep 1
fi

echo "Connecting MIDI"
aconnect "$DRUMS" mididings 2>/dev/null
aconnect mididings:1 Hydrogen 2>/dev/null

# Nothing was started, so this must've been just a MIDI reconnect after automatic power off.
[ "$pid_qjackctrl$pid_hydrogen$pid_mididings" = "" ] && exit 0

echo "Connecting ALSA/JACK bridge"
alsa_in -j "ALSA output" -d loop_playback_out &
alsa_out -j "ALSA input" -d loop_record_in &
sleep 1
jack_connect "ALSA output:capture_1" "system:playback_1"
jack_connect "ALSA output:capture_2" "system:playback_2"

if [ "$(which jack-rack 2>/dev/null)" ] && [ -e /opt/jackrack/reverb_drums ]
then
    echo "Connecting JACK Rack"
    jack-rack /opt/jackrack/reverb_drums &
    pid_jackrack=$!
    sleep 2
    jack_disconnect "Hydrogen:out_L" "system:playback_1"
    jack_disconnect "Hydrogen:out_R" "system:playback_2"
    jack_connect "Hydrogen:out_L" "jack_rack:in_1"
    jack_connect "Hydrogen:out_R" "jack_rack:in_2"
    jack_connect "jack_rack:out_1" "system:playback_1"
    jack_connect "jack_rack:out_2" "system:playback_2"
fi

echo
echo Press return twice to quit.
read temp
echo Press return once to quit.
read temp

[ "$pid_mididings" ] && kill $pid_mididings
[ "$pid_jackrack" ] && kill $pid_jackrack
[ "$pid_hydrogen" ] && kill $pid_hydrogen
[ "$pid_qjackctrl" ] && kill $pid_qjackctrl
[ "$pid_qjackctrl" ] && killall jackd
