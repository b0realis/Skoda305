#!/usr/bin/env python3
"""Convert the LOC 'War of the Nations' photo of the Skoda 305 mm M.11 into
a 320x200 VGA sepia splash (16 colors, Floyd-Steinberg dither).

Usage: python3 tools/make_splash_photo.py [source.jpg]
If no source is given, downloads from Wikimedia Commons (public domain, 1919).
Output: assets/img/splash_photo.png
"""
import os
import sys
import urllib.request

from PIL import Image, ImageFilter, ImageOps

URL = ("https://upload.wikimedia.org/wikipedia/commons/0/0d/"
       "Skoda_305_mm_Model_1911_LOC_War_of_the_Nations_1.jpg")
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "img", "splash_photo.png")

# sepia ramp: game palette tones, dark bunker brown -> archive cream
RAMP_STOPS = [(0x20, 0x1A, 0x14), (0x42, 0x3A, 0x30), (0x78, 0x6C, 0x5C),
              (0xC2, 0xAE, 0x94), (0xEE, 0xDE, 0xBC)]


def sepia_palette(n=32):
    pal = []
    for i in range(n):
        f = i / (n - 1) * (len(RAMP_STOPS) - 1)
        a = min(int(f), len(RAMP_STOPS) - 2)
        t = f - a
        c0, c1 = RAMP_STOPS[a], RAMP_STOPS[a + 1]
        pal += [round(c0[k] + (c1[k] - c0[k]) * t) for k in range(3)]
    return pal + [0, 0, 0] * (256 - n)


def main():
    if len(sys.argv) > 1:
        src = sys.argv[1]
    else:
        src = os.path.join(HERE, "skoda305_src.jpg")
        if not os.path.exists(src):
            print("downloading", URL)
            req = urllib.request.Request(URL, headers={"User-Agent": "SkodaM1911-dev"})
            with urllib.request.urlopen(req) as r, open(src, "wb") as f:
                f.write(r.read())

    img = Image.open(src).convert("L")
    w, h = img.size
    # whole photograph, pillarboxed: fit to the area above the caption bar
    ph = 184
    pw = round(w * ph / h)
    img = img.resize((pw, ph), Image.LANCZOS)
    img = ImageOps.autocontrast(img, cutoff=1)
    # gentle smoothing, then quantize WITHOUT dithering: no speckle, just
    # clean posterized sepia (32 shades keep the banding nearly invisible)
    img = img.filter(ImageFilter.GaussianBlur(0.4))

    pal_img = Image.new("P", (1, 1))
    pal_img.putpalette(sepia_palette())
    photo = img.convert("RGB").quantize(palette=pal_img,
                                        dither=Image.Dither.NONE)
    canvas = Image.new("RGB", (320, 200), (0, 0, 0))
    canvas.paste(photo.convert("RGB"), ((320 - pw) // 2, 0))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    canvas.save(OUT)
    print("wrote %s (photo %dx%d)" % (OUT, pw, ph))


if __name__ == "__main__":
    main()
