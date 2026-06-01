//
//  AttributedTitle.swift
//  VXWalkthrough
//

import Foundation

/// A piece of walkthrough text that supports lightweight inline bold markup.
///
/// Two markup styles are recognized (matching the legacy framework):
/// - asterisks: `"See *No* Evil"`
/// - `<b>` tags: `"See <b>No</b> Evil"`
///
/// Marked spans are rendered bold by applying
/// `.inlinePresentationIntent = .stronglyEmphasized`, which SwiftUI's `Text`
/// renders using the bold weight of the surrounding font.
public struct AttributedTitle: Sendable, Equatable, Hashable,
    ExpressibleByStringLiteral, ExpressibleByStringInterpolation,
    CustomStringConvertible
{
    /// The raw, unparsed string including any markup delimiters.
    public var raw: String

    public init(_ raw: String) { self.raw = raw }
    public init(stringLiteral value: String) { self.raw = value }

    public var isEmpty: Bool {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The plain string with all markup delimiters removed.
    public var plainText: String {
        String(AttributedTitleParser.parse(raw).characters)
    }

    public var description: String { raw }

    /// The parsed attributed representation with bold spans applied.
    public func attributedString() -> AttributedString {
        AttributedTitleParser.parse(raw)
    }
}

enum AttributedTitleParser {
    /// Capture group 2 of each pattern is the inner (bold) text.
    private static let patterns = [
        "(\\*)(.+?)(\\*)",
        "(<b>)(.+?)(</b>)",
    ]

    struct Span {
        let range: Range<String.Index>
        let inner: Range<String.Index>
    }

    static func parse(_ raw: String) -> AttributedString {
        guard !raw.isEmpty else { return AttributedString("") }

        let spans = boldSpans(in: raw)
        guard !spans.isEmpty else { return AttributedString(raw) }

        var result = AttributedString()
        var cursor = raw.startIndex

        for span in spans {
            if cursor < span.range.lowerBound {
                result += AttributedString(String(raw[cursor ..< span.range.lowerBound]))
            }
            var bold = AttributedString(String(raw[span.inner]))
            bold.inlinePresentationIntent = .stronglyEmphasized
            result += bold
            cursor = span.range.upperBound
        }

        if cursor < raw.endIndex {
            result += AttributedString(String(raw[cursor ..< raw.endIndex]))
        }
        return result
    }

    /// Returns non-overlapping bold spans ordered by location. Overlapping
    /// matches (e.g. a `<b>` span starting inside an earlier `*` span) are
    /// skipped deterministically.
    private static func boldSpans(in raw: String) -> [Span] {
        let ns = raw as NSString
        var candidates: [(NSRange, NSRange)] = []

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let matches = regex.matches(in: raw, range: NSRange(location: 0, length: ns.length))
            for match in matches where match.numberOfRanges >= 3 {
                candidates.append((match.range, match.range(at: 2)))
            }
        }

        candidates.sort { $0.0.location < $1.0.location }

        var spans: [Span] = []
        var consumedUpTo = 0
        for (full, inner) in candidates {
            guard full.location >= consumedUpTo else { continue } // skip overlap
            guard let fullRange = Range(full, in: raw),
                  let innerRange = Range(inner, in: raw)
            else { continue }
            spans.append(Span(range: fullRange, inner: innerRange))
            consumedUpTo = full.location + full.length
        }
        return spans
    }
}
