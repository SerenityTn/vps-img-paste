import AppKit

// Menu-bar app: left-click uploads the clipboard image to the VPS by invoking
// `~/bin/vps-img-paste`; right-click (or Option-click) shows a small menu.
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

    private func symbol(_ name: String) -> NSImage? {
        let img = NSImage(systemSymbolName: name, accessibilityDescription: "VPS Image Paste")
        img?.isTemplate = true
        return img
    }

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
        let up = NSMenuItem(title: "Upload Clipboard Image → VPS",
                            action: #selector(runUpload), keyEquivalent: "")
        up.target = self
        menu.addItem(up)
        menu.addItem(NSMenuItem.separator())
        let quit = NSMenuItem(title: "Quit VPS Image Paste", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        if let button = statusItem.button {
            menu.popUp(positioning: nil,
                       at: NSPoint(x: 0, y: button.bounds.height + 5), in: button)
        }
    }

    @objc private func runUpload() {
        setIcon("arrow.up.circle")          // busy
        let script = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("bin/vps-img-paste").path
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/zsh")
            task.arguments = ["-c", script]
            var ok = false
            do {
                try task.run()
                task.waitUntilExit()
                ok = (task.terminationStatus == 0)
            } catch { ok = false }
            DispatchQueue.main.async { self?.flash(ok ? "checkmark.circle" : "exclamationmark.triangle") }
        }
    }

    private func setIcon(_ name: String) { statusItem.button?.image = symbol(name) }

    private func flash(_ name: String) {
        setIcon(name)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { [weak self] in
            guard let self = self else { return }
            self.setIcon(self.idleSymbol)
        }
    }

    @objc private func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // menu-bar only, no Dock icon
app.run()
