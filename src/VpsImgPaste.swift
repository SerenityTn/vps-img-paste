import AppKit

private struct Upload { let name: String; let size: Int }

// Menu-bar app. Left-click uploads the clipboard image (or a screenshot) via
// `~/bin/vps-img-paste`; right-click (or Option-click) opens a menu to browse
// and clean the images already uploaded to the VPS.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let idleSymbol = "photo.on.rectangle.angled"

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = symbol(idleSymbol)
            button.action = #selector(handleClick(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "VPS Image Paste — click to upload the clipboard image to the VPS"
        }
    }

    // MARK: - Click routing

    @objc private func handleClick(_ sender: Any?) {
        guard let event = NSApp.currentEvent else { runUpload(); return }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.option) {
            showMenu()
        } else {
            runUpload()
        }
    }

    private func showMenu() {
        let menu = NSMenu()

        let up = NSMenuItem(title: "Upload Clipboard Image / Screenshot → VPS",
                            action: #selector(runUpload), keyEquivalent: "")
        up.target = self
        menu.addItem(up)

        let region = NSMenuItem(title: "Capture Region → VPS…",
                                action: #selector(runCapture(_:)), keyEquivalent: "")
        region.target = self
        region.representedObject = "region"
        menu.addItem(region)

        let full = NSMenuItem(title: "Capture Full Screen → VPS",
                              action: #selector(runCapture(_:)), keyEquivalent: "")
        full.target = self
        full.representedObject = "full"
        menu.addItem(full)

        menu.addItem(.separator())

        // Uploaded-images section (queried live from the VPS).
        let (uploads, ok) = listUploads()
        let header = NSMenuItem(title: uploadsTitle(uploads, ok), action: nil, keyEquivalent: "")
        let sub = NSMenu()
        if !ok {
            sub.addItem(disabled("VPS unreachable"))
        } else if uploads.isEmpty {
            sub.addItem(disabled("No uploads"))
        } else {
            for u in uploads {
                let it = NSMenuItem(title: "\(u.name)   (\(humanSize(u.size)))",
                                    action: #selector(openImage(_:)), keyEquivalent: "")
                it.target = self
                it.representedObject = u.name
                sub.addItem(it)
            }
        }
        header.submenu = sub
        menu.addItem(header)

        if ok && !uploads.isEmpty {
            let clean = NSMenuItem(title: "Clean All Uploads (\(uploads.count))…",
                                   action: #selector(cleanUploads), keyEquivalent: "")
            clean.target = self
            menu.addItem(clean)
        }

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit VPS Image Paste", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        if let button = statusItem.button {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 5), in: button)
        }
    }

    // MARK: - Actions

    @objc private func runUpload() {
        setIcon("arrow.up.circle")
        runScriptAsync([]) { [weak self] ok in
            self?.flash(ok ? "checkmark.circle" : "exclamationmark.triangle")
        }
    }

    @objc private func runCapture(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? String else { return }
        setIcon("camera")
        runScriptAsync([mode]) { [weak self] ok in
            self?.flash(ok ? "checkmark.circle" : "exclamationmark.triangle")
        }
    }

    @objc private func openImage(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let (out, status) = self.runScriptSync(["fetch", name])
            let path = out.trimmingCharacters(in: .whitespacesAndNewlines)
            DispatchQueue.main.async {
                if status == 0, !path.isEmpty {
                    NSWorkspace.shared.open(URL(fileURLWithPath: path))
                } else {
                    self.flash("exclamationmark.triangle")
                }
            }
        }
    }

    @objc private func cleanUploads() {
        let alert = NSAlert()
        alert.messageText = "Delete all uploaded images on the VPS?"
        alert.informativeText = "This permanently removes every uploaded image from the remote folder."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        setIcon("trash")
        runScriptAsync(["clean"]) { [weak self] ok in
            self?.flash(ok ? "checkmark.circle" : "exclamationmark.triangle")
        }
    }

    @objc private func quit() { NSApp.terminate(nil) }

    // MARK: - Script bridge

    private func scriptPath() -> String {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser.path
        let candidates = [
            ProcessInfo.processInfo.environment["VPS_IMG_PASTE_BIN"],  // explicit override
            "/opt/homebrew/bin/vps-img-paste",                          // Homebrew (Apple Silicon)
            "/usr/local/bin/vps-img-paste",                             // Homebrew (Intel)
            "\(home)/bin/vps-img-paste",                                // install.sh symlink
        ].compactMap { $0 }
        for c in candidates where fm.isExecutableFile(atPath: c) { return c }
        return candidates.last ?? "\(home)/bin/vps-img-paste"
    }

    private func runScriptSync(_ args: [String]) -> (String, Int32) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: scriptPath())
        task.arguments = args
        let out = Pipe()
        task.standardOutput = out
        task.standardError = Pipe()
        do { try task.run() } catch { return ("", 127) }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        return (String(data: data, encoding: .utf8) ?? "", task.terminationStatus)
    }

    private func runScriptAsync(_ args: [String], onDone: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let task = Process()
            task.executableURL = URL(fileURLWithPath: self.scriptPath())
            task.arguments = args
            var ok = false
            do { try task.run(); task.waitUntilExit(); ok = task.terminationStatus == 0 } catch { ok = false }
            DispatchQueue.main.async { onDone(ok) }
        }
    }

    private func listUploads() -> ([Upload], Bool) {
        let (out, status) = runScriptSync(["list"])
        if status != 0 { return ([], false) }
        var files: [Upload] = []
        for line in out.split(separator: "\n") {
            let parts = line.split(separator: "\t", maxSplits: 1)
            if parts.count == 2, let sz = Int(parts[0]) {
                files.append(Upload(name: String(parts[1]), size: sz))
            }
        }
        return (files, true)
    }

    // MARK: - Helpers

    private func symbol(_ name: String) -> NSImage? {
        let img = NSImage(systemSymbolName: name, accessibilityDescription: "VPS Image Paste")
        img?.isTemplate = true
        return img
    }

    private func setIcon(_ name: String) { statusItem.button?.image = symbol(name) }

    private func flash(_ name: String) {
        setIcon(name)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { [weak self] in
            guard let self = self else { return }
            self.setIcon(self.idleSymbol)
        }
    }

    private func disabled(_ title: String) -> NSMenuItem {
        let m = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        m.isEnabled = false
        return m
    }

    private func humanSize(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    private func uploadsTitle(_ uploads: [Upload], _ ok: Bool) -> String {
        guard ok else { return "Uploaded Images" }
        if uploads.isEmpty { return "Uploaded Images (0)" }
        let total = uploads.reduce(0) { $0 + $1.size }
        return "Uploaded Images (\(uploads.count), \(humanSize(total)))"
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // menu-bar only, no Dock icon
app.run()
