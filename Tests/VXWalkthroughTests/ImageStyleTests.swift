//
//  ImageStyleTests.swift
//  VXWalkthroughTests
//
//  Covers the additive aspect-fit `ImageStyle.fit` used for wide artwork.
//

import Foundation
import SwiftUI
import Testing
@testable import VXWalkthrough

@MainActor
struct ImageStyleTests {
    @Test("`.fit` is a distinct, additive style (existing cases unchanged)")
    func fitIsDistinct() {
        let styles: [WalkthroughTheme.ImageStyle] = [.round, .fullBleed, .card, .fit]
        #expect(Set(styles.map(String.init(describing:))).count == 4)
        #expect(WalkthroughTheme.ImageStyle.fit != .fullBleed)
        #expect(WalkthroughTheme.ImageStyle.fit != .card)
    }

    @Test("Default theme still uses `.round` (non-breaking)")
    func defaultUnchanged() {
        #expect(WalkthroughTheme.default.imageStyle == .round)
    }

    @Test("A theme can opt into `.fit`")
    func themeOptsIntoFit() {
        let theme = WalkthroughTheme(imageStyle: .fit)
        #expect(theme.imageStyle == .fit)
    }

    #if canImport(UIKit) || canImport(AppKit)
        @Test("A loose image renders through `.fit` without throwing")
        func fitRendersLooseImage() {
            // The view builds a WalkthroughImageView with the .fit style around a
            // real loose fixture; constructing it must not trap. Aspect-fit means
            // the loader still resolves the image; cropping behavior is visual.
            let image = WalkthroughImageLoader.loadImage(named: "frame_0", preferredBundle: .module)
            #expect(image != nil)
            let view = WalkthroughImageView(image: .named("frame_0"), style: .fit)
            _ = view.body
        }
    #endif
}
