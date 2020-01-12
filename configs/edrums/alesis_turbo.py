#!/usr/bin/env python3
# A mididings script.
# Translates MIDI messages coming from Alesis Turbo Mesh Kit edrums so that:
#   * the hihat openness is taken into account
#   * a hard ride hit is translated into a different cymbal
#   * if kick drum is hit 8+ times in a row, hihat pedal turns into double kick pedal
#   * if crash cymbal is hit 8+ times in a row, double kick pedal turns into hihat pedal
# To debug MIDI messages
#   1. run: amidi -p virtual -d
#   2. connect the edrum MIDI device to the virtual RawMIDI port

from mididings import *
from mididings import engine as _Engine

class MidiTranslations():

    def __init__(self):

        self.hihat_closed = False
        self.hihat_is_double_kick = False
        self._switch_to_double_kick_counter = 0
        self._switch_to_hihat_counter = 0

    def reset_switch_counters(self):

        self._switch_to_double_kick_counter = 0
        self._switch_to_hihat_counter = 0

    def grow_switch_to_double_kick_counter(self):

        self._switch_to_double_kick_counter += 1
        self._switch_to_hihat_counter = 0
        # 16 note on/off events = 8 hits
        if self._switch_to_double_kick_counter > 16 and not self.hihat_is_double_kick:
            self.hihat_is_double_kick = True
            print("Second pedal is now a double kick pedal.")

    def grow_switch_to_hihat_counter(self):

        self._switch_to_hihat_counter += 1
        self._switch_to_double_kick_counter = 0
        # 16 note on/off events = 8 hits
        if self._switch_to_hihat_counter > 16 and self.hihat_is_double_kick:
            self.hihat_is_double_kick = False
            print("Second pedal is now a hihat pedal.")

    def control_hihat_openness(self, ev):

        # Control value is 127 when hihat pedal is down: B9 04 7F
        self.hihat_closed = ev.value == 127

    def apply_hihat_openness(self, ev):

        if self.hihat_closed and not self.hihat_is_double_kick:
            ev.note = 42
        return ev

    def hard_ride_hit(self, ev):

        # The velocity level is arbitrary, determined by experimenting.
        if ev.velocity > 60:
            ev.note = 52
        return ev

    def hihat_to_kick(self, ev):

        if self.hihat_is_double_kick:
            ev.note = 36
            # Alesis Turbo has no velocity info for the kick drum, it always uses 0x64.
            ev.velocity = 100
        return ev

config(
    backend='alsa',
    client_name='mididings',
    in_ports=['midi_in'],
    out_ports=['midi_out']
)

def apply_note_translations(ev):

    try: _Engine._TheEngine().custom_translations
    except: _Engine._TheEngine().custom_translations = MidiTranslations()
    ct = _Engine._TheEngine().custom_translations

    # Kick
    if ev.note == 36:
        ct.grow_switch_to_double_kick_counter()

    # Crash
    elif ev.note == 49:
        ct.grow_switch_to_hihat_counter()

    else:
        ct.reset_switch_counters()

        # Hihat pedal
        if ev.note == 44:
            ev = ct.hihat_to_kick(ev)

        # Hihat
        elif ev.note == 46:
            ev = ct.apply_hihat_openness(ev)

        # Ride
        elif ev.note == 51:
            ev = ct.hard_ride_hit(ev)

    return ev

def apply_control_translations(ev):

    try: _Engine._TheEngine().custom_translations
    except: _Engine._TheEngine().custom_translations = MidiTranslations()
    _Engine._TheEngine().custom_translations.control_hihat_openness(ev)

run(
    [
        Filter(CTRL) >> CtrlFilter(4) >> Process(apply_control_translations),
        Filter(NOTEON|NOTEOFF) >> Process(apply_note_translations)
    ]
)
