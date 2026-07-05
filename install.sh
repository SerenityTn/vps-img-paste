#!/usr/bin/env bash
# Install hermes-img: symlink the script into ~/bin, build the menu-bar app,
# and register it to launch at login. Idempotent.
set -euo pipefail
cd "$(dirname "$0")"
REPO="$(pwd)"

# 1. Dependency check
if ! command -v /opt/homebrew/bin/pngpaste >/dev/null 2>&1 && ! command -v pngpaste >/dev/null 2>&1; then
  echo "→ Installing pngpaste (needed to read clipboard images)…"
  brew install pngpaste
fi

# 2. Symlink the CLI into ~/bin
mkdir -p "$HOME/bin"
ln -sf "$REPO/bin/hermes-img" "$HOME/bin/hermes-img"
chmod +x "$REPO/bin/hermes-img"
echo "✓ ~/bin/hermes-img -> $REPO/bin/hermes-img"

# 3. Seed local config if missing
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/hermes-img.env"
if [ ! -f "$CONF" ]; then
  mkdir -p "$(dirname "$CONF")"
  cp "$REPO/hermes-img.env.example" "$CONF"
  echo "! Created $CONF — edit it and set HERMES_VPS before first use."
else
  echo "✓ Config present: $CONF"
fi

# 4. Build the app
./build.sh

# 5. LaunchAgent (start now + at every login)
PL="$HOME/Library/LaunchAgents/com.khaireddine.hermesimage.plist"
BIN="$HOME/Applications/HermesImage.app/Contents/MacOS/HermesImage"
cat > "$PL" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.khaireddine.hermesimage</string>
  <key>ProgramArguments</key><array><string>$BIN</string></array>
  <key>RunAtLoad</key><true/>
  <key>ProcessType</key><string>Interactive</string>
</dict>
</plist>
PLIST
launchctl unload "$PL" 2>/dev/null || true
launchctl load -w "$PL"
echo "✓ Menu-bar app installed and running (auto-starts at login)."
