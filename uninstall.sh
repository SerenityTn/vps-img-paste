#!/usr/bin/env bash
# Remove the menu-bar app, LaunchAgent, and ~/bin symlink.
# Leaves your ~/.config/hermes-img.env untouched.
set -euo pipefail

PL="$HOME/Library/LaunchAgents/com.khaireddine.hermesimage.plist"
launchctl unload "$PL" 2>/dev/null || true
rm -f "$PL"
pkill -f "HermesImage.app/Contents/MacOS/HermesImage" 2>/dev/null || true
rm -rf "$HOME/Applications/HermesImage.app"
[ -L "$HOME/bin/hermes-img" ] && rm -f "$HOME/bin/hermes-img"
echo "✓ Uninstalled. (Config at ~/.config/hermes-img.env kept — delete it manually if you want.)"
