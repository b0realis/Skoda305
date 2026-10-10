#!/usr/bin/env python3
"""Convert the SCHOOL weapon-page photographs to VGA sepia, same recipe as the
boot splash (32 shades, no dithering). Underlying photographs are WWI-era
(public domain).

Usage: python3 tools/make_help_photos.py <skoda.jpg> <obice.jpg>
Outputs: assets/img/help_skoda.png, assets/img/help_obice.png
"""
import os
import sys

from PIL import Image, ImageFilter, ImageOps

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "img")

RAMP_STOPS = [(0x20, 0x1A, 0x14), (0x42, 0x3A, 0x30), (0x78, 0x6C, 0x5C),
              (0xC2, 0xAE, 0x94), (0xEE, 0xDE, 0xBC)]

MAX_W = 176
MAX_H = 132


def sepia_palette(n=32):
    pal = []
    for i in range(n):
        f = i / (n - 1) * (len(RAMP_STOPS) - 1)
        a = min(int(f), len(RAMP_STOPS) - 2)
        t = f - a
        c0, c1 = RAMP_STOPS[a], RAMP_STOPS[a + 1]
        pal += [round(c0[k] + (c1[k] - c0[k]) * t) for k in range(3)]
    return pal + [0, 0, 0] * (256 - n)


def convert(src, out_name, crop_bottom=0):
    img = Image.open(src).convert("L")
    w, h = img.size
    if crop_bottom:
        img = img.crop((0, 0, w, h - crop_bottom))
        w, h = img.size
    scale = min(MAX_W / w, MAX_H / h)
    img = img.resize((round(w * scale), round(h * scale)), Image.LANCZOS)
    img = ImageOps.autocontrast(img, cutoff=1)
    img = img.filter(ImageFilter.GaussianBlur(0.4))
    pal_img = Image.new("P", (1, 1))
    pal_img.putpalette(sepia_palette())
    out = img.convert("RGB").quantize(palette=pal_img, dither=Image.Dither.NONE)
    path = os.path.join(OUT, out_name)
    out.convert("RGB").save(path)
    print("wrote %s (%dx%d)" % (path, out.width, out.height))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    convert(sys.argv[1], "help_skoda.png", crop_bottom=60)
    convert(sys.argv[2], "help_obice.png")
