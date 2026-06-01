//
//  WalkthroughImage.swift
//  VXWalkthrough
//

import Foundation

/// Describes the image shown on a walkthrough page.
public enum WalkthroughImage: Sendable, Equatable, Hashable {
    /// An image from an asset catalog, looked up by name.
    case named(String)
    /// An SF Symbol, looked up by system name.
    case system(String)
    /// A remote image loaded asynchronously.
    case remote(URL)
    /// No image.
    case none

    /// Convenience: treat an empty/whitespace name as `.none`.
    public init(named name: String?) {
        guard let name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            self = .none
            return
        }
        self = .named(name)
    }

    public var isEmpty: Bool { self == .none }
}
