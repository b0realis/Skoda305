#!/usr/bin/env python3
"""Generate the game icon: Škoda M.11 silhouette against a dithered sepia
sky and a snow-capped peak, 32x32 pixel art in the game palette, scaled
(nearest) to every reusable size.

Outputs:
  assets/icon/moznar-m11-{16,32,48,64,128,256,512}.png
  assets/icon/moznar-m11.ico        (16..256, for Windows reuse)
  icon.png                          (256, Godot project/window icon)

Run:  python3 tools/make_icon.py   (needs Pillow)
"""
import os

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
OUT = os.path.join(ROOT, "assets", "icon")

BAYER4 = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

SKY = [(166, 150, 132), (194, 174, 148), (220, 200, 168)]
PEAK_FAR = (138, 132, 150)
SNOW_FAR = (207, 206, 218)
PEAK_NEAR = (111, 106, 124)
SNOW_NEAR = (230, 230, 238)
GROUND_HI = (120, 108, 92)
GROUND = (90, 80, 68)
GROUND_LO = (66, 58, 48)
STEEL = (46, 50, 56)
STEEL_HI = (106, 112, 120)
MOUNT = (35, 38, 44)
PLATFORM = (28, 32, 36)
PLATFORM_HI = (58, 64, 70)
RIBBON_R = (210, 80, 74)
RIBBON_W = (232, 228, 220)


def bayer(x, y):
    return (BAYER4[y % 4][x % 4] + 0.5) / 16.0


def make_base():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    px = img.load()

    # dithered sepia sky
    for y in range(22):
        f = y / 21.0 * (len(SKY) - 1)
        i = min(int(f), len(SKY) - 2)
        frac = f - i
        for x in range(32):
            px[x, y] = SKY[i + 1] if frac > bayer(x, y) else SKY[i]

    draw = ImageDraw.Draw(img)
    # far peak (left) and near peak (right), snow caps
    draw.polygon([(0, 21), (9, 10), (18, 21)], fill=PEAK_FAR)
    draw.polygon([(6, 14), (9, 10), (12, 14)], fill=SNOW_FAR)
    draw.polygon([(12, 21), (23, 7), (32, 21)], fill=PEAK_NEAR)
    draw.polygon([(20, 11), (23, 7), (26, 11)], fill=SNOW_NEAR)

    # ground bands
    draw.rectangle([0, 21, 31, 21], fill=GROUND_HI)
    draw.rectangle([0, 22, 31, 25], fill=GROUND)
    draw.rectangle([0, 26, 31, 31], fill=GROUND_LO)

    # mortar silhouette: barrel, kettle mount, platform
    def thick_line(p0, p1, width, color):
        draw.line([p0, p1], fill=color, width=width)

    thick_line((10, 21), (23, 6), 5, STEEL)
    thick_line((9, 20), (21, 6), 1, STEEL_HI)   # top-edge glint
    draw.ellipse([21, 3, 26, 8], fill=STEEL)    # muzzle
    draw.ellipse([23, 4, 25, 6], fill=(20, 22, 26))  # bore
    draw.ellipse([5, 17, 16, 25], fill=MOUNT)   # kettle
    draw.rectangle([3, 25, 19, 28], fill=PLATFORM)
    draw.rectangle([3, 25, 19, 25], fill=PLATFORM_HI)
    # k.u.k. ribbon on the kettle
    px[8, 22] = RIBBON_R
    px[9, 22] = RIBBON_W
    px[10, 22] = RIBBON_R

    # rounded corners (r=4)
    mask = Image.new("L", (32, 32), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, 31, 31], radius=4, fill=255)
    img.putalpha(mask)
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    base = make_base()
    sizes = [16, 32, 48, 64, 128, 256, 512]
    for s in sizes:
        im = base.resize((s, s), Image.NEAREST)
        im.save(os.path.join(OUT, "moznar-m11-%d.png" % s))
    big = base.resize((256, 256), Image.NEAREST)
    big.save(os.path.join(ROOT, "icon.png"))
    big.save(os.path.join(OUT, "moznar-m11.ico"),
             sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    print("wrote icon set to", OUT, "and icon.png")


if __name__ == "__main__":
    main()
