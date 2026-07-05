# Hermes Image

A tiny macOS menu-bar app that sends the image on your clipboard to a remote
host (e.g. a [Hermes](https://github.com/) VPS) in one click, then puts the
uploaded file's remote path on your clipboard so you can paste it straight into
a terminal/SSH app.

It exists because clipboard **image** paste can't cross an SSH session — the
remote app reads the remote (headless) clipboard, not your Mac's. Pasting
**text** works fine, though, and Hermes auto-attaches any on-disk file path it
sees. So this turns "clipboard image" into "clipboard path".

## Flow

1. Copy an image, or screenshot to clipboard with **⌘⌃⇧4**
2. **Click the menu-bar icon** (📷)
3. In your SSH/Hermes session, **⌘V** the path and send → the image attaches

The icon shows ↑ while uploading, ✓ on success, ⚠️ on failure. Right-click (or
⌥-click) the icon for a menu with **Quit**.

## Install

```sh
git clone <your-repo-url> hermes-img
cd hermes-img
./install.sh
```

Then edit `~/.config/hermes-img.env` and set your host:

```sh
HERMES_VPS="user@your-vps-host"      # or an ssh_config alias
HERMES_REMOTE_HOME="/home/user"
```

The upload dir (`~/hermes-uploads` by default) must exist on the host:

```sh
ssh user@your-vps-host 'mkdir -p ~/hermes-uploads'
```

`install.sh` builds the app into `~/Applications`, symlinks the `hermes-img`
CLI into `~/bin`, and registers a LaunchAgent so the app starts at login.

## Components

| Path | What |
|------|------|
| `bin/hermes-img` | The upload script (clipboard image → scp → clipboard path). Works standalone in a terminal too. |
| `src/HermesImage.swift` | The AppKit menu-bar app; on click it runs `~/bin/hermes-img`. |
| `build.sh` | Compiles the app into `~/Applications/HermesImage.app`. |
| `install.sh` / `uninstall.sh` | Set up / tear down the symlink, app, and LaunchAgent. |
| `hermes-img.env.example` | Template for the local (gitignored) config. |

## Requirements

- macOS 13+ (Apple Silicon or Intel)
- Swift toolchain (Xcode Command Line Tools): `xcode-select --install`
- [`pngpaste`](https://github.com/jcsalterego/pngpaste) (installed automatically by `install.sh`)
- SSH key access to the host

## Rebuild after editing

```sh
./build.sh && launchctl kickstart -k gui/$(id -u)/com.khaireddine.hermesimage
```
