//
//  LocalizedStepsLoader.swift
//  VXWalkthrough
//
//  Opt-in parity with the legacy `populate()` behavior: builds info steps from
//  localized keys `walkthrough_0`, `walkthrough_1`, … until a key is missing.
//

import Foundation

/// Builds walkthrough steps from sequentially-numbered localized strings.
public struct LocalizedStepsLoader: Sendable {
    /// Resolves a localization key to its value, or `nil` if absent.
    public typealias Lookup = @Sendable (_ key: String) -> String?

    private let prefix: String
    private let lookup: Lookup

    /// - Parameters:
    ///   - prefix: Key prefix (default `"walkthrough_"`).
    ///   - lookup: Key resolver. Defaults to `NSLocalizedString` against the
    ///     main bundle, treating "value == key" (no translation) as missing.
    public init(
        prefix: String = "walkthrough_",
        lookup: @escaping Lookup = LocalizedStepsLoader.bundleLookup(.main)
    ) {
        self.prefix = prefix
        self.lookup = lookup
    }

    /// Loads steps `\(prefix)0…n` until the first missing/empty key.
    public func load(imagePrefix: String? = nil) -> [WalkthroughStep] {
        var steps: [WalkthroughStep] = []
        var index = 0
        while true {
            let key = "\(prefix)\(index)"
            guard let value = lookup(key), !value.isEmpty, value != key else { break }
            let imageName = "\(imagePrefix ?? prefix)\(index)"
            steps.append(
                WalkthroughStep(
                    id: key,
                    kind: .info,
                    title: AttributedTitle(value),
                    image: .named(imageName),
                    sort: index * 10
                )
            )
            index += 1
        }
        return steps
    }

    /// A lookup backed by a `Bundle`'s localization tables.
    public static func bundleLookup(_ bundle: Bundle) -> Lookup {
        { key in
            let value = bundle.localizedString(forKey: key, value: key, table: nil)
            return value
        }
    }
}
