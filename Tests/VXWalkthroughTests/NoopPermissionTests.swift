import Testing
import Foundation
@testable import VXWalkthrough

@Suite("Core permissions default (no-op)")
struct NoopPermissionTests {
    @Test("NoopPermissionRequester reports every kind as .unavailable")
    func noopReportsUnavailable() async {
        let requester = NoopPermissionRequester()
        for kind in PermissionKind.allCases {
            await #expect(requester.status(for: kind) == .unavailable)
            await #expect(requester.request(kind) == .unavailable)
        }
    }

    @Test("With the no-op default, a PermissionPage advances (no requester injected)")
    func unavailableAdvances() {
        let spec = PermissionSpec(kind: .camera, grantedMessage: "Yay", deniedMessage: "Nope")
        // The core env default is `NoopPermissionRequester`, which yields
        // `.unavailable`; the resolver turns that into `.advance`.
        #expect(PermissionResolver.outcome(for: .unavailable, spec: spec) == .advance)
    }

    @MainActor
    @Test("A PermissionPage with the no-op requester advances past itself")
    func permissionPageAdvancesWithNoop() async {
        let model = WalkthroughModel(steps: [
            WalkthroughStep(id: "perm", kind: .permission(PermissionSpec(kind: .photoLibrary, grantedMessage: "Y", deniedMessage: "N"))),
            WalkthroughStep(id: "next", kind: .info),
        ])
        let requester = NoopPermissionRequester()
        let spec = PermissionSpec(kind: .photoLibrary, grantedMessage: "Y", deniedMessage: "N")

        let status = await requester.request(spec.kind)
        model.applyOutcome(PermissionResolver.outcome(for: status, spec: spec), to: "perm")

        #expect(model.currentIndex == 1)
    }
}
