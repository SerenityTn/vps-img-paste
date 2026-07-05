#!/usr/bin/env bash
# Remove the menu-bar app, LaunchAgent, and ~/bin symlink.
# Leaves your ~/.config/vps-img-paste.env untouched.
set -euo pipefail

PL="$HOME/Library/LaunchAgents/com.khaireddine.vpsimgpaste.plist"
launchctl unload "$PL" 2>/dev/null || true
rm -f "$PL"
pkill -f "VpsImgPaste.app/Contents/MacOS/VpsImgPaste" 2>/dev/null || true
rm -rf "$HOME/Applications/VpsImgPaste.app"
[ -L "$HOME/bin/vps-img-paste" ] && rm -f "$HOME/bin/vps-img-paste"
echo "✓ Uninstalled. (Config at ~/.config/vps-img-paste.env kept — delete it manually if you want.)"
