import Testing
import Foundation
import VXWalkthrough
@testable import VXWalkthroughPermissions

/// These tests run on the macOS host. The system backends are gated behind
/// `#if os(iOS)` (and per-kind traits), so on macOS every kind resolves to
/// `.unavailable`. The value of this target is the traits-enabled *compile*:
/// CI runs it with all traits on to verify each backend builds.
@Suite("SystemPermissionRequester (host)")
struct SystemPermissionRequesterTests {
    @Test("Constructs and conforms to PermissionRequesting")
    func constructs() {
        let requester: any PermissionRequesting = SystemPermissionRequester()
        _ = requester
    }

    @Test("On the macOS host, every kind resolves to .unavailable")
    func unavailableOnHost() async {
        let requester = SystemPermissionRequester()
        for kind in PermissionKind.allCases {
            await #expect(requester.status(for: kind) == .unavailable)
            await #expect(requester.request(kind) == .unavailable)
        }
    }
}
