//
//  CircleMeasurement.swift
//  VXWalkthrough
//
//  Plumbing for cross-page circular image sizing. Each page reports the height
//  of its non-image content (title / body / controls); the container takes the
//  largest such height (the most-constrained page), derives the vertical space
//  left for the image, resolves a single circle diameter that fits everywhere,
//  and injects it back through the environment. Sizing the image independently
//  of the measured content avoids any layout feedback loop.
//

import SwiftUI

/// Collects the tallest non-image content height across all pages.
struct PageContentHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// The diameter resolved by the container for the circular image style.
private struct ResolvedCircleDiameterKey: EnvironmentKey {
    static let defaultValue: CGFloat? = nil
}

extension EnvironmentValues {
    var walkthroughResolvedCircleDiameter: CGFloat? {
        get { self[ResolvedCircleDiameterKey.self] }
        set { self[ResolvedCircleDiameterKey.self] = newValue }
    }
}

extension View {
    /// Reports the receiver's height as the page's non-image content height, so
    /// the container can size a circle that fits across every page.
    func measureWalkthroughContentHeight() -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: PageContentHeightPreferenceKey.self,
                    value: proxy.size.height
                )
            }
        )
    }
}
