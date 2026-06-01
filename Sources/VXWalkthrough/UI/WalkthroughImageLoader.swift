//
//  WalkthroughImageLoader.swift
//  VXWalkthrough
//
//  Resolves `.named` images through an ordered bundle cascade, falling back to
//  loose image files (.png/.jpg/.jpeg) when no asset-catalog entry exists. This
//  restores compatibility with legacy projects that ship `walkthrough_0…n` art
//  as loose files rather than in an asset catalog.
//

import SwiftUI

#if canImport(UIKit)
    import UIKit
    /// The platform image type (`UIImage` on UIKit, `NSImage` on AppKit).
    public typealias WalkthroughPlatformImage = UIImage
#elseif canImport(AppKit)
    import AppKit
    /// The platform image type (`UIImage` on UIKit, `NSImage` on AppKit).
    public typealias WalkthroughPlatformImage = NSImage
#endif

/// Resolves named images across a bundle cascade with a loose-file fallback.
///
/// Search order (first hit wins, de-duplicated):
/// `preferred` → `Bundle.main` → ``VXWalkthrough/resourceBundle`` — i.e. the
/// host app takes precedence over the library's own resources.
@MainActor
enum WalkthroughImageLoader {
    #if canImport(UIKit) || canImport(AppKit)
        private static let cache = NSCache<NSString, WalkthroughPlatformImage>()
    #endif

    /// Loose-file extensions we attempt, in priority order.
    static let supportedExtensions = ["png", "jpg", "jpeg"]

    /// Filename suffixes tried for loose files (scale/idiom variants).
    private static let suffixes = ["", "@2x", "@3x", "~ipad", "~ipad@2x", "~ipad@3x"]

    /// The ordered, de-duplicated bundles searched for `name`.
    static func candidateBundles(preferred: Bundle?) -> [Bundle] {
        var result: [Bundle] = []
        func add(_ bundle: Bundle?) {
            guard let bundle, !result.contains(where: { $0 === bundle }) else { return }
            result.append(bundle)
        }
        add(preferred)
        add(.main)
        add(VXWalkthrough.resourceBundle)
        return result
    }

    #if canImport(UIKit) || canImport(AppKit)
        /// Resolves `name` to a platform image, or `nil` if not found.
        static func loadImage(named name: String, preferredBundle: Bundle?) -> WalkthroughPlatformImage? {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }

            let bundles = candidateBundles(preferred: preferredBundle)
            let key = (bundles.map { $0.bundleIdentifier ?? $0.bundlePath }.joined(separator: "|") + "::" + trimmed) as NSString
            if let cached = cache.object(forKey: key) { return cached }

            for bundle in bundles {
                if let image = namedLookup(trimmed, in: bundle) ?? looseLookup(trimmed, in: bundle) {
                    cache.setObject(image, forKey: key)
                    return image
                }
            }
            return nil
        }

        /// Asset-catalog (and, on UIKit, loose) lookup by name.
        private static func namedLookup(_ name: String, in bundle: Bundle) -> WalkthroughPlatformImage? {
            #if canImport(UIKit)
                return UIImage(named: name, in: bundle, compatibleWith: nil)
            #elseif canImport(AppKit)
                return bundle.image(forResource: name)
            #endif
        }

        /// Explicit loose-file lookup across scale/idiom suffixes and extensions.
        private static func looseLookup(_ name: String, in bundle: Bundle) -> WalkthroughPlatformImage? {
            for suffix in suffixes {
                for ext in supportedExtensions {
                    guard let url = bundle.url(forResource: name + suffix, withExtension: ext) else { continue }
                    #if canImport(UIKit)
                        if let image = UIImage(contentsOfFile: url.path) { return image }
                    #elseif canImport(AppKit)
                        if let image = NSImage(contentsOf: url) { return image }
                    #endif
                }
            }
            return nil
        }
    #endif
}

// MARK: - Environment

private struct WalkthroughImageBundleKey: EnvironmentKey {
    static let defaultValue: Bundle? = nil
}

public extension EnvironmentValues {
    /// A host-provided bundle searched *before* `Bundle.main` and the library
    /// bundle when resolving `.named` images. Defaults to `nil`.
    var walkthroughImageBundle: Bundle? {
        get { self[WalkthroughImageBundleKey.self] }
        set { self[WalkthroughImageBundleKey.self] = newValue }
    }
}

public extension View {
    /// Prepends a bundle to the `.named` image search order.
    ///
    /// Most apps need no configuration — loose images in the main bundle are
    /// found automatically. Use this to point at a custom resource bundle.
    func walkthroughImageBundle(_ bundle: Bundle) -> some View {
        environment(\.walkthroughImageBundle, bundle)
    }
}
