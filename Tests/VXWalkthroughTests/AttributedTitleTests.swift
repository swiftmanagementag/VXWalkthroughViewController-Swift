import Testing
import Foundation
@testable import VXWalkthrough

@Suite("AttributedTitle markup")
struct AttributedTitleTests {
    private func boldSubstrings(_ title: AttributedTitle) -> [String] {
        let attr = title.attributedString()
        var result: [String] = []
        for run in attr.runs where run.inlinePresentationIntent == .stronglyEmphasized {
            result.append(String(attr[run.range].characters))
        }
        return result
    }

    @Test("Plain text has no bold and is unchanged")
    func plainText() {
        let title: AttributedTitle = "Hear No Evil"
        #expect(title.plainText == "Hear No Evil")
        #expect(boldSubstrings(title).isEmpty)
    }

    @Test("Asterisk markup marks the inner span bold and strips delimiters")
    func asterisk() {
        let title: AttributedTitle = "See *No* Evil"
        #expect(title.plainText == "See No Evil")
        #expect(boldSubstrings(title) == ["No"])
    }

    @Test("Bold tag markup is supported")
    func boldTag() {
        let title: AttributedTitle = "See <b>No</b> Evil"
        #expect(title.plainText == "See No Evil")
        #expect(boldSubstrings(title) == ["No"])
    }

    @Test("Multiple bold spans in one string")
    func multiple() {
        let title: AttributedTitle = "*Speak* and *Evil*"
        #expect(title.plainText == "Speak and Evil")
        #expect(boldSubstrings(title) == ["Speak", "Evil"])
    }

    @Test("Mixed asterisk and tag markup")
    func mixed() {
        let title: AttributedTitle = "*A* and <b>B</b>"
        #expect(title.plainText == "A and B")
        #expect(boldSubstrings(title) == ["A", "B"])
    }

    @Test("Empty string yields empty attributed text")
    func empty() {
        let title: AttributedTitle = ""
        #expect(title.isEmpty)
        #expect(title.plainText.isEmpty)
    }

    @Test("Unterminated marker is left as literal text")
    func unterminated() {
        let title: AttributedTitle = "See *No Evil"
        #expect(title.plainText == "See *No Evil")
        #expect(boldSubstrings(title).isEmpty)
    }
}
