#!/usr/bin/env bash
# Regenerates the app icon and the menu bar glyphs from Resources/banana.py:
#   - Assets.xcassets (used by the Xcode / App Store build)
#   - AppIcon.icns (used by build-app.sh)
# Requires rsvg-convert (brew install librsvg). The generated files are
# committed, so this is only needed after changing the drawing.
set -euo pipefail
cd "$(dirname "$0")"

BANANA_ARGS="-10 36 0.50 0.40"
python3 banana.py $BANANA_ARGS > AppIcon.svg
python3 banana.py $BANANA_ARGS --menubar > MenuBarIcon.svg
python3 banana.py $BANANA_ARGS --menubar-color > MenuBarIconColor.svg

ICONSET=Assets.xcassets/AppIcon.appiconset
for size in 16 32 128 256 512; do
    rsvg-convert -w $size -h $size AppIcon.svg -o "$ICONSET/icon_${size}x${size}.png"
    rsvg-convert -w $((size * 2)) -h $((size * 2)) AppIcon.svg -o "$ICONSET/icon_${size}x${size}@2x.png"
done
TMP="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$TMP" && cp "$ICONSET"/*.png "$TMP/"
iconutil -c icns "$TMP" -o AppIcon.icns

# Menu bar glyphs are 18pt tall. MenuBarIcon is a template image (macOS tints
# it); MenuBarIconColor is shown briefly when a link is cleaned.
for name in MenuBarIcon MenuBarIconColor; do
    rsvg-convert -h 18 $name.svg -o Assets.xcassets/$name.imageset/$name.png
    rsvg-convert -h 36 $name.svg -o Assets.xcassets/$name.imageset/$name@2x.png
done
echo "Wrote Resources/Assets.xcassets and Resources/AppIcon.icns"
