import Testing
import Foundation
@testable import VXWalkthrough

@Suite("LocalizedStepsLoader")
struct LocalizedStepsLoaderTests {
    @Test("Loads sequential keys until the first gap")
    func sequential() {
        let table = [
            "walkthrough_0": "See *No* Evil",
            "walkthrough_1": "Hear No Evil",
            "walkthrough_2": "Speak *Evil*",
        ]
        let loader = LocalizedStepsLoader { table[$0] }
        let steps = loader.load()

        #expect(steps.count == 3)
        #expect(steps.map(\.id) == ["walkthrough_0", "walkthrough_1", "walkthrough_2"])
        #expect(steps[0].image == .named("walkthrough_0"))
        #expect(steps[2].image == .named("walkthrough_2"))
        #expect(steps[0].sort == 0)
        #expect(steps[1].sort == 10)
    }

    @Test("Stops at a missing key")
    func stopsAtGap() {
        let table = ["walkthrough_0": "A", "walkthrough_1": "B"]
        let loader = LocalizedStepsLoader { table[$0] }
        #expect(loader.load().count == 2)
    }

    @Test("Treats untranslated (value == key) as missing")
    func untranslated() {
        let loader = LocalizedStepsLoader { key in key } // echo back: no translations
        #expect(loader.load().isEmpty)
    }

    @Test("Custom image prefix")
    func imagePrefix() {
        let table = ["walkthrough_0": "A"]
        let loader = LocalizedStepsLoader { table[$0] }
        let steps = loader.load(imagePrefix: "img_")
        #expect(steps[0].image == .named("img_0"))
    }
}
