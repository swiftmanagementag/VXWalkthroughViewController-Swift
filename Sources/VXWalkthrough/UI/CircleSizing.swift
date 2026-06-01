//
//  CircleSizing.swift
//  VXWalkthrough
//
//  Pure sizing logic for the circular image style. Kept free of SwiftUI so it
//  can be unit-tested directly. The resolved diameter is the largest circle
//  that fits across every page (the most-constrained page wins) while leaving
//  the configured margin, capped by `maxDiameter`.
//

import CoreGraphics

enum CircleSizing {
    /// The smallest diameter we will ever resolve to, so the circle never
    /// collapses on very constrained layouts.
    static let minimumDiameter: CGFloat = 44

    /// Computes the circle diameter.
    ///
    /// - Parameters:
    ///   - minLeftoverHeight: The smallest leftover image-slot height across all
    ///     pages. Pass `.infinity` when no measurement is available yet (the
    ///     result is then bounded by `width` and `maxDiameter`).
    ///   - width: The available container width.
    ///   - style: The theme's circle style (margin / max diameter).
    /// - Returns: A finite, positive diameter, clamped to `minimumDiameter`.
    static func diameter(
        minLeftoverHeight: CGFloat,
        width: CGFloat,
        style: WalkthroughTheme.CircleStyle
    ) -> CGFloat {
        let margin = max(0, style.margin)
        let byHeight = minLeftoverHeight - 2 * margin
        let byWidth = width - 2 * margin
        let cap = style.maxDiameter ?? .infinity

        let candidate = min(byHeight, byWidth, cap)
        guard candidate.isFinite else { return minimumDiameter }
        return max(minimumDiameter, candidate)
    }
}
