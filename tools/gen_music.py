#!/usr/bin/env python3
"""Generate the Adlib-style title tune (stdlib only).

An original melancholic march in A minor over the lament progression
Am - G - F - E: square-wave lead with vibrato, low square bass in
root-fifth march time, noise snare on the off-beats. 8-bit crunch.

Output: assets/sfx/title_theme.wav (~21 s, meant to loop).
Run:  python3 tools/gen_music.py
"""
import math
import os
import random
import struct
import wave

SR = 22050
BPM = 92.0
BEAT = 60.0 / BPM
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sfx")
random.seed(305)

NOTES = {"E2": 82.41, "F2": 87.31, "G2": 98.00, "A2": 110.00, "B2": 123.47,
         "C3": 130.81, "D3": 146.83, "E3": 164.81, "F3": 174.61, "G3": 196.00,
         "A3": 220.00, "B3": 246.94, "C4": 261.63, "D4": 293.66, "E4": 329.63,
         "F4": 349.23, "G4": 392.00, "GS4": 415.30, "A4": 440.00, "B4": 493.88,
         "C5": 523.25, "D5": 587.33, "E5": 659.26, "R": 0.0}

# lead: (note, beats) — two 4-bar phrases over Am G F E, question and answer
LEAD = [
    ("A4", 1), ("C5", 1), ("E5", 1.5), ("D5", 0.5),      # Am
    ("D5", 1), ("B4", 1), ("G4", 2),                     # G
    ("F4", 1), ("A4", 1), ("C5", 1.5), ("B4", 0.5),      # F
    ("B4", 1), ("GS4", 1), ("E4", 2),                    # E
    ("E5", 1), ("C5", 1), ("A4", 1.5), ("B4", 0.5),      # Am
    ("G4", 1), ("B4", 1), ("D5", 2),                     # G
    ("C5", 1), ("A4", 1), ("F4", 1.5), ("G4", 0.5),      # F
    ("GS4", 2), ("B4", 1), ("E4", 1),                    # E
]

# bass: root-fifth march, one bar per chord, repeated for both phrases
BASS_BARS = [("A2", "E3"), ("G2", "D3"), ("F2", "C3"), ("E2", "B2")] * 2


def square(phase, duty=0.5):
    return 0.6 if (phase % 1.0) < duty else -0.6


def render():
    total_beats = sum(b for _, b in LEAD)
    n = int(total_beats * BEAT * SR)
    mix = [0.0] * n

    # lead voice
    t0 = 0.0
    for name, beats in LEAD:
        dur = beats * BEAT
        f = NOTES[name]
        if f > 0:
            i0 = int(t0 * SR)
            phase = 0.0
            for i in range(int(dur * SR)):
                t = i / SR
                vib = 1.0 + 0.006 * math.sin(2 * math.pi * 5.5 * t)
                phase += f * vib / SR
                env = min(t / 0.02, 1.0) * min((dur - t) / 0.06, 1.0)
                env *= 0.75 + 0.25 * math.exp(-t * 3.0)
                if i0 + i < n:
                    mix[i0 + i] += square(phase, 0.25) * env * 0.55
        t0 += dur

    # bass voice: root on beats 1-2, fifth on beats 3-4
    t0 = 0.0
    for root, fifth in BASS_BARS:
        for k in range(4):
            f = NOTES[root] if k < 2 else NOTES[fifth]
            i0 = int(t0 * SR)
            phase = 0.0
            for i in range(int(BEAT * SR)):
                t = i / SR
                phase += f / SR
                env = min(t / 0.01, 1.0) * math.exp(-t * 4.0)
                if i0 + i < n:
                    mix[i0 + i] += square(phase, 0.5) * env * 0.4
            t0 += BEAT

    # snare on beats 2 and 4 of every bar
    beat_i = 0
    t0 = 0.0
    while t0 < total_beats * BEAT - 0.01:
        if beat_i % 4 in (1, 3):
            i0 = int(t0 * SR)
            for i in range(int(0.09 * SR)):
                if i0 + i < n:
                    mix[i0 + i] += random.uniform(-1, 1) * math.exp(-i / SR * 55.0) * 0.3
        beat_i += 1
        t0 += BEAT

    return mix


def save(name, samples, gain=0.85):
    peak = max(1e-9, max(abs(s) for s in samples))
    frames = []
    for s in samples:
        v = math.tanh(s / peak * gain * 1.3)
        q = round((v * 0.5 + 0.5) * 255) / 255.0 * 2.0 - 1.0
        frames.append(int(q * 32000))
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(struct.pack("<%dh" % len(frames), *frames))
    print("wrote %s (%.2fs)" % (path, len(frames) / SR))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    save("title_theme", render())
