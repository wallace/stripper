#!/usr/bin/env bash
# Builds "Link Stripper.app" (release, ad-hoc signed, not sandboxed) into ./build
# without needing Xcode. The App Store build uses LinkStripper.xcodeproj instead.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
BIN="$(swift build -c release --show-bin-path)/Stripper"

APP="build/Link Stripper.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Stripper"
cp Resources/AppIcon.icns Resources/Assets.xcassets/MenuBarIcon*.imageset/*.png "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key><string>io.github.wallace.stripper</string>
    <key>CFBundleName</key><string>Link Stripper</string>
    <key>CFBundleDisplayName</key><string>Link Stripper</string>
    <key>CFBundleExecutable</key><string>Stripper</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHumanReadableCopyright</key><string></string>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "Built $APP"
