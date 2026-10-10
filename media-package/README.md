# Media package — Skoda 305: Isonzo Front

Press/store assets for itch.io and elsewhere. Everything is generated from
the game's own code (`tools/media.tscn` renders the logos with the in-game
pixel font and caduceus art; `tools/make_media.py` composes the rest), so
the kit can always be regenerated pixel-identical.

## Contents

| Asset | Use |
|---|---|
| `cover-630x500.png` | itch.io cover image (their recommended 630×500) |
| `banner-960x240.png` | page header / social banner |
| `gameplay.gif` | animated gameplay loop (640×400) with an **exact shared palette** — colors are pixel-identical to the game; put it first in the screenshot rail |
| `bg-tile-dark.png` | tiling page *background texture* (128×128, deliberately near-black with sparse dither specks — it sits behind the page, not in it) |
| `logos/logo-game-wordmark*.png` | game wordmark, transparent, native/@2x/@4x + dark-plate variant |
| `logos/logo-prescription-games*.png` | studio caduceus logo, same variants |
| `screenshots/gameplay-01..08.png` | eight in-game battle moments, auto-picked by action score (explosions, trails) |
| `screenshots/menu-title.png` etc. | named UI shots: title, both splashes, the SCHOOL pages, round intro, assist calculator, wind-flag helper |
| `icons/` | full icon set 16–512 px + multi-size `.ico` |

## itch.io page styling recipe

Match the game's palette in the itch theme editor:

- **Background**: `#14161C` (or upload `bg-tile-dark.png` as a tiled
  background image, screenshots-behind disabled)
- **Text**: `#C8C0A8`  · **Headers**: `#E4D8AC`
- **Links / buttons**: `#D2504A` (A-H red) or `#4E9A50` (Italy green)
- **Banner**: `banner-960x240.png` at the top of the page body
- Screenshot rail order: `gameplay.gif`, `gameplay-01..03`, `menu-title`,
  `wind-flag-helper`, `assist-calculator`, `sola-3-skoda-m11` — lead with
  motion, end with depth.
- Font: itch's monospace option pairs best with the pixel look.

## Rules for use (from VGA-design.md)

Only scale these assets by **integer factors with nearest-neighbor** —
never smooth-resize pixel art. Don't recolor the logos; the gold caduceus
and amber wordmark are canon. The photographs inside screenshots are
WWI-era public domain; everything else is MIT like the code.
