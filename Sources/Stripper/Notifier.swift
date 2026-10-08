import Foundation
import StripperCore
import UserNotifications

/// Posts an optional banner when a link is cleaned.
@MainActor
final class Notifier {
    private var center: UNUserNotificationCenter? {
        // UNUserNotificationCenter crashes outside an app bundle (e.g. `swift run`).
        Bundle.main.bundleIdentifier == nil ? nil : .current()
    }

    func requestAuthorization(completion: @escaping @MainActor (Bool) -> Void) {
        guard let center else { return completion(false) }
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            Task { @MainActor in completion(granted) }
        }
    }

    func notify(_ result: CleanResult) {
        guard let center else { return }
        let content = UNMutableNotificationContent()
        content.title = "Link cleaned"
        let n = result.removedParameters.count
        content.subtitle = "Removed \(n) tracking parameter\(n == 1 ? "" : "s"): "
            + result.removedParameters.joined(separator: ", ")
        content.body = result.cleaned
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request)
    }
}
