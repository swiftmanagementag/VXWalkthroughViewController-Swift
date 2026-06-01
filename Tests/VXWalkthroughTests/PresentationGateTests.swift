import Testing
import Foundation
@testable import VXWalkthrough

@Suite("WalkthroughPresentationGate")
struct PresentationGateTests {
    @Test("Presents once, then is suppressed for the same version")
    func oncePerVersion() {
        let store = InMemoryKeyValueStore()
        let gate = WalkthroughPresentationGate(store: store, version: "1.0.0")

        #expect(gate.shouldPresent)
        #expect(!gate.hasBeenShown)

        gate.setShown(true)

        #expect(!gate.shouldPresent)
        #expect(gate.hasBeenShown)
    }

    @Test("A new app version resets the gate")
    func newVersionResets() {
        let store = InMemoryKeyValueStore()
        WalkthroughPresentationGate(store: store, version: "1.0.0").setShown(true)

        let next = WalkthroughPresentationGate(store: store, version: "1.1.0")
        #expect(next.shouldPresent)
    }

    @Test("Uses the legacy key prefix for parity")
    func legacyKey() {
        let store = InMemoryKeyValueStore()
        WalkthroughPresentationGate(store: store, version: "42").setShown(true)
        #expect(store.bool(forKey: "vxwalkthroughshown_42"))
    }
}
