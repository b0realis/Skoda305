#!/bin/sh
# Install Skoda 305 into ~/.local (binary, icon, app-menu entry).
# Run from the unpacked release folder:  sh install.sh
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"

# the one game binary in this folder: x86_64 or arm64 (Raspberry Pi 5)
BIN=""
for f in "$DIR"/skoda-305-linux-*; do
	[ -f "$f" ] && BIN="$(basename "$f")"
done
if [ -z "$BIN" ]; then
	echo "No skoda-305-linux-* binary next to install.sh" >&2
	exit 1
fi

mkdir -p "$HOME/.local/bin" \
	"$HOME/.local/share/applications" \
	"$HOME/.local/share/icons/hicolor/256x256/apps"

cp "$DIR/$BIN" "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/$BIN"
cp "$DIR/skoda-305.png" "$HOME/.local/share/icons/hicolor/256x256/apps/skoda-305.png"
# Raspberry Pi 5: OpenGL ES 3 (its desktop OpenGL 3.1 is below Godot's 3.3)
FLAGS=""
case "$BIN" in
	*arm64) FLAGS=" --rendering-driver opengl3_es" ;;
esac
sed "s|^Exec=.*|Exec=$HOME/.local/bin/$BIN$FLAGS|" \
	"$DIR/skoda-305.desktop" > "$HOME/.local/share/applications/skoda-305.desktop"

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
gtk-update-icon-cache "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
echo "Installed. Look for 'Skoda 305' in your application menu."
