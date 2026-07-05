#!/usr/bin/env bash
# Install vps-img-paste: symlink the script into ~/bin, build the menu-bar app,
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
ln -sf "$REPO/bin/vps-img-paste" "$HOME/bin/vps-img-paste"
chmod +x "$REPO/bin/vps-img-paste"
echo "✓ ~/bin/vps-img-paste -> $REPO/bin/vps-img-paste"

# 3. Seed local config if missing
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/vps-img-paste.env"
if [ ! -f "$CONF" ]; then
  mkdir -p "$(dirname "$CONF")"
  cp "$REPO/vps-img-paste.env.example" "$CONF"
  echo "! Created $CONF — edit it and set VPS_HOST before first use."
else
  echo "✓ Config present: $CONF"
fi

# 4. Build the app
./build.sh

# 5. LaunchAgent (start now + at every login)
PL="$HOME/Library/LaunchAgents/com.khaireddine.vpsimgpaste.plist"
BIN="$HOME/Applications/VpsImgPaste.app/Contents/MacOS/VpsImgPaste"
cat > "$PL" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.khaireddine.vpsimgpaste</string>
  <key>ProgramArguments</key><array><string>$BIN</string></array>
  <key>RunAtLoad</key><true/>
  <key>ProcessType</key><string>Interactive</string>
</dict>
</plist>
PLIST
launchctl unload "$PL" 2>/dev/null || true
launchctl load -w "$PL"
echo "✓ Menu-bar app installed and running (auto-starts at login)."
