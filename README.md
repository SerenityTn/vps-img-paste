# VPS Image Paste

A tiny macOS menu-bar app that sends the image on your clipboard to a remote
host over SSH in one click, then puts the uploaded file's remote path on your
clipboard so you can paste it straight into a terminal / SSH session.

It exists because clipboard **image** paste can't cross an SSH session — the
remote app reads the remote (headless) clipboard, not your Mac's. Pasting
**text** works fine, though, and many CLI/agent tools auto-attach any on-disk
file path they see. So this turns "clipboard image" into "clipboard path".

## Flow

1. Copy an image, or screenshot to clipboard with **⌘⌃⇧4** — *optional*
2. **Click the menu-bar icon** (📷)
3. In your SSH session, **⌘V** the path and send → the tool attaches the image

If there's **no image on the clipboard**, clicking the icon instead captures a
full-screen screenshot of the main display and uploads that (named `shot-*.png`
vs `clip-*.png`). So the icon is always "send what I've got / send what I see".

The icon shows ↑ while uploading, ✓ on success, ⚠️ on failure. Right-click (or
⌥-click) the icon for a menu with **Quit**.

> **Screen Recording permission:** the screenshot fallback needs it. The first
> time it fires, grant it under **System Settings → Privacy & Security → Screen
> Recording** for *VPS Image Paste*. Until then, a screenshot is blank/windowless.

## Install

```sh
git clone <your-repo-url> vps-img-paste
cd vps-img-paste
./install.sh
```

Then edit `~/.config/vps-img-paste.env` and set your host:

```sh
VPS_HOST="user@your-vps-host"      # or an ssh_config alias
VPS_REMOTE_HOME="/home/user"
```

The upload dir (`~/img-uploads` by default) must exist on the host:

```sh
ssh user@your-vps-host 'mkdir -p ~/img-uploads'
```

`install.sh` builds the app into `~/Applications`, symlinks the `vps-img-paste`
CLI into `~/bin`, and registers a LaunchAgent so the app starts at login.

## Components

| Path | What |
|------|------|
| `bin/vps-img-paste` | The upload script (clipboard image → scp → clipboard path). Works standalone in a terminal too. |
| `src/VpsImgPaste.swift` | The AppKit menu-bar app; on click it runs `~/bin/vps-img-paste`. |
| `build.sh` | Compiles the app into `~/Applications/VpsImgPaste.app`. |
| `install.sh` / `uninstall.sh` | Set up / tear down the symlink, app, and LaunchAgent. |
| `vps-img-paste.env.example` | Template for the local (gitignored) config. |

## Requirements

- macOS 13+ (Apple Silicon or Intel)
- Swift toolchain (Xcode Command Line Tools): `xcode-select --install`
- [`pngpaste`](https://github.com/jcsalterego/pngpaste) (installed automatically by `install.sh`)
- SSH key access to the host

## Rebuild after editing

```sh
./build.sh && launchctl kickstart -k gui/$(id -u)/com.khaireddine.vpsimgpaste
```
