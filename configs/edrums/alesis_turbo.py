#!/usr/bin/env python3
# A mididings script.
# Translates MIDI messages coming from Alesis Turbo Mesh Kit edrums so that:
#   * the hihat openness is taken into account
#   * a hard ride hit is translated into a different cymbal
# To debug MIDI messages
#   1. run: amidi -p virtual -d
#   2. connect the edrum MIDI device to the virtual RawMIDI port

from mididings import *

config(
    backend='alsa',
    client_name='mididings',
    in_ports=['midi_in'],
    out_ports=['midi_out']
)

def check_hihat_openness(ev):
    # Control value is 127 when hihat pedal is down: B9 04 7F
    ev.ctrl = 2 if ev.value == 127 else 1
    return ev

def apply_hihat_openness(ev):
    ev.note = 42
    return ev

def translate_hard_ride_hit(ev):
    # The velocity level is arbitrary, determined by experimenting.
    if ev.velocity > 60:
        ev.note = 52
    return ev

run(
    scenes = {
        1:  Scene("hihat open",
                [
                    KeyFilter(notes=[51]) >> Process(translate_hard_ride_hit),
                    ~KeyFilter(notes=[51])
                ]
            ),
        2:  Scene("hihat closed",
                [
                    KeyFilter(notes=[46]) >> Process(apply_hihat_openness),
                    KeyFilter(notes=[51]) >> Process(translate_hard_ride_hit),
                    ~KeyFilter(notes=[46,51])
                ]
            )
    },
    control = Filter(CTRL) >> CtrlFilter(4) >> Process(check_hihat_openness) >> [
        CtrlFilter(1) >> SceneSwitch(1),
        CtrlFilter(2) >> SceneSwitch(2)
    ],
    pre = Filter(NOTEON|NOTEOFF)
)
