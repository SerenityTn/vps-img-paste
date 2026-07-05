#!/usr/bin/env bash
# Compile the menu-bar app from src/ into ~/Applications/HermesImage.app.
set -euo pipefail
cd "$(dirname "$0")"

APP="${APP_DIR:-$HOME/Applications}/HermesImage.app"
SRC="src/HermesImage.swift"

echo "Building $APP ..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>HermesImage</string>
  <key>CFBundleDisplayName</key><string>Hermes Image</string>
  <key>CFBundleIdentifier</key><string>com.khaireddine.hermesimage</string>
  <key>CFBundleExecutable</key><string>HermesImage</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSUIElement</key><true/>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

swiftc -O -o "$APP/Contents/MacOS/HermesImage" "$SRC" -framework AppKit
codesign --force --sign - "$APP" >/dev/null 2>&1 || true
echo "✓ Built $APP"
