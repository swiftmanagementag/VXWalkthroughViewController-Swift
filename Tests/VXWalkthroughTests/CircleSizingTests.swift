//
//  CircleSizingTests.swift
//  VXWalkthroughTests
//
//  Covers the pure cross-page circle-sizing logic and the slot-height
//  reduction (smallest leftover across pages wins), including the rotation
//  case (a shorter container yields a smaller diameter).
//

import CoreGraphics
import Testing
@testable import VXWalkthrough

struct CircleSizingTests {
    private let style = WalkthroughTheme.CircleStyle.default // margin 24, maxDiameter 320

    @Test("Caps at maxDiameter when space is plentiful")
    func capsAtMax() {
        let d = CircleSizing.diameter(minLeftoverHeight: 1000, width: 1000, style: style)
        #expect(d == 320)
    }

    @Test("Width-constrained (portrait, narrow)")
    func widthConstrained() {
        let d = CircleSizing.diameter(minLeftoverHeight: 1000, width: 200, style: style)
        #expect(d == 152) // width - 2*margin (200 - 48)
    }

    @Test("Height-constrained, and shorter height yields smaller diameter (rotation)")
    func rotationShrinksDiameter() {
        let tall = CircleSizing.diameter(minLeftoverHeight: 1000, width: 1000, style: style)
        let short = CircleSizing.diameter(minLeftoverHeight: 150, width: 1000, style: style)
        #expect(short == 102) // height - 2*margin (150 - 48)
        #expect(short < tall)
    }

    @Test("Margin is subtracted on both sides")
    func marginSubtracted() {
        let s = WalkthroughTheme.CircleStyle(maxDiameter: nil, margin: 50)
        let d = CircleSizing.diameter(minLeftoverHeight: 400, width: 400, style: s)
        #expect(d == 300) // 400 - 2*50
    }

    @Test("nil maxDiameter is uncapped (bounded by the smaller dimension)")
    func uncapped() {
        let s = WalkthroughTheme.CircleStyle(maxDiameter: nil, margin: 0)
        let d = CircleSizing.diameter(minLeftoverHeight: 500, width: 800, style: s)
        #expect(d == 500)
    }

    @Test("Clamps to the minimum diameter for tiny space")
    func minimumClamp() {
        let d = CircleSizing.diameter(minLeftoverHeight: 10, width: 10, style: style)
        #expect(d == CircleSizing.minimumDiameter)
    }

    @Test("Infinite leftover (pre-measurement) is bounded, never infinite")
    func infinitePreMeasurement() {
        let uncapped = WalkthroughTheme.CircleStyle(maxDiameter: nil, margin: 24)
        let d = CircleSizing.diameter(minLeftoverHeight: .infinity, width: .infinity, style: uncapped)
        #expect(d == CircleSizing.minimumDiameter)
        // With a cap, an unmeasured wide container falls back to the cap.
        let capped = CircleSizing.diameter(minLeftoverHeight: .infinity, width: 1000, style: style)
        #expect(capped == 320)
    }

    @Test("Content-height preference keeps the tallest (most-constrained) page")
    func preferenceReducesToMax() {
        var value = PageContentHeightPreferenceKey.defaultValue
        #expect(value == 0)
        PageContentHeightPreferenceKey.reduce(value: &value) { 120 }
        PageContentHeightPreferenceKey.reduce(value: &value) { 260 }
        PageContentHeightPreferenceKey.reduce(value: &value) { 200 }
        #expect(value == 260)
    }
}
