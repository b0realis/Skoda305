# Changelog

## 1.10.0 — 2026-10-10

One project for every platform: the mobile-touch fork is merged back in,
and game controllers join. The same build plays with a keyboard, a mouse,
a touchscreen or a gamepad.

- Game controllers: D-pad or left stick = angle/power and menu navigation,
  A = fire/confirm, X (or Y) = weapon (tap cycles, hold shows the wind
  flag), LB/RB or triggers = fine adjustment, START = menu. On the title:
  Y = assist, X = hard mode, SELECT = picture toggle. B goes back in SCHOOL
  but never quits the game or abandons a battle. On-screen hints switch
  to button names while a controller is in use, and back on a keypress.
- Touch controls: on touchscreens, VGA-style buttons appear while aiming
  (angle < >, power + -, weapon tap/hold-for-wind, FIRE, MENU). They
  synthesize the same keys the keyboard uses, so precision repeat and
  tap-vs-hold behave identically. They appear after the first touch, so
  keyboard players on touchscreen laptops never see them, and a button
  turns see-through when a gun stands behind it.
- Menus take direct taps — and mouse clicks on desktop: title rows
  (first tap highlights, second confirms), language flags, the
  assist/hard hints, SCHOOL paging (left edge = back), splash skipping,
  round-over banners.
- PICTURE toggle (key S / SELECT, or tap the top-right label on the
  title): SHARP = integer scaling, FULL = fractional, fills the screen.
  Default FULL on touchscreens, SHARP on desktops; persisted.
- English is now the default language (it was Slovenian); a language you
  picked is still remembered.
- Boot picture: the stock Godot logo gives way to a VGA "Powered by
  Godot" scene in the game's dusk palette (also the web loading screen),
  held for 1.5 s so it registers.
- SCHOOL gains a touch-controls page (3/6) — shown only when the touch
  controls are in use; desktops keep the five pages.
- Mobile browsers: Godot's mouse-from-touch emulation is off (it delivered
  every tap twice), and on the web the title tune is re-triggered on the
  first tap (iOS keeps audio locked until a gesture).

Fixes:

- Two keys (or two fingers) at once on the round-over banner awarded the
  round twice and skipped a round number; a double press on the title
  could build two battles. Scene switches now happen exactly once.
- The prescription software could trap itself: its lob correction only
  ever steepened the arc, so after a few dozen shots it fired straight
  up — or backward, away from you — for the rest of the round (~6% of
  rounds). It now always fires toward you, lobs only while it has charge
  to spare, and at full charge and still short it flattens its arc.
- Shell flight no longer depends on the frame rate: 30 and 144 fps used
  to land a few pixels apart, and a stall (hidden browser tab) could
  throw a shot 160 px off. Thin rock spires can no longer be skipped.
- Very quick taps (shorter than a frame) on weapon or power were lost.
- ESC was ignored while the computer aimed.
- Screen shake only ever grew within a round: after one 380KG blast,
  every shot's recoil shook at full strength.
- After firing the last 380KG or SHRAPNEL shell, the empty weapon stayed
  selected and the next fire press only clicked.
- Paging past the last SCHOOL page raised an index error.
- A lone Shift/Alt/Ctrl (e.g. Alt+Tab) flipped SCHOOL pages, skipped the
  splash or dismissed the round-over banner.
- Touch: a key could stay stuck after losing focus mid-hold or lifting
  one of two fingers; the MENU button covered the end of the soldier's
  wind line; German "SCHRAPNELL X2" overflowed the weapon button.
- A wrongly typed value in settings.cfg stopped the other settings from
  loading.
- Text: a missing ";" glyph, the German wind-flag title touching the page
  counter, "RATE OF FIRE" running into its value (now "FIRE RATE").

## 1.9.3 — 2026-07-28

- The soldier's wind estimate moved from the bottom of the screen to the
  top: it docks under the HUD, or under the ballistic calculator panel
  when that is open — so it can never be covered (on mobile, the touch
  buttons occupied its old spot).

## 1.9.2 — 2026-07-27

- The calculator gained an actionable line: under DX it now says
  AIM with an arrow pointing UPWIND by the drift amount — follow
  the green line instead of computing the correction in your head.

## 1.9.1 — 2026-07-27

- Both gunners now read the same angle scale: ANGLE 0 = flat toward your
  enemy, 90 = straight up, on either side of the valley (the right-hand
  player no longer sees mirrored 100-170 values).
- SCHOOL: removed the accent underline that clipped the gun-page titles.

## 1.9.0 — 2026-07-27

- HARD mode (key H on the title, persisted): power is limited to
  the M.11's five historical propellant charges — incremental charges 1-4
  plus a 5th for lighter shells only (the 380KG heavy shell takes at most
  charge 4). Pick the charge, lay the gun with elevation, like a real
  battery. Applies to human players; the HUD shows CHARGE
  instead of POWER.
- New SCHOOL page (3/5): powder and charges — the Ringpulver M.97 story,
  shell weights, velocities and ranges, with the in-game charge ladder
  drawn from the real presets.
- Skoda fact sheet gains POWDER and CHARGES rows.

## 1.8.0 — 2026-07-26

- The game's official title is now **SKODA 305**: the big title changed,
  the front joined the years line ("ISONZO FRONT 1915 - 1917"), and
  "Skoda" left the small subtitle ("30.5CM MORTAR M.11"). Window title,
  desktop entry, bundle id and release filenames follow (skoda-305-*).
- macOS export target (universal binary, unsigned — right-click > Open on
  first launch). Four platforms now build from one command each: Linux,
  Windows, macOS, Web.
- Media package in `media-package/`: itch.io cover and banner, animated
  gameplay GIF, transparent game wordmark and Prescription Games caduceus
  logos (native/@2x/@4x + dark variants, rendered by the game's own font
  and art code), page background tile, curated screenshots, full icon set,
  and a styling README with the palette recipe.

## 1.7.1 — 2026-07-26

- Wind units unified: the soldier now reports both scales — "SOLDIER: WIND
  FROM THE RIGHT AT STRENGTH 8, ABOUT 25 KNOTS" (the exact HUD strength plus
  approximate knots; 1 wind unit = about 3 knots).
- New SCHOOL page (2/4): the TAB flag helper — three live demo flags at
  W = 0 / 3 / 9 with their knot equivalents, and the conversion rule.
  The HUD number is exact; the soldier's knots are an estimate.

## 1.7.0 — 2026-07-26

- Web export target: the game now builds to HTML5/WASM
  (`build/web-build/`, packaged as a ready-to-upload itch.io zip).
  Exported single-threaded so it runs on itch.io with no special embed
  settings. Web builds hide the quit option (a tab cannot close itself)
  and skip the native window icon.
- Renderer pinned to Compatibility (WebGL/OpenGL) on every platform —
  required for the web, and the right fit for a 2D pixel game everywhere.

## 1.6.5 — 2026-07-26

- Licensed under MIT (code, generated assets, docs; the period photographs
  are public domain).
- Series lore made official in the codebase: the computer opponent is the
  "prescription software" (Rx) — `src/ai.gd` is now `src/prescription.gd`
  and every reference follows. The word "AI" no longer appears in this
  series.
- Design system documented in `docs/VGA-design.md`, now including full
  SFX & music design and the period-photograph treatment for historical
  games.

## 1.6.4 — 2026-07-18

- The HUD wind gauge bar now ends in an arrowhead pointing downwind, so
  direction reads instantly even at a glance.

## 1.6.3 — 2026-07-18

- Wind indicators are now truly proportional. The HUD text-arrows were
  replaced by an analog gauge: a centered bar that fills downwind 1 px per
  wind unit, green/amber/red by severity, with the number alongside. The
  TAB flag now lifts with the wind — sagging near-vertical in a light
  breeze, stiff and horizontal in a gale — on top of the existing
  strength-scaled flutter.

## 1.6.2 — 2026-07-18

- Wind fix: the drifting wind no longer camps at maximum strength on one
  side. The old clamped random walk was "sticky" at +-9 (about 20% of all
  turns were spent at full gale); the walk now reflects off the bounds and
  strong winds tend to ease toward calm (~3% at max, sides balanced).
  Diagnosed and tuned with the new `tools/wind_sim.gd`.

## 1.6.1 — 2026-07-18

- Title screen: the controls hint moved up a few pixels to give the
  ASSIST (P) line some breathing room.

## 1.6.0 — 2026-07-18

- SCHOOL is now a three-page manual: the ballistics page plus two weapon fact
  sheets — the Skoda 30.5cm M.11 and the Obice da 305/17, each with a
  period photograph in VGA sepia and specifications sourced from reference
  works (caliber, weight, shells, muzzle velocity, range, elevation, rate
  of fire, crew, service year). Left/right to flip pages, Esc to leave.
- Title screen: the Santa Lucia photograph sits a little lower.

## 1.5.2 — 2026-07-18

- The ballistics manual in the menu is now called SCHOOL — ASSIST
  at the bottom of the title screen refers to the calculator assist.

## 1.5.1 — 2026-07-18

- Trajectory trails are now per player: while aiming you faintly see your
  OWN previous shot's arc (not your opponent's), and your new shot draws at
  full strength over it.
- Gun visibility: the Austro-Hungarian mortar is now dark gunmetal and the
  Italian Obice a clear green, so both stand out against rock and sky.

## 1.5.0 — 2026-07-18

- Last-shot feedback in the assist calculator: after you fire, the panel
  shows your previous shot's forecast drift (PREDICTED) next to the drift the
  shell actually picked up in flight (MEASURED, integrated during the flight,
  so it includes dispersion, gusts and early mountain impacts). The gap
  between the two numbers is the dispersion and the changing wind — read it
  and walk your fire in.

## 1.4.0 — 2026-07-18

- Assist mode ("ASSIST", key P on the title screen, persisted): the advanced
  ballistic calculator. While aiming, a live panel computes flight time and
  the exact wind drift (DX = 2*W*T^2) for your current power, angle and
  selected weapon — how many pixels left/right of the no-wind impact the
  shell will land. Human turns only; the prescription software never
  peeks at it.

## 1.3.0 — 2026-07-18

- New HELP screen in the menu: a field-manual page on wind and ballistics —
  trajectory diagram plotted live from the game's own equations (calm vs
  W=8 arcs, drift bracket, animated shell), the formulas with the real
  constants, and a plain-words summary. Localized in all four languages.
- Removed the falling-shell whistle sound.

## 1.2.0 — 2026-07-18

- Wind now drifts every shot (with occasional gusts) and shells have a small
  per-shot dispersion — no firing solution can be repeated pixel-perfect.
- Power keys are precise: a tap moves exactly 1 unit, holding repeats slowly
  and then accelerates (Shift still halves the rate).
- Hold TAB for the wind helper: a signal flag above your gun flutters
  downwind (harder wind = wilder flutter) and your soldier calls out an
  estimate at the bottom ("wind from the left at N knots" — an estimate,
  not gospel). A short TAB tap still cycles the weapon, on release.

## 1.1.1 — 2026-07-18

- Game icon art: pixel M.11 silhouette against a dithered sepia sky
  (`tools/make_icon.py`; full PNG size set + Windows .ico in `assets/icon/`
  for reuse).
- Linux icon integration: window/taskbar icon set at runtime, and the
  release zip ships a `.desktop` entry + `install.sh` for an app-menu
  entry with the icon.

## 1.1.0 — 2026-07-18

- Boot splash sequence: Prescription Games caduceus logo + the 1916 LOC
  photograph of the Skoda 305 mm M.11 in clean 32-shade VGA sepia
  (whole photo, pillarboxed, no dithering).
- Original title tune: melancholic A-minor march (square lead, march bass,
  noise snare), plus a splash sting.
- Italy now fields its own gun: the Obice da 305 (tall A-frame mount,
  longer barrel) instead of a recolored Skoda.
- Localization: English, Slovenian, German, Italian — flag selector on the
  title screen, choice persisted.
- Version shown on the title screen.

## 1.0.0 — 2026-07-18

- Initial release: Scorched Earth clone on the Isonzo Front. VGA 320×200,
  destructible alpine terrain, wind, three weapons, 1P vs the computer or hotseat,
  first to 3 rounds. All art generated in code, 8-bit generated SFX.
