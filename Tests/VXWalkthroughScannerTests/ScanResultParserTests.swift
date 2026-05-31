import Testing
import Foundation
@testable import VXWalkthroughScanner

@Suite("ScanResultParser")
struct ScanResultParserTests {
    @Test("Plain code passes through unchanged")
    func plain() {
        let result = ScanResultParser.parse("ABC-123")
        #expect(result.value == "ABC-123")
        #expect(result.voucher == nil)
        #expect(result.teacher == nil)
    }

    @Test("Trims whitespace")
    func trims() {
        #expect(ScanResultParser.parse("  XY-9  ").value == "XY-9")
    }

    @Test("Extracts voucher and teacher from a URL payload")
    func urlPayload() {
        let url = "https://truck.app.link/truck?voucher=JOPJ-OI6I-VWKO&teacher=L025&flavor=ch_truck_premium"
        let result = ScanResultParser.parse(url)
        #expect(result.value == "JOPJ-OI6I-VWKO")
        #expect(result.voucher == "JOPJ-OI6I-VWKO")
        #expect(result.teacher == "L025")
    }

    @Test("URL without voucher falls back to the full string")
    func urlNoVoucher() {
        let url = "https://example.com/path?foo=bar"
        let result = ScanResultParser.parse(url)
        #expect(result.value == url)
        #expect(result.voucher == nil)
    }

    @Test("Availability flag is platform-correct")
    func availability() {
        #if os(iOS)
            #expect(VXWalkthroughScanner.isAvailable)
        #else
            #expect(!VXWalkthroughScanner.isAvailable)
        #endif
    }
}
