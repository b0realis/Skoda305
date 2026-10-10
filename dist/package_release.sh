#!/usr/bin/env bash
## Release packages — what a player unpacks and runs:
##   Skoda305-<version>-linux64.zip              Linux x86-64
##   Skoda305-<version>-raspberry-pi5-arm64.zip  Raspberry Pi 5 / 64-bit ARM Linux
##   Skoda305-<version>-windows64.zip            Windows x86-64
##   Skoda305-<version>-macos.zip                macOS (universal, unsigned)
##   Skoda305-<version>-web.zip                  browser build, index.html at
##                                               the root (itch.io: Kind = HTML)
## plus SHA256SUMS, in build/release-<version>/. Exports every preset with
## Godot 4.7, plays one headless match with the x86-64 build (the autotest)
## as a smoke test, and ships the engine's licence + third-party notices
## next to the game (Godot is MIT, and so is this game).
## Usage: dist/package_release.sh   (override the engine with GODOT=/path)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT:-$(command -v godot4 || command -v godot \
	|| ls "$ROOT"/../godot/Godot_v4*_linux.x86_64 2>/dev/null | tail -1 || true)}"
[ -n "$GODOT" ] && [ -x "$GODOT" ] || { echo "Godot 4.7 not found: set GODOT=/path" >&2; exit 1; }
VERSION="$(sed -n 's/^config\/version="\(.*\)"$/\1/p' "$ROOT/project.godot")"
[ -n "$VERSION" ] || { echo "no config/version in project.godot" >&2; exit 1; }
OUT="$ROOT/build/release-$VERSION"
EXP="$OUT/export"
rm -rf "${OUT:?}"
mkdir -p "$EXP/web"
# build/ sits inside the project: Godot must never import (and then pack)
# its own exported files
touch "$ROOT/build/.gdignore"
# A throwaway profile: notices and the smoke match never touch the
# player's own settings.
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
run_sandboxed() { XDG_DATA_HOME="$SANDBOX/data" XDG_CONFIG_HOME="$SANDBOX/config" \
	XDG_CACHE_HOME="$SANDBOX/cache" "$@"; }

echo "== SKODA 305 $VERSION — exporting with $("$GODOT" --version)"
"$GODOT" --headless --path "$ROOT" --import >/dev/null 2>&1 || true
export_preset() {  # export_preset <preset> <file> <log-tag>
	"$GODOT" --headless --path "$ROOT" --export-release "$1" "$2" >"$OUT/export-$3.log" 2>&1
}
export_preset "Linux" "$EXP/skoda-305-linux-x86_64" linux64
export_preset "Linux ARM64" "$EXP/skoda-305-linux-arm64" arm64
export_preset "Windows" "$EXP/skoda-305-windows-x86_64.exe" windows64
export_preset "macOS" "$EXP/skoda-305-macos.zip" macos
export_preset "Web" "$EXP/web/index.html" web
file "$EXP/skoda-305-linux-x86_64" | grep -q "x86-64" || { echo "x86-64 export missing/wrong" >&2; exit 1; }
file "$EXP/skoda-305-linux-arm64" | grep -q "aarch64" || { echo "arm64 export missing/wrong" >&2; exit 1; }
file "$EXP/skoda-305-windows-x86_64.exe" | grep -q "PE32+" || { echo "windows export missing/wrong" >&2; exit 1; }
unzip -l "$EXP/skoda-305-macos.zip" | grep -q "Skoda 305.app/Contents/MacOS/" || { echo "macOS export missing/wrong" >&2; exit 1; }
for f in index.html index.wasm index.pck index.js; do
	[ -s "$EXP/web/$f" ] || { echo "web export lacks $f" >&2; exit 1; }
done
for b in skoda-305-linux-x86_64 skoda-305-linux-arm64 skoda-305-windows-x86_64.exe; do
	[ "$(stat -c %s "$EXP/$b")" -gt 20000000 ] || { echo "$b too small — PCK not embedded?" >&2; exit 1; }
done

# The engine's licence + every bundled third-party component, from the
# very engine that exported the binaries.
run_sandboxed "$GODOT" --headless --path "$ROOT" --script res://dist/godot_notices.gd \
	-- "$EXP/THIRD_PARTY_NOTICES.txt" >/dev/null 2>&1
[ -s "$EXP/THIRD_PARTY_NOTICES.txt" ] || { echo "notices not written" >&2; exit 1; }

# Smoke test: the exported x86-64 game plays a whole headless match.
set +e
run_sandboxed timeout 300 "$EXP/skoda-305-linux-x86_64" --headless -- --autotest \
	>"$OUT/smoke-linux64.log" 2>&1
set -e
grep -q "MATCH OVER" "$OUT/smoke-linux64.log" \
	|| { echo "x86-64 smoke match did not finish, see $OUT/smoke-linux64.log" >&2; exit 1; }
if grep -q "SCRIPT ERROR" "$OUT/smoke-linux64.log"; then
	echo "x86-64 smoke match logged script errors, see $OUT/smoke-linux64.log" >&2; exit 1
fi

CONTROLS='CONTROLS
  Keyboard  LEFT/RIGHT angle, UP/DOWN powder charge, SHIFT fine,
            TAB tap = cycle weapon, TAB hold = wind flag + soldier,
            SPACE/ENTER fire, ESC menu.
            On the title: P assist calculator, H hard mode (historical
            charges), S picture (sharp/full), arrows + ENTER, flags = language.
  Gamepad   D-pad / left stick angle + power, A fire, X tap = weapon,
            X hold = wind flag, LB/RB fine, START menu.
            On the title: Y assist, X hard mode, SELECT picture, B back (SOLA).
  Touch     on-screen buttons appear while aiming once you touch the screen.
  SOLA      the field manual on the title screen explains wind, charges
            and both guns.'

LICENCE='LICENCE
  SKODA 305 is free software under the MIT licence (LICENSE). It runs on
  the Godot Engine (MIT): the engine'"'"'s licence and its third-party
  notices are in THIRD_PARTY_NOTICES.txt. The period photographs are
  WWI-era works in the public domain. The boot picture is a pixel-art
  rendition of the Godot Engine mascot; the Godot logo is by Andrea
  Calabro, licensed CC BY 4.0.'

readme() {  # readme <stage> <platform> <start-text>
	cat >"$1/README.txt" <<README
SKODA 305 $VERSION — $2
A minimal Scorched Earth clone on the WWI Isonzo Front (Soska fronta):
the Skoda 30.5 cm M.11 siege mortar against the Obice da 305, in VGA
320x200. One player against the computer, or two on one machine.
Source code: https://github.com/b0realis/Skoda305

START
$3

$CONTROLS

$LICENCE
README
}

stage_common() {  # stage_common <stage>
	cp "$ROOT/LICENSE" "$1/LICENSE"
	cp "$ROOT/CHANGELOG.md" "$1/CHANGELOG.md"
	cp "$EXP/THIRD_PARTY_NOTICES.txt" "$1/THIRD_PARTY_NOTICES.txt"
}

linux_package() {  # linux_package <platform> <binary> <start-text> <run.sh body>
	local name="Skoda305-$VERSION-$1"
	local stage="$OUT/$name"
	mkdir -p "$stage"
	cp -p "$EXP/$2" "$stage/$2"
	chmod +x "$stage/$2"
	stage_common "$stage"
	cp "$ROOT/assets/icon/moznar-m11-256.png" "$stage/skoda-305.png"
	cp "$ROOT/dist/skoda-305.desktop" "$stage/skoda-305.desktop"
	cp "$ROOT/dist/install.sh" "$stage/install.sh"
	chmod +x "$stage/install.sh"
	printf '%s\n' "$4" >"$stage/run.sh"
	chmod +x "$stage/run.sh"
	readme "$stage" "$1" "$3"
	(cd "$OUT" && zip -qr -X "$name.zip" "$name")
	echo "ok: $name.zip ($(du -h "$OUT/$name.zip" | cut -f1))"
}

linux_package linux64 skoda-305-linux-x86_64 \
'  Linux x86-64. Extract the folder anywhere and run ./run.sh (or the
  binary directly). sh install.sh copies the game to ~/.local and adds it
  to your application menu (no root needed). Needs OpenGL 3.3 or
  OpenGL ES 3.0 graphics drivers.' \
'#!/bin/sh
# SKODA 305 launcher (Linux x86-64).
set -eu
cd -- "$(dirname -- "$0")"
exec ./skoda-305-linux-x86_64 "$@"'

linux_package raspberry-pi5-arm64 skoda-305-linux-arm64 \
'  Raspberry Pi 5 (or newer 64-bit ARM Linux): use a 64-bit desktop OS
  such as Raspberry Pi OS (64-bit) with its standard graphics drivers.
  Extract the folder and run ./run.sh from the desktop session — it runs
  on OpenGL ES 3. sh install.sh adds it to the application menu.
  If needed: chmod +x run.sh skoda-305-linux-arm64
  Not a 32-bit build. Built and checked as an ARM64 export; not yet
  played on a Pi in hand.' \
'#!/bin/sh
# Raspberry Pi 5 launcher: OpenGL ES 3 (the Pi 5 offers desktop OpenGL
# 3.1, below the 3.3 Godot asks for first).
set -eu
cd -- "$(dirname -- "$0")"
exec ./skoda-305-linux-arm64 --rendering-driver opengl3_es "$@"'

# Windows: one .exe
name="Skoda305-$VERSION-windows64"
stage="$OUT/$name"
mkdir -p "$stage"
cp -p "$EXP/skoda-305-windows-x86_64.exe" "$stage/"
stage_common "$stage"
readme "$stage" windows64 \
'  Windows 10/11, 64-bit. Extract the folder and run
  skoda-305-windows-x86_64.exe. The build is not code-signed: if
  SmartScreen warns, choose "More info" > "Run anyway".'
(cd "$OUT" && zip -qr -X "$name.zip" "$name")
echo "ok: $name.zip ($(du -h "$OUT/$name.zip" | cut -f1))"

# macOS: the .app (universal: Apple silicon + Intel), unsigned
name="Skoda305-$VERSION-macos"
stage="$OUT/$name"
mkdir -p "$stage"
(cd "$stage" && unzip -q "$EXP/skoda-305-macos.zip")
stage_common "$stage"
readme "$stage" macos \
'  macOS 10.13 or newer (universal: Apple silicon and Intel). Extract and
  move "Skoda 305.app" to Applications. The app is not signed: on the
  first launch right-click it and choose Open (or run
  xattr -dr com.apple.quarantine "Skoda 305.app").'
(cd "$OUT" && zip -qry -X "$name.zip" "$name")
echo "ok: $name.zip ($(du -h "$OUT/$name.zip" | cut -f1))"

# Web: index.html at the zip root, ready for itch.io
name="Skoda305-$VERSION-web"
cp "$ROOT/LICENSE" "$EXP/THIRD_PARTY_NOTICES.txt" "$EXP/web/"
(cd "$EXP/web" && zip -qr -X "$OUT/$name.zip" .)
echo "ok: $name.zip ($(du -h "$OUT/$name.zip" | cut -f1))"

(cd "$OUT" && sha256sum Skoda305-"$VERSION"-*.zip >SHA256SUMS)
echo "== done: $OUT"
cat "$OUT/SHA256SUMS"
