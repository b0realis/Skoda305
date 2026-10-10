#!/usr/bin/env python3
"""Assemble the itch.io media package into media-package/ (needs Pillow).

Inputs: docs/*.png screenshots (640x400), media-package/logos/*.png
(rendered by tools/media.tscn), assets/icon/*, and optionally a frames dir
for the gameplay GIF.

Usage: python3 tools/make_media.py [gif_frames_dir]
"""
import glob
import os
import random
import shutil
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
MP = os.path.join(ROOT, "media-package")
BG = (20, 22, 28)  # 14161c


def scale(img, k):
    return img.resize((img.width * k, img.height * k), Image.NEAREST)


def logo_scales():
    for name in ["logo-game-wordmark", "logo-prescription-games"]:
        p = os.path.join(MP, "logos", name + ".png")
        img = Image.open(p)
        for k in [2, 4]:
            scale(img, k).save(os.path.join(MP, "logos", "%s@%dx.png" % (name, k)))
        # dark-background variant for places that dislike transparency
        dark = Image.new("RGBA", img.size, BG + (255,))
        dark.paste(img, (0, 0), img)
        scale(dark, 4).convert("RGB").save(
            os.path.join(MP, "logos", name + "-dark@4x.png"))
    print("logos: scales + dark variants")


def cover():
    """itch.io cover, 630x500: wordmark band on top, battle scene below."""
    battle = Image.open(os.path.join(ROOT, "docs", "battle.png"))
    wordmark = scale(Image.open(os.path.join(MP, "logos", "logo-game-wordmark.png")), 2)
    canvas = Image.new("RGB", (630, 500), BG)
    canvas.paste(battle.crop((5, 3, 635, 397)), (0, 106))
    canvas.paste(wordmark, ((630 - wordmark.width) // 2, 14), wordmark)
    canvas.save(os.path.join(MP, "cover-630x500.png"))
    print("cover-630x500")


def banner():
    """Wide page banner, 960x240: x3-scaled scenery band + wordmark on a
    beveled steel panel (the game's own dialog style)."""
    shot = Image.open(os.path.join(ROOT, "docs", "battle.png"))
    native = shot.resize((320, 200), Image.NEAREST)  # exact /2 back to native
    big = scale(native, 3)  # 960x600
    band = big.crop((0, 180, 960, 420))
    wordmark = scale(Image.open(os.path.join(MP, "logos", "logo-game-wordmark.png")), 2)
    pw, ph = wordmark.width + 36, wordmark.height + 24
    panel = Image.new("RGB", (pw, ph), (35, 38, 44))
    ppx = panel.load()
    for x in range(pw):
        ppx[x, 0] = (78, 85, 96)
        ppx[x, ph - 1] = (18, 20, 24)
    for y in range(ph):
        ppx[0, y] = (78, 85, 96)
        ppx[pw - 1, y] = (18, 20, 24)
    panel.paste(wordmark, (18, 12), wordmark)
    band.paste(panel, ((960 - pw) // 2, (240 - ph) // 2))
    band.save(os.path.join(MP, "banner-960x240.png"))
    print("banner-960x240")


def bg_tile():
    """Subtle dark dithered tile for the itch page background."""
    random.seed(1911)
    tile = Image.new("RGB", (128, 128), BG)
    px = tile.load()
    for y in range(128):
        for x in range(128):
            r = random.random()
            if r < 0.05:
                px[x, y] = (28, 32, 40)
            elif r < 0.07:
                px[x, y] = (16, 17, 22)
    tile.save(os.path.join(MP, "bg-tile-dark.png"))
    print("bg-tile-dark")


NAMED_SHOTS = {
    "shot_title.png": "menu-title.png",
    "shot_splash1.png": "splash-logo.png",
    "shot_splash2.png": "splash-photo.png",
    "shot_help.png": "sola-1-ballistics.png",
    "shot_help2.png": "sola-2-wind-flag.png",
    "shot_help3.png": "sola-3-skoda-m11.png",
    "shot_help4.png": "sola-4-obice-305.png",
    "shot_banner.png": "round-intro.png",
    "shot_aim.png": "assist-calculator.png",
}

ACTION_COLORS = {(255, 248, 224), (255, 232, 144), (255, 176, 64),
                 (224, 96, 32), (160, 48, 32), (216, 200, 160)}


def screenshots(shot_dirs):
    """Named UI shots from the first run + the most action-packed battle
    frames across all runs, scored by fire/trail pixel count."""
    out = os.path.join(MP, "screenshots")
    for src_name, dst_name in NAMED_SHOTS.items():
        src = os.path.join(shot_dirs[0], src_name)
        if os.path.exists(src):
            shutil.copy(src, os.path.join(out, dst_name))
    flag = os.path.join(ROOT, "docs", "wind_helper.png")
    if os.path.exists(flag):
        shutil.copy(flag, os.path.join(out, "wind-flag-helper.png"))

    scored = []
    for d in shot_dirs:
        for f in glob.glob(os.path.join(d, "shot_battle_*.png")):
            img = Image.open(f).convert("RGB")
            counts = {c: n for n, c in img.getcolors(maxcolors=1 << 20)}
            score = sum(n for c, n in counts.items() if c in ACTION_COLORS)
            scored.append((score, f))
    scored.sort(reverse=True)
    for i, (score, f) in enumerate(scored[:8]):
        shutil.copy(f, os.path.join(out, "gameplay-%02d.png" % (i + 1)))
    print("screenshots: %d named + %d gameplay picks" %
          (len(NAMED_SHOTS), min(8, len(scored))))


def icons():
    for f in glob.glob(os.path.join(ROOT, "assets", "icon", "*")):
        shutil.copy(f, os.path.join(MP, "icons", os.path.basename(f)))
    print("icons copied")


def gameplay_gif(frames_dir):
    """Pixel-perfect GIF: one exact global palette shared by every frame
    (the game world uses well under 256 colors), no dithering, no adaptive
    re-quantization — colors in the GIF are identical to the game's."""
    frames = sorted(glob.glob(os.path.join(frames_dir, "shot_g*.png")))
    if not frames:
        print("no gif frames, skipping")
        return
    imgs = [Image.open(f).convert("RGB") for f in frames]
    colors = set()
    for im in imgs:
        colors.update(c for _, c in im.getcolors(maxcolors=1 << 20))
    assert len(colors) <= 256, "palette overflow: %d colors" % len(colors)
    pal = Image.new("P", (1, 1))
    flat = []
    for c in sorted(colors):
        flat += list(c)
    flat += [0, 0, 0] * (256 - len(colors))
    pal.putpalette(flat)
    q = [im.quantize(palette=pal, dither=Image.Dither.NONE) for im in imgs]
    q[0].save(os.path.join(MP, "gameplay.gif"), save_all=True,
              append_images=q[1:], duration=67, loop=0)
    print("gameplay.gif (%d frames, %d exact colors)" % (len(q), len(colors)))


if __name__ == "__main__":
    for d in ["logos", "screenshots", "icons"]:
        os.makedirs(os.path.join(MP, d), exist_ok=True)
    logo_scales()
    cover()
    banner()
    bg_tile()
    icons()
    if len(sys.argv) > 1:
        screenshots(sys.argv[1:])
        gameplay_gif(sys.argv[1])
    else:
        print("note: pass one or more --shots output dirs for screenshots+gif")
