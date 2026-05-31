//
//  WalkthroughPresentationGate.swift
//  VXWalkthrough
//
//  "Show the walkthrough once per app version" gate. Mirrors the legacy
//  `walkthroughShown()` semantics, with injectable storage for testing.
//

import Foundation

/// Minimal key/value persistence abstraction used by the presentation gate.
public protocol KeyValueStore: Sendable {
    func bool(forKey key: String) -> Bool
    func set(_ value: Bool, forKey key: String)
}

extension UserDefaults: @retroactive @unchecked Sendable {}
extension UserDefaults: KeyValueStore {}

/// A thread-safe in-memory store, primarily for tests.
public final class InMemoryKeyValueStore: KeyValueStore, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: Bool] = [:]

    public init() {}

    public func bool(forKey key: String) -> Bool {
        lock.withLock { storage[key] ?? false }
    }

    public func set(_ value: Bool, forKey key: String) {
        lock.withLock { storage[key] = value }
    }
}

/// Tracks whether the walkthrough has been shown for the current app version.
public struct WalkthroughPresentationGate: Sendable {
    private let store: KeyValueStore
    private let version: String
    private let keyPrefix: String

    /// - Parameters:
    ///   - store: Backing store (defaults to `.standard`).
    ///   - version: App version string. Defaults to the main bundle's
    ///     `CFBundleVersion`.
    ///   - keyPrefix: Storage key prefix (kept for parity with the legacy key).
    public init(
        store: KeyValueStore = UserDefaults.standard,
        version: String? = nil,
        keyPrefix: String = "vxwalkthroughshown_"
    ) {
        self.store = store
        self.version = version ?? Self.bundleVersion()
        self.keyPrefix = keyPrefix
    }

    private var key: String { "\(keyPrefix)\(version)" }

    /// `true` if the walkthrough has already been shown for this version.
    public var hasBeenShown: Bool { store.bool(forKey: key) }

    /// `true` if the walkthrough should be presented (i.e. not yet shown).
    public var shouldPresent: Bool { !hasBeenShown }

    /// Marks the walkthrough as shown (or not) for this version.
    public func setShown(_ shown: Bool = true) {
        store.set(shown, forKey: key)
    }

    static func bundleVersion() -> String {
        (Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String) ?? ""
    }
}
