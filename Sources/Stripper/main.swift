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

    private let enabledItem = NSMenuItem(title: "Clean Copied Links", action: #selector(toggleEnabled), keyEquivalent: "")
    private let notifyItem = NSMenuItem(title: "Show Notifications", action: #selector(toggleNotifications), keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
    private let statsItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let lastItem = NSMenuItem(title: "", action: #selector(copyOriginal), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        defaults.register(defaults: [Keys.enabled: true, Keys.notifications: false])

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // Banana glyph from the app bundle; falls back to an SF Symbol under `swift run`.
        let icon = NSImage(named: "MenuBarIcon")
            ?? NSImage(systemSymbolName: "link.badge.plus", accessibilityDescription: nil)
        icon?.isTemplate = true
        icon?.accessibilityDescription = "Stripper"
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
        for item in [enabledItem, notifyItem, loginItem, lastItem] { item.target = self }
        menu.addItem(statsItem)
        menu.addItem(lastItem)
        menu.addItem(.separator())
        menu.addItem(enabledItem)
        menu.addItem(notifyItem)
        menu.addItem(loginItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Stripper", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func refreshMenu() {
        enabledItem.state = monitor.isEnabled ? .on : .off
        notifyItem.state = defaults.bool(forKey: Keys.notifications) ? .on : .off
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        statsItem.title = "Links cleaned this session: \(cleanedCount)"
        statusItem.button?.appearsDisabled = !monitor.isEnabled
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
        if defaults.bool(forKey: Keys.notifications) {
            notifier.notify(result)
        }
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

    private func showNotificationsDeniedAlert() {
        let alert = NSAlert()
        alert.messageText = "Notifications are turned off for Stripper"
        alert.informativeText = "Enable them in System Settings › Notifications › Stripper."
        alert.runModal()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
