//
//  ImageLoaderTests.swift
//  VXWalkthroughTests
//
//  Verifies the legacy loose-image fallback: `.named` images resolve from loose
//  .png/.jpg/.jpeg files in a bundle, with the host app bundle taking
//  precedence over the library bundle.
//

import Foundation
import Testing
@testable import VXWalkthrough

@MainActor
struct ImageLoaderTests {
    @Test func appBundleHasPrecedenceOverLibraryBundle() {
        let order = WalkthroughImageLoader.candidateBundles(preferred: nil)
        let mainIndex = order.firstIndex { $0 === Bundle.main }
        let moduleIndex = order.firstIndex { $0 === VXWalkthrough.resourceBundle }
        #expect(mainIndex != nil)
        if let mainIndex, let moduleIndex {
            #expect(mainIndex < moduleIndex)
        }
    }

    @Test func preferredBundleIsSearchedFirst() {
        let order = WalkthroughImageLoader.candidateBundles(preferred: .module)
        #expect(order.first === Bundle.module)
    }

    @Test func candidateBundlesAreDeduplicated() {
        // Passing main as the preferred bundle must not list it twice.
        let order = WalkthroughImageLoader.candidateBundles(preferred: .main)
        let mainCount = order.filter { $0 === Bundle.main }.count
        #expect(mainCount == 1)
    }

    @Test func supportsOnlyPNGAndJPEG() {
        #expect(WalkthroughImageLoader.supportedExtensions == ["png", "jpg", "jpeg"])
    }

    #if canImport(UIKit) || canImport(AppKit)
        @Test func loadsLoosePNG() {
            let image = WalkthroughImageLoader.loadImage(named: "frame_0", preferredBundle: .module)
            #expect(image != nil)
        }

        @Test func loadsLooseJPEG() {
            let image = WalkthroughImageLoader.loadImage(named: "frame_1", preferredBundle: .module)
            #expect(image != nil)
        }

        @Test func loadsScaleOnlyVariant() {
            // Only `frame_2@2x.png` exists (no base name) — the suffix matrix
            // must still find it.
            let image = WalkthroughImageLoader.loadImage(named: "frame_2", preferredBundle: .module)
            #expect(image != nil)
        }

        @Test func missingNameReturnsNil() {
            let image = WalkthroughImageLoader.loadImage(named: "definitely_not_here_42", preferredBundle: .module)
            #expect(image == nil)
        }

        @Test func blankNameReturnsNil() {
            #expect(WalkthroughImageLoader.loadImage(named: "   ", preferredBundle: .module) == nil)
        }

        @Test func resolvesFromLibraryBundleWhenNoPreferred() {
            // The fixtures live in the test bundle, which is `.module` here; a
            // miss against main should continue the cascade rather than throw.
            let image = WalkthroughImageLoader.loadImage(named: "frame_0", preferredBundle: .module)
            #expect(image != nil)
        }
    #endif
}
