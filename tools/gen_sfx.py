#!/usr/bin/env python3
"""Generate 8-bit DOS-style sound effects for SKODA 305 (stdlib only).

Output: assets/sfx/*.wav  (22050 Hz, mono, 16-bit container with 8-bit
quantized levels for that crunchy Sound Blaster feel).
Run:  python3 tools/gen_sfx.py
"""
import math
import os
import random
import struct
import wave
from collections import deque

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sfx")
random.seed(1911)


def save(name, samples, gain=0.9):
    peak = max(1e-9, max(abs(s) for s in samples))
    frames = []
    for s in samples:
        v = math.tanh(s / peak * gain * 1.4)
        q = round((v * 0.5 + 0.5) * 255) / 255.0 * 2.0 - 1.0  # 8-bit steps
        frames.append(int(q * 32000))
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(struct.pack("<%dh" % len(frames), *frames))
    print("wrote %s (%.2fs)" % (path, len(frames) / SR))


def times(dur):
    return [i / SR for i in range(int(dur * SR))]


def lowpass(xs, win):
    q = deque(maxlen=win)
    out = []
    for x in xs:
        q.append(x)
        out.append(sum(q) / len(q))
    return out


def sweep_sine(dur, f_fn, amp_fn):
    out, phase = [], 0.0
    for t in times(dur):
        phase += 2.0 * math.pi * f_fn(t) / SR
        out.append(math.sin(phase) * amp_fn(t))
    return out


def shot():
    dur = 0.38
    tone = sweep_sine(dur, lambda t: 55 + 110 * math.exp(-t * 14),
                      lambda t: math.exp(-t * 9))
    noise = [random.uniform(-1, 1) * math.exp(-t * 26) * 0.8 for t in times(dur)]
    noise = lowpass(noise, 3)
    save("shot", [a + b for a, b in zip(tone, noise)], 1.0)


def boom(name, dur, lp, k_noise, f_rumble, k_rumble, gain):
    noise = [random.uniform(-1, 1) * math.exp(-t * k_noise) for t in times(dur)]
    noise = lowpass(noise, lp)
    rumble = sweep_sine(dur, lambda t: f_rumble,
                        lambda t: 0.8 * math.exp(-t * k_rumble))
    save(name, [a * 1.6 + b for a, b in zip(noise, rumble)], gain)


def destroy():
    dur = 2.3
    noise = [random.uniform(-1, 1) * math.exp(-t * 2.2) for t in times(dur)]
    noise = lowpass(noise, 18)
    out = []
    for i, t in enumerate(times(dur)):
        crackle = 0.0
        if random.random() < 0.015 * math.exp(-t * 1.5):
            crackle = random.uniform(-1, 1)
        rumble = 0.9 * math.sin(2 * math.pi * 38 * t) * math.exp(-t * 1.8)
        out.append(noise[i] * 1.8 + rumble + crackle)
    save("destroy", out, 1.0)


def square_note(f, dur, decay=8.0):
    out = []
    for t in times(dur):
        v = 1.0 if math.sin(2 * math.pi * f * t) >= 0 else -1.0
        out.append(v * math.exp(-t * decay) * 0.6)
    return out


def click():
    save("click", square_note(900, 0.03, 40.0), 0.5)


def beep():
    save("beep", square_note(660, 0.07, 18.0), 0.5)


def thud():
    dur = 0.25
    tone = sweep_sine(dur, lambda t: 40 + 35 * math.exp(-t * 20),
                      lambda t: math.exp(-t * 12))
    noise = lowpass([random.uniform(-1, 1) * math.exp(-t * 30) * 0.5 for t in times(dur)], 6)
    save("thud", [a + b for a, b in zip(tone, noise)], 0.8)


def win():
    seq = []
    for f, d in [(392, 0.14), (523, 0.14), (659, 0.14), (784, 0.42)]:
        seq += square_note(f, d, 5.0)
        seq += [0.0] * int(0.02 * SR)
    save("win", seq, 0.55)


def sting():
    # gentle A-minor arpeggio for the studio splash
    dur = 1.6
    out = [0.0] * int(dur * SR)
    for k, f in enumerate([220.0, 261.63, 329.63, 440.0]):
        start = int(k * 0.12 * SR)
        note = square_note(f, dur - k * 0.12, 2.5)
        for i, v in enumerate(note):
            if start + i < len(out):
                out[start + i] += v * 0.5
    save("sting", out, 0.5)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    shot()
    boom("boom1", 0.85, 8, 5.5, 52, 4.0, 1.0)
    boom("boom2", 1.5, 16, 2.8, 40, 2.2, 1.0)
    destroy()
    click()
    beep()
    thud()
    win()
    sting()
