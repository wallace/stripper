import Foundation

/// The outcome of cleaning a URL that contained tracking parameters.
public struct CleanResult: Equatable, Sendable {
    public let original: String
    public let cleaned: String
    /// Names of the query parameters that were removed, in original order.
    public let removedParameters: [String]
}

/// Validates a string as a plain web link and strips identifying/tracking
/// query parameters from it.
///
/// Only `http`/`https` links are handled: these are the links a browser
/// follows with a GET request, where the query string is part of the address
/// and safe to edit. Anything else (mailto:, file:, custom schemes, javascript:,
/// arbitrary text) is rejected. No network request is ever made.
public struct URLCleaner: Sendable {
    public var rules: TrackingRules

    public init(rules: TrackingRules = .default) {
        self.rules = rules
    }

    /// Returns a cleaned link, or `nil` if the input is not a valid web URL or
    /// contains nothing to strip.
    public func clean(_ input: String) -> CleanResult? {
        guard let components = Self.validatedComponents(from: input),
              let host = components.host?.lowercased(),
              let items = components.percentEncodedQueryItems, !items.isEmpty
        else { return nil }

        var kept: [URLQueryItem] = []
        var removed: [String] = []
        for item in items {
            if rules.shouldStrip(parameter: item.name.removingPercentEncoding ?? item.name, host: host) {
                removed.append(item.name)
            } else {
                kept.append(item)
            }
        }
        guard !removed.isEmpty else { return nil }

        var cleanedComponents = components
        cleanedComponents.percentEncodedQueryItems = kept.isEmpty ? nil : kept
        guard let cleaned = cleanedComponents.string,
              Self.validatedComponents(from: cleaned) != nil
        else { return nil }

        let original = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return CleanResult(original: original, cleaned: cleaned, removedParameters: removed)
    }

    /// Parses and validates `input` as an absolute http(s) URL.
    ///
    /// The whole (trimmed) string must be a single URL — text that merely
    /// contains a link is left alone so we never rewrite prose the user copied.
    public static func validatedComponents(from input: String) -> URLComponents? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed.count <= 8192,
              trimmed.rangeOfCharacter(from: .whitespacesAndNewlines) == nil,
              let components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = components.host, isValidHost(host),
              components.url != nil
        else { return nil }
        return components
    }

    private static func isValidHost(_ host: String) -> Bool {
        guard !host.isEmpty, host.count <= 253 else { return false }
        // IPv6 literal, e.g. [::1]
        if host.hasPrefix("[") && host.hasSuffix("]") { return host.count > 2 }
        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_%"))
        for label in labels {
            guard !label.isEmpty, label.count <= 63,
                  label.unicodeScalars.allSatisfy({ allowed.contains($0) }),
                  !label.hasPrefix("-"), !label.hasSuffix("-")
            else { return false }
        }
        // Require a dotted name, "localhost", or an IP — rejects things like "http://foo".
        return labels.count > 1 || host.lowercased() == "localhost"
    }
}
