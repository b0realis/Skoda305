# Skoda 305 — Isonzo Front

A minimal **Scorched Earth** clone set on the WWI Isonzo Front.
Austria-Hungary fields the **Skoda 30.5 cm Mörser M.11** siege
mortar, Italy answers with the **Obice da 305**. Minimal design, minimal
features, maximal fun. Official title: **Skoda 305**.

![Title](docs/title.png)
![Battle](docs/battle.png)
![Splash](docs/splash_photo.png)

## Download

Ready-to-run packages are on the
[Releases page](https://github.com/b0realis/Skoda305/releases):
**Linux x86-64**, **Raspberry Pi 5** (64-bit ARM, OpenGL ES 3),
**Windows**, **macOS** (universal, unsigned) and a **web** build (the zip
for itch.io). Unpack and run; each package has a README.txt with the
controls. Build them yourself with `dist/package_release.sh` (Godot 4.7
and its export templates).

## Run

Open the project in **Godot 4.7** and press Play (or `godot --path .`).
No plugins, no imported art packs — every sprite, font, flag and background is
generated in code; the only binary assets are generated WAVs, the converted
1916 LOC photograph and the "Powered by Godot" boot picture. Boot sequence:
the VGA "Powered by Godot" picture (while the engine loads) → Prescription
Games caduceus splash → the archive photo splash → title (any key skips).

## Game

- **1 PLAYER** — you (Austria-Hungary) against the prescription software (Italy).
- **2 PLAYERS** — hotseat duel, taking turns on one keyboard.
- First to **3 rounds** wins the war.
- **Languages**: English (the default), Slovenian, German, Italian — pick
  the flag on the title screen (arrow keys on the language row); the choice
  is remembered.
- **School**: a five-page field manual — how wind bends the
  trajectory (diagram plotted from the game's real equations, formulas
  included), the wind flag, powder charges, plus fact sheets for both guns
  with period photographs and historical specifications. On touchscreens a
  sixth page (3/6) explains the touch controls.
- **Hard mode** (key `H` on the title screen): power is restricted to the
  M.11's five historical propellant charges (1-4, plus a 5th for light
  shells only) — pick a charge and lay the gun with elevation, like a real
  battery. See SCHOOL page 3 for the history.
- **Assist** (key `P` on the title screen): toggles the advanced ballistic
  calculator — a live panel while aiming that computes flight time and the
  exact wind drift in pixels for your current settings, plus last-shot
  feedback: forecast drift vs the drift your shell really picked up. Saved
  between runs.
- **Picture** (key `S` / SELECT, or tap the top-right label on the title):
  SHARP = integer scaling, pixel-perfect with borders; FULL = fractional,
  fills the screen. Defaults to FULL on touchscreens, SHARP on desktops;
  saved between runs.

Turn-based artillery: set angle and power, mind the **wind**, and lob shells
over the ridge. The wind drifts every shot (gusts included) and every shell
scatters slightly — repeat fire never lands twice in the same hole. Terrain
is fully destructible — craters collapse, and a gun whose ground is blown
away falls and takes damage.

### Controls

| Key | Action |
|---|---|
| ← / → | barrel angle (`ANGLE`) |
| ↑ / ↓ | powder charge (`POWER`) |
| Shift | fine adjustment |
| Tab (tap) | cycle weapon (`WEAPON`) |
| Tab (hold) | wind helper: signal flag + soldier's estimate |
| Space / Enter | fire (`FIRE`) |
| Esc | back to menu / quit |

### Touch controls

On a touchscreen (phones, tablets, touch laptops) VGA-style buttons appear
while you aim, from your first touch on — they press the same keys the
keyboard does, so everything behaves identically. Keyboard players never
see them; the mouse can click the menus. A button turns see-through when
a gun stands behind it.

![Touch controls](docs/touch_controls.png)

| Button | Action |
|---|---|
| < / > (hold) | barrel angle |
| + / - (hold) | powder charge, auto-repeat |
| weapon (tap / hold) | cycle weapon / wind flag |
| FIRE | fire |
| MENU | back to menu |

Menus: the first tap highlights a row, the second confirms (rows are only
~3.6 mm tall on a phone). SCHOOL: tap the left edge = back, anywhere else =
forward. Splash and round-over banners: tap anywhere.

### Game controllers

Any gamepad works (Xbox names; other pads by position — bottom face
button = A). Like touch, the controller presses the keyboard's keys, and
the on-screen hints switch to button names while you use it.

| Button | Battle | Title / SCHOOL |
|---|---|---|
| D-pad / left stick | angle, power | navigate, pages |
| A | fire | confirm / next |
| X (tap / hold) | cycle weapon / wind flag | title: hard mode |
| Y | same as X | title: assist |
| LB / RB, triggers | fine adjustment | — |
| START | menu | confirm |
| SELECT | — | title: picture toggle |
| B | — | SCHOOL: back |

B never quits the game or abandons a battle (use START for the menu).

### Weapons

| | crater | damage | ammo/round |
|---|---|---|---|
| SHELL | small | 32 | ∞ |
| 380KG | huge | 65 | 2 |
| SHRAPNEL | 5 bomblets | 16 each | 2 |

## Style

DOS 6.22 / VGA mood, Bitmap Brothers reference: native **320×200** viewport,
integer-scaled to the window (or fractionally filled, see Picture), fixed palette, ordered (Bayer) dithering in the
sky and in the splash fades, chunky 5-px pixel font. All UI text avoids
diacritics — CP437 had no carons (or umlauts) either. The title-screen
"photograph" is painted in code after the wartime photo of an M.11 being
assembled at Santa Lucia on the Isonzo; the boot splash uses the Library of
Congress "War of the Nations" photo (public domain, 1919) quantized to a
16-shade sepia palette. The title tune is an original melancholic march in
A minor (square-wave lead, march bass, noise snare), generated to WAV.

## Build

`export_presets.cfg` ships Linux (x86-64 and ARM64 for the Raspberry Pi 5),
Windows, macOS and Web presets (desktop builds are single-file binaries
with the PCK embedded). With export templates installed:

```sh
godot --headless --path . --export-release "Linux"
godot --headless --path . --export-release "Linux ARM64"   # Raspberry Pi 5
godot --headless --path . --export-release "Windows"
godot --headless --path . --export-release "macOS"
godot --headless --path . --export-release "Web"
```

Outputs land in `build/`. Current version: see `CHANGELOG.md`.
The macOS app is unsigned: on first launch, right-click the app and choose
*Open* (or clear the quarantine flag with `xattr -dr com.apple.quarantine`).
Store/press assets live in `media-package/` (see its README for the
itch.io styling recipe).

### Play online (itch.io)

The project uses the **Compatibility (WebGL) renderer** and the Web preset
exports **single-threaded** (no thread support), so it needs no
cross-origin-isolation headers — it runs on itch.io out of the box:

1. Zip the *contents* of `build/web-build/` (`index.html` at the zip root)
   — `dist/package_release.sh` produces
   `build/release-<version>/Skoda305-<version>-web.zip` ready to upload.
2. On itch.io: project *Kind* = **HTML**, upload the zip and tick
   *"This file will be played in the browser"*.
3. Embed: viewport **1280 × 800** (or 960 × 600), enable the
   *Fullscreen button* and tick **Mobile friendly** — the same build serves
   desktop and phone browsers (iPhone Safari has no fullscreen API, so
   "Mobile friendly" is what gives phones the full-window view). No
   SharedArrayBuffer toggle needed.
4. Browsers unlock audio on the first keypress or tap — the title tune
   starts as soon as the player touches a key or the screen (on iOS the
   tune is re-triggered on the first tap; the iPhone's ring/silent switch
   also mutes web audio).

To test locally: `cd build/web-build && python3 -m http.server 8000`, then
open `http://localhost:8000`.

## Development

Two reusable guides for this and future VGA-style games in the series:

- [docs/VGA-design.md](docs/VGA-design.md) — the design system: identity
  pillars, palette roles, screen anatomy, UI components, motion and audio
  vocabulary, UX rules, anti-patterns.
- [docs/VGA-PLAYBOOK.md](docs/VGA-PLAYBOOK.md) — the engineering playbook:
  rendering rules, dithering toolkit, generated art/audio pipelines, dev
  harnesses, release ritual, gotchas ledger.

- `tools/gen_sfx.py` — regenerates all sound effects (Python 3, stdlib only).
- `tools/gen_music.py` — regenerates the title tune.
- `tools/make_splash_photo.py` — rebuilds the VGA splash photo (needs Pillow;
  downloads the source from Wikimedia Commons if not given a file).
- `godot --headless --path . -- --autotest` — smoke-test match in the
  console, the prescription software playing both sides (~2 s);
  `--matches=150` plays a batch for statistics (Rx behavior, errors).
- `godot --headless --path . res://tools/text_check.tscn` — every
  localized string against the pixel font: missing glyphs, text wider
  than its slot (screen, buttons, 2x titles, fact-sheet labels).
- `SHOT_DIR=/tmp godot --path . -- --shots` — muted Rx demo that saves
  screenshots.
- `-- --touchui` — forces the touch layer on a desktop (testing the touch
  SCHOOL page and menus; battle buttons only show for human players).

Mechanics referenced from the classic *Scorched Earth* (and the
[donovani/scorched-earth](https://gitlab.com/donovani/scorched-earth)
restoration project); all code here is original. Historical background:
[Battles of the Isonzo](https://en.wikipedia.org/wiki/Battles_of_the_Isonzo).

## License

Code, generated assets and documentation: [MIT](LICENSE).
The period photographs are WWI-era works in the public domain.
The boot picture is a pixel-art rendition of the Godot Engine mascot; the
Godot logo is by Andrea Calabró, licensed
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
