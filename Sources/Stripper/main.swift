import AppKit
import ServiceManagement
import StripperCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private enum Keys {
        static let enabled = "enabled"
        static let notifications = "notificationsEnabled"
    }

    private let defaults = UserDefaults.standard
    private let monitor = ClipboardMonitor()
    private let notifier = Notifier()
    private var statusItem: NSStatusItem!
    private var cleanedCount = 0
    private var lastResult: CleanResult?
    private var icon: NSImage?
    private var flashIcon: NSImage?
    private var flashEnd: DispatchWorkItem?

    private let enabledItem = NSMenuItem(title: "Clean Copied Links", action: #selector(toggleEnabled), keyEquivalent: "")
    private let notifyItem = NSMenuItem(title: "Show Notifications", action: #selector(toggleNotifications), keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
    private let statsItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let lastItem = NSMenuItem(title: "", action: #selector(copyOriginal), keyEquivalent: "")
    private let accessItem = NSMenuItem(title: "", action: #selector(explainClipboardAccess), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        defaults.register(defaults: [Keys.enabled: true, Keys.notifications: false])

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // Banana glyph from the app bundle; falls back to an SF Symbol under `swift run`.
        icon = NSImage(named: "MenuBarIcon")
            ?? NSImage(systemSymbolName: "link.badge.plus", accessibilityDescription: nil)
        icon?.isTemplate = true
        icon?.accessibilityDescription = "Link Stripper"
        flashIcon = NSImage(named: "MenuBarIconColor")
        flashIcon?.accessibilityDescription = "Link Stripper: link cleaned"
        statusItem.button?.image = icon
        buildMenu()

        monitor.isEnabled = defaults.bool(forKey: Keys.enabled)
        monitor.onClean = { [weak self] result in self?.handle(result) }
        monitor.start()
        refreshMenu()
    }

    private func buildMenu() {
        let menu = NSMenu()
        statsItem.isEnabled = false
        lastItem.isHidden = true
        accessItem.isHidden = true
        for item in [enabledItem, notifyItem, loginItem, lastItem, accessItem] { item.target = self }
        menu.addItem(statsItem)
        menu.addItem(lastItem)
        menu.addItem(accessItem)
        menu.addItem(.separator())
        menu.addItem(enabledItem)
        menu.addItem(notifyItem)
        menu.addItem(loginItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Link Stripper", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        menu.delegate = self
        statusItem.menu = menu
    }

    private func refreshMenu() {
        enabledItem.state = monitor.isEnabled ? .on : .off
        notifyItem.state = defaults.bool(forKey: Keys.notifications) ? .on : .off
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        statsItem.title = "Links cleaned this session: \(cleanedCount)"
        statusItem.button?.appearsDisabled = !monitor.isEnabled
        if #available(macOS 15.4, *) {
            // macOS asks before apps read what other apps copied. Surface it when
            // we're not on "Allow", since cleaning depends on it.
            switch NSPasteboard.general.accessBehavior {
            case .alwaysDeny:
                accessItem.title = "⚠︎ Clipboard Access Blocked…"
                accessItem.isHidden = false
            case .ask:
                accessItem.title = "Stop Clipboard Prompts…"
                accessItem.isHidden = false
            default:
                accessItem.isHidden = true
            }
        }
        if let lastResult {
            lastItem.isHidden = false
            lastItem.title = "Copy Last Original Link"
            lastItem.toolTip = lastResult.original
        }
    }

    private func handle(_ result: CleanResult) {
        cleanedCount += 1
        lastResult = result
        refreshMenu()
        flashMenuBarIcon()
        if defaults.bool(forKey: Keys.notifications) {
            notifier.notify(result)
        }
    }

    /// Shows the full-colour banana for a moment as feedback that a link was cleaned.
    private func flashMenuBarIcon() {
        guard let flashIcon, let button = statusItem.button else { return }
        flashEnd?.cancel()
        button.image = flashIcon
        let end = DispatchWorkItem { [weak self] in self?.statusItem.button?.image = self?.icon }
        flashEnd = end
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: end)
    }

    @objc private func toggleEnabled() {
        monitor.isEnabled.toggle()
        defaults.set(monitor.isEnabled, forKey: Keys.enabled)
        refreshMenu()
    }

    @objc private func toggleNotifications() {
        if defaults.bool(forKey: Keys.notifications) {
            defaults.set(false, forKey: Keys.notifications)
            refreshMenu()
            return
        }
        notifier.requestAuthorization { [weak self] granted in
            guard let self else { return }
            self.defaults.set(granted, forKey: Keys.notifications)
            if !granted { self.showNotificationsDeniedAlert() }
            self.refreshMenu()
        }
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSAlert(error: error).runModal()
        }
        refreshMenu()
    }

    /// Escape hatch for when the tracking-free link doesn't work: put the
    /// original back without it being cleaned again.
    @objc private func copyOriginal() {
        guard let lastResult else { return }
        let wasEnabled = monitor.isEnabled
        monitor.isEnabled = false
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(lastResult.original, forType: .string)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.monitor.isEnabled = wasEnabled
        }
    }

    @objc private func explainClipboardAccess() {
        let alert = NSAlert()
        alert.messageText = "Let Link Stripper read copied links"
        alert.informativeText = """
            macOS asks before an app reads what you copy in other apps. To clean links \
            without being asked each time, set Link Stripper to Allow in System Settings › \
            Privacy & Security › Paste from Other Apps.

            Link Stripper only reads the clipboard when it holds a web link, and nothing \
            ever leaves your Mac.
            """
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate()
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Pasteboard") {
            NSWorkspace.shared.open(url)
        }
    }

    private func showNotificationsDeniedAlert() {
        let alert = NSAlert()
        alert.messageText = "Notifications are turned off for Link Stripper"
        alert.informativeText = "Turn them on in System Settings › Notifications › Link Stripper."
        alert.runModal()
    }
}

extension AppDelegate: NSMenuDelegate {
    // Clipboard access can change in System Settings while we run.
    func menuWillOpen(_ menu: NSMenu) { refreshMenu() }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
