//
//  LocalizedStepsLoaderTests.swift
//  VXWalkthroughTests
//
//  Exercises the loader against an injected closure *and* a real localized
//  resource bundle (Tests/.../Resources/en.lproj/Localizable.strings).
//

import Foundation
import Testing
@testable import VXWalkthrough

struct LocalizedStepsLoaderTests {
    @Test func loadsSequentiallyUntilMissingKey() {
        let table = [
            "walkthrough_0": "First",
            "walkthrough_1": "Second",
        ]
        let loader = LocalizedStepsLoader(lookup: { table[$0] })
        let steps = loader.load()

        #expect(steps.count == 2)
        #expect(steps[0].id == "walkthrough_0")
        #expect(steps[0].title.plainText == "First")
        #expect(steps[1].image == .named("walkthrough_1"))
        #expect(steps.allSatisfy { $0.kind == .info })
    }

    @Test func treatsUntranslatedKeyAsTerminator() {
        // bundleLookup returns the key itself when no translation exists; the
        // loader must treat that as the end of the sequence.
        let loader = LocalizedStepsLoader(lookup: { $0 == "walkthrough_0" ? "Only" : $0 })
        #expect(loader.load().count == 1)
    }

    @Test func honoursCustomImagePrefix() {
        let loader = LocalizedStepsLoader(lookup: { $0 == "walkthrough_0" ? "Title" : nil })
        let steps = loader.load(imagePrefix: "onboard_")
        #expect(steps.first?.image == .named("onboard_0"))
    }

    @Test func loadsFromRealLocalizedBundle() {
        let loader = LocalizedStepsLoader(lookup: LocalizedStepsLoader.bundleLookup(.module))
        let steps = loader.load()

        #expect(steps.count == 3)
        #expect(steps.map(\.id) == ["walkthrough_0", "walkthrough_1", "walkthrough_2"])
        // Markup is parsed into plain text for accessibility/sorting purposes.
        #expect(steps[0].title.plainText == "See No Evil")
        #expect(steps[2].title.plainText == "Speak No Evil")
    }
}
