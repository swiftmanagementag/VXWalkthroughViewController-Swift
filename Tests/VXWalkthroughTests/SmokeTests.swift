import Testing
@testable import VXWalkthrough

@Suite("Smoke")
struct SmokeTests {
    @Test("Framework exposes a version and resource bundle")
    func metadata() {
        #expect(!VXWalkthrough.version.isEmpty)
        _ = VXWalkthrough.resourceBundle
    }
}
