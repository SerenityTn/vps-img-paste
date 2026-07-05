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

If there's **no image on the clipboard**, clicking the icon instead lets you
**drag to select a screen region** to upload (set `VPS_SHOT_MODE=full` for a
whole-display grab). The right-click menu also has explicit **Capture Region →
VPS…** and **Capture Full Screen → VPS** items. Screenshots are named
`shot-*.png` vs `clip-*.png`.

The app only ever acts on an icon click — it has no global hotkey and does not
watch the clipboard, so your normal keyboard-shortcut screenshots/copies are
never touched. After an upload it puts the VPS path on the clipboard for the
⌘V-into-SSH step, then **restores your previous clipboard** (image or text)
after a grace window (`VPS_CLIP_RESTORE_SECONDS`, default 60s) so the link never
lingers to be pasted into a Mac app by mistake.

The icon shows ↑ while uploading, ✓ on success, ⚠️ on failure.

**Right-click** (or ⌥-click) the icon for a menu that also lets you manage what's
on the VPS:

- **Uploaded Images (N, size)** — submenu listing every image currently on the
  host; click one to download and open it in Preview.
- **Clean All Uploads (N)…** — deletes every uploaded image on the host (with a
  confirmation).
- **Quit**.

The same operations are available from the CLI:

```sh
vps-img-paste            # upload clipboard image / screenshot
vps-img-paste list       # SIZE<TAB>NAME per uploaded image, newest first
vps-img-paste fetch NAME # download NAME to a temp file, print its path
vps-img-paste clean      # delete all uploaded images on the host
```

> **Screen Recording permission:** the screenshot fallback needs it. The first
> time it fires, grant it under **System Settings → Privacy & Security → Screen
> Recording** for *VPS Image Paste*. Until then, a screenshot is blank/windowless.

## Install (Homebrew)

```sh
brew install SerenityTn/tap/vps-img-paste
```

Then configure your host and start the menu-bar app:

```sh
mkdir -p ~/.config
cp "$(brew --prefix)/share/vps-img-paste/vps-img-paste.env.example" ~/.config/vps-img-paste.env
$EDITOR ~/.config/vps-img-paste.env          # set VPS_HOST / VPS_REMOTE_HOME

ssh user@your-vps-host 'mkdir -p ~/img-uploads'   # create the upload dir
brew services start vps-img-paste             # run now + at login
```

Upgrade later with `brew upgrade vps-img-paste`.

### Install from source (no Homebrew)

```sh
git clone https://github.com/SerenityTn/vps-img-paste
cd vps-img-paste
./install.sh          # builds app to ~/Applications, symlinks CLI to ~/bin, login agent
$EDITOR ~/.config/vps-img-paste.env
```

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
