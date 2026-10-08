#!/usr/bin/env bash
# Regenerates the app icon (AppIcon.svg -> AppIcon.icns) and the menu bar glyph
# (MenuBarIcon.svg -> MenuBarIcon.png, @2x) from Resources/banana.py.
# Requires rsvg-convert (brew install librsvg). The generated files are
# committed, so this is only needed after changing the drawing.
set -euo pipefail
cd "$(dirname "$0")"

BANANA_ARGS="-10 36 0.50 0.40"
python3 banana.py $BANANA_ARGS > AppIcon.svg
python3 banana.py $BANANA_ARGS --menubar > MenuBarIcon.svg

ICONSET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
    rsvg-convert -w $size -h $size AppIcon.svg -o "$ICONSET/icon_${size}x${size}.png"
    rsvg-convert -w $((size * 2)) -h $((size * 2)) AppIcon.svg -o "$ICONSET/icon_${size}x${size}@2x.png"
done
iconutil -c icns "$ICONSET" -o AppIcon.icns
echo "Wrote Resources/AppIcon.icns"

# Menu bar glyph: 18pt tall, used as a template image so macOS tints it.
rsvg-convert -h 18 MenuBarIcon.svg -o MenuBarIcon.png
rsvg-convert -h 36 MenuBarIcon.svg -o MenuBarIcon@2x.png
echo "Wrote Resources/MenuBarIcon.png, MenuBarIcon@2x.png"
