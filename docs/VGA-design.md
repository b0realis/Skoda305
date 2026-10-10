# VGA-design.md — The Design System

The visual, audio and interaction design of *Možnar M.11 — Soška fronta*,
recorded as a reusable design system for further retro games in the series.
Companion to `VGA-PLAYBOOK.md` (which covers the engineering *how*; this
document is the *what and why*).

---

## 1. Identity

**A playable postcard from 1994 about 1916.** The game looks like a DOS 6.22
production found on a shareware CD, about a real place and real machines,
made with obvious affection for both eras.

Three pillars — test every new element against them:

1. **VGA authenticity** — if a 1994 DOS game couldn't have rendered it, we
   don't render it. No anti-aliasing, no alpha gradients, no sub-pixel
   anything, no smooth easing curves.
2. **Historical sincerity** — real guns, real places, verified numbers,
   period photographs. The game never invents history; it pixelates it.
3. **Readable minimalism** — few systems, every one legible at a glance.
   If the player must squint or re-read, the design failed, not the player.

## 2. Canvas

- **320 × 200**, integer-scaled. Everything designed at native size and
  judged at native size first; a thing that only reads when scaled up is
  wrong.
- **HUD band**: top 14 px, two 5-px text rows with 1 px bevels. The world
  owns rows 14–199.
- **Footer conventions**: instructional text lives in the bottom ~28 px;
  the very last row (y 193) is reserved for corner status (assist hint
  bottom-left, version bottom-right).
- Center-critical content sits at x=160; screen corners hold meta info.

## 3. Palette

One fixed palette, warm-grey biased, low saturation everywhere except
deliberate accents. Roles, not colors, are the unit of design:

| Role | Swatches (hex) | Notes |
|---|---|---|
| Sky gradient | `6e6a78 8a8078 a69684 c2ae94 dcc8a8 eedebc` | dark violet-grey up top → cream horizon; always Bayer-dithered between bands |
| Sun / clouds | `f4e8c8` / `d8ccb4` | sun gets a dithered halo |
| Far / near ridges | `8a8496`+snow `cfceda` / `6f6a7c`+snow `c4c4ce` | background silhouettes, cooler and lighter than playable terrain |
| Terrain rock | `9a8e7c 786c5c 5a5044 423a30 2e2820` | surface → depth ramp, per-pixel hash speckle |
| Snow / grass | `e6e6ee c6c8d6` / `6a7048 565c3c` | snow above the snowline, war-worn olive in valleys |
| Scorch | `201a14` | crater rims, burnt debris |
| Fire ramp | `ffffff ffe890 ffb040 e06020 a03020` | explosion phases, muzzle flash |
| Smoke | `9a9490 6e6a66` | rising, slow |
| UI steel | bg `23262c`, bevel `4e5560`/`121418` | every panel |
| UI text | amber `e4d8ac`, bone `e8e4dc`, dim `8a8578` | amber = interactive/important, bone = data, dim = labels |
| Team accents | A-H red `d2504a`, Italy green `4e9a50` | names, ribbons, page accents |
| Gun bodies | A-H gunmetal `22262c 3a4048 5c646e`; Italy green `2c4426 48703c 6ca05a` | tuned for contrast against BOTH rock and sky |
| Status colors | good `4e9a50`, warn `d8a838`, bad `c03830` | HP bars and the wind gauge share the same severity language |
| Sepia photo ramp | 5 stops `201a14 423a30 786c5c c2ae94 eedebc`, interpolated to 32 | all period photographs |

Rules:
- Nothing pure black or white in the world; only UI extremes approach them.
- A hue may appear only through its ramp. New element → assign it a ramp.
- Sprites must contrast with **every** background they can appear against
  (we repainted both guns after they melted into the ridges).

## 4. Light & atmosphere

- Light comes from the sky: surfaces lighten toward their top row, depth
  darkens by band. No cast shadows — depth is done with value ramps.
- Distance = lighter and bluer (ridge layers), never blurring.
- Dust, haze and mood come from dithering density, not transparency.
- Film grain (random ±1 px flicker at ~5% alpha) belongs to the title
  screen only — it frames the game as an old reel, then gets out of the way.

## 5. Typography

- One 5-px, variable-width, uppercase pixel font. Three sizes only:
  ×1 body, ×2 headers/banners, ×3 the game title.
- **Everything uppercase, no diacritics** in any language (CP437 conceit);
  German uses OE/UE, Slovene drops carons. This is a feature, not a debt.
- Text over the world always carries a 1-px dark drop shadow; text inside
  panels never does.
- Hierarchy by color before size: amber → bone → dim (see palette roles).
- Numbers align with their units ("380 KG", "17.6 KM"); formulas render in
  the same font as prose — the manual should feel typed, not typeset.

## 6. Screen anatomy

**Boot ritual** (any key skips): black screen → gold caduceus logo with
studio name and a fake "(C) 1994" → full-bleed sepia period photograph with
a caption bar. Logo fades with ordered dither; the photograph cuts in clean
(dither dots over a photo read as dirt).

**Title**: three vertical zones. Left — the "archive photo" in a museum
plate (white inner frame, dark outer, caption beneath). Right — the menu
column with blinking `>` cursor, language flags in a bordered row. Center
top — subtitle / big title / years, with status lines (victor, assist)
beneath. Bottom — two control-hint lines, then the corner row. The backdrop
is the same sky+ridge painter the battle uses: one world, one look.

**Battle**: layer order sky → terrain → own-trail (dimmed 55%) → guns →
particles/shells → HUD (unshaken) → helper overlays. The HUD band:
team names with accent colors and active-player marker, HP bars, round and
score center, aim numbers row two, weapon center, wind gauge right.

**Banners/dialogs**: centered steel panel, 1-px light top/left and dark
bottom/right bevel, ×2 amber headline, ×1 lines, blinking press-key prompt
(0.8 s cycle). Used identically for round intro, round end, victory.

**ŠOLA (manual)**: page counter top-right, nav hint bottom. Page 1 —
diagram plotted live from the game's real equations, formulas in-font,
plain-words summary. Pages 2+ — fact sheets: photo plate left, label:value
table right (labels dim, values bone), team-color accent under the title.

## 7. UI components

- **Panel**: steel bg + bevel, 3–4 px padding. Never rounded.
- **HP bar**: 26×3 px fill in a dark frame, severity-colored.
- **Wind gauge**: 21×5 px bar, center tick, fill grows downwind 1 px per
  unit and tapers into an arrowhead; severity-colored; number alongside.
  *Design rule generalized: analog quantities get analog pixels — exactly
  one pixel per unit, direction shown by the shape itself.*
- **Signal flag** (helper): pole + red/white pennant; angle interpolates
  hanging→horizontal with strength, flutter amplitude and speed scale with
  it. The indicator *behaves* like the thing it measures.
- **Flags (language)**: 12×9, procedural; add a distinguishing mark when
  two flags would collide at that size.
- **Blink cadences**: 0.5 s menu cursor, 0.8 s prompts. Nothing else blinks.
- **Touch buttons** (mobile builds): steel panels in the standard bevel,
  ≥ 24 px (~8 mm on a phone), pressed state = inverted bevel + darker
  fill; laid along the bottom edge in thumb clusters (angle left, power
  right, weapon + FIRE center, MENU tucked under the HUD). They appear
  only on touch devices — desktop players never see them.

## 8. Motion & feedback vocabulary

| Event | Feedback |
|---|---|
| Fire | muzzle flash (0.12 s, fire ramp), 1–2 px recoil, dust puff, boom |
| Shell flight | 2–3 px hot pixel + 1-px trail written into the own-trail layer |
| Impact | expanding fire-ramp circle, debris pixels (radial, gravity), smoke risers, screen shake scaled to crater, terrain collapse |
| Gun death | big crater + destroy rumble + long shake |
| Turn hand-off | beep (pitch per side), trail layer swap, HUD marker moves |
| Menu action | click (move) / beep (confirm), slight pitch variation |

- Shake is the world container jittering ±1–2 px; the HUD never shakes.
- All particles are 1–2 px palette rects with gravity; lifetimes under 2.5 s.
- Transitions between screens are cuts or dither fades — never slides,
  never zooms.

## 9. Audio design: SFX & music

**The signature**: 22 kHz mono, everything normalized, soft-clipped and
quantized to 8-bit levels — the "Sound Blaster crunch". Sounds are short,
dry and low-fi; music and effects run through the same master chain so the
whole game speaks from one imaginary speaker.

### SFX catalogue (design intent per sound)

| Sound | Recipe | Intent |
|---|---|---|
| shot | pitch-diving sine (~165→55 Hz) + fast noise burst | a punch you feel, not a bang you hear |
| boom1 / boom2 | lowpassed noise decay + low sine rumble (52 / 40 Hz) | small shell vs 380 kg — size lives in the lows and the length |
| destroy | 2.3 s noise + 38 Hz rumble + random crackle spikes | a gun's death should linger |
| thud | short low sweep + soft noise | a fall is bodily, not explosive |
| click / beep | 30/70 ms square blips (900 / 660 Hz) | UI grammar: click = move, beep = confirm/turn |
| sting | slow minor arpeggio, long decay | studio splash — calm before the war |
| win | rising square arpeggio | the only bright sound in the game, earned once per match |

Usage rules:
- Every play gets **±8% random pitch** — kills repetition fatigue for free.
- UI sounds duck to −4…−8 dB; world sounds own the headroom.
- 8-voice round-robin pool so overlapping booms never cut each other off.
- **The whistle lesson**: any sound that fires every turn must earn its
  place forever. The falling-shell whistle was atmospheric for ten shots
  and irritating for the rest — removed. Silence before impact is stronger.

### Music design

- **Title screen only.** Battle is scored by wind, booms and silence — that
  restraint *is* the drama, and it is period-true (DOS games rarely played
  music in-game).
- Series brief: an **original** composition, minor key, lament progression
  (here Am–G–F–E), march meter ~92 BPM, ~20 s seamless loop.
- Three voices: square lead (25% duty, light 5–6 Hz vibrato, per-note
  decay), root–fifth march bass, noise snare on beats 2 and 4.
- Melody as two 4-bar phrases — question and answer; second pass varied.
- Mood target: **dignified melancholy**, never heroics. If it could play
  over a military parade, rewrite it; it should play over a faded photo.
- The splash sting reuses the tonic chord of the theme, so the boot ritual
  and title feel composed together.

## 10. Interaction & UX rules

1. **Precision inputs are discrete**: tap = exactly 1 unit; hold = delay,
   slow repeat, then fast; Shift halves. Continuous drift frustrates.
2. **Tap vs hold on one key**: act on release-below-threshold (tap cycles
   weapon) so holding for the helper never mutates state.
3. **Helpers are opt-in, honest and private**: assist is a title-screen
   toggle (persisted); the calculator computes from the real constants;
   measured feedback is integrated from the actual flight; nothing a
   player's helper shows leaks to the opponent (own trail, own feedback,
   human-turns-only panels). The prescription software never reads player
   helpers.
4. **Teach with the truth**: the manual plots the same equations the game
   integrates; the calculator's forecast is later compared against the
   measured outcome (NAPOVED vs MERITEV) — the gap *is* the lesson.
5. **In-fiction voice**: help arrives as a soldier's spoken estimate, a
   signal flag, a field manual — never as a modern tooltip.
6. **Fairness through randomness done right**: environment drifts each turn
   (with gusts), shots disperse slightly, and random walks must be checked
   for sticky bounds (reflect, ease extremes) — verified with histogram
   sims, not vibes.
7. **State the action, not the measurement**: a helper that reports "drift
   95 px left" is a puzzle; one that adds "AIM 95 px right" in green is a
   tool. If the player must invert your number, print the inverted number.
8. **Numbers face the player**: displayed scales are symmetric from each
   player's point of view (elevation 0 = toward the enemy on both sides),
   even when internal representations differ. Presentation-layer mirrors,
   never physics changes.
9. **Difficulty is a historical constraint, not a penalty**: hard mode is
   the gun's five real propellant charges, not fuzzier aim or less HP.
   The harder game should teach more, not punish more.
10. **Overlays dock, screens have territories**: helpers stack off each
    other's edges (soldier line under the calculator, calculator under
    the HUD); the top of the screen is for information, the bottom for
    terrain — and on touch devices, for thumbs. Two-step confirmation
    (select, then activate) protects dense menus from fat fingers.

## 11. Historical & cultural design

- Factions get their real equipment (Škoda 30.5 cm M.11 vs Obice da
  305/17), silhouettes distinct enough to identify at 14 px.
- All specifications verified against references before they ship.
- Photographs: see §12 — the full period-photograph treatment.
- Four languages (EN/SL/DE/IT) as first-class citizens; Slovene themes and
  places carry the identity (Soška fronta, Sv. Lucija, Doberdob...).
- Gentle humor lives in the frame, not the subject: the fake "(C) 1994",
  "Prescription Games" — the war itself is treated with respect.
- **Naming conventions**: the studio is *Prescription Games*; the computer
  opponent is the *prescription software* (short: **Rx**) — in fiction,
  code and docs alike. The word "AI" does not exist in this series.

## 12. Period photographs (the historical-game treatment)

Nothing sells "about 1916" like the actual 1916. Photographs are the
game's anchor to reality — treated as archive material, never as decoration.

**Sourcing**
- Era-appropriate photographs in the **public domain** (Library of
  Congress, Wikimedia Commons, national archives, heritage societies).
- Stock-agency scans of PD-era photographs are usable — a faithful
  reproduction of a public-domain work gains no new rights — but crop away
  watermark bars; tiled watermarks dissolve completely at VGA scale
  (~176 px wide, 32 shades).
- Choose photos that answer a player's question: *what did this machine /
  place / crew actually look like?* If a photo is merely pretty, skip it.

**One conversion, one look** (all photos share it):
grayscale → crop to subject → LANCZOS resize to target (≤176 px wide
in-page, fit-to-height for splash) → autocontrast (1% clip) → 0.4 px blur
→ quantize to the 5-stop sepia ramp interpolated to **32 shades, no
dithering** → pillarbox on black when the whole frame matters.
Error-diffusion dithering is banned on photos: the speckle reads as dirt.

**Three presentation patterns**
1. **Full-bleed splash** — the photograph as a held title card, black
   caption bar beneath. Cuts in clean (no dither fade over photos).
2. **Museum plate** — white inner frame, dark outer border, caption below;
   used on the title screen. Reads as a mounted archive print.
3. **Fact-sheet plate** — photo left, label:value specification table
   right; the encyclopedia page pattern (ŠOLA).

**Captions** — always: place + date or a plain factual statement
("SV. LUCIJA, 1916", "KARNIJA: OGENJ NA MALBORGHETTO"), localized, small
dim text. A photo without a caption is decoration; with one, it is a
document.

**Casting** — one photo per moment: the splash shows the machine at war;
the title shows the human crew at work; the manual shows identification
views. No repeats.

**Respect** — no dead, no wounded, no mockery. The sepia pixelation acts
as a veil of reverence: recognizable, dignified, unmistakably past.

## 13. Anti-patterns (they break the spell)

- Anti-aliasing, alpha gradients, smooth tweens, particles with soft edges.
- Half-pixel positions (text smears), non-integer scaling.
- Floyd–Steinberg dithering on photographs (speckle reads as dirt).
- Off-palette colors, saturated large areas, pure black/white in the world.
- Sprites that share a value range with their background.
- Modern UI affordances: tooltips, hover states, rounded corners, drop
  shadows other than the 1-px text shadow.
- Helpers that are always-on, or that reveal the opponent's information.
- Sounds that outstay repetition (the whistle lesson).

## 14. Reusing this system for the next game

1. Keep: canvas, typography, UI components, motion vocabulary, audio
   identity, UX rules, boot ritual, banner/dialog spec, blink cadences.
2. Re-theme: palette ramps (new sky, new terrain materials), team accents,
   sprites, backdrop painter, photographs, captions, music key/tempo.
3. Re-verify: sprite contrast on every background; widest-language layout;
   any new random process (histogram it); every screen judged at native
   320×200.
4. The three pillars (§1) arbitrate every argument. When in doubt: would
   the 1994 shareware version have done it? Then do that.
