import Testing
import Foundation
@testable import VXWalkthrough

@Suite("WalkthroughImage")
struct WalkthroughImageTests {
    @Test("init(named:) maps empty/whitespace to .none")
    func emptyName() {
        #expect(WalkthroughImage(named: nil) == .none)
        #expect(WalkthroughImage(named: "") == .none)
        #expect(WalkthroughImage(named: "   ") == .none)
        #expect(WalkthroughImage(named: "walkthrough_0") == .named("walkthrough_0"))
    }

    @Test("isEmpty reflects .none")
    func isEmpty() {
        #expect(WalkthroughImage.none.isEmpty)
        #expect(!WalkthroughImage.system("star").isEmpty)
    }
}

@Suite("StepState")
struct StepStateTests {
    @Test("loading flag")
    func loading() {
        #expect(StepState.loading.isLoading)
        #expect(!StepState.idle.isLoading)
    }

    @Test("terminal states and messages")
    func terminal() {
        #expect(StepState.success("ok").isTerminal)
        #expect(StepState.failure("bad").isTerminal)
        #expect(!StepState.idle.isTerminal)
        #expect(StepState.success("ok").message == "ok")
        #expect(StepState.failure("bad").message == "bad")
        #expect(StepState.loading.message == nil)
    }
}

@Suite("WalkthroughStep ordering")
struct StepOrderingTests {
    @Test("sortedBySort orders by sort ascending")
    func bySort() {
        let steps = [
            WalkthroughStep(id: "b", sort: 20),
            WalkthroughStep(id: "a", sort: 10),
            WalkthroughStep(id: "c", sort: 30),
        ]
        #expect(steps.sortedBySort().map(\.id) == ["a", "b", "c"])
    }

    @Test("equal sort values preserve declaration order (stable)")
    func stable() {
        let steps = [
            WalkthroughStep(id: "x", sort: 0),
            WalkthroughStep(id: "y", sort: 0),
            WalkthroughStep(id: "z", sort: 0),
        ]
        #expect(steps.sortedBySort().map(\.id) == ["x", "y", "z"])
    }

    @Test("StepKind metadata")
    func kindMetadata() {
        #expect(StepKind.info.isInteractive == false)
        #expect(StepKind.action(ActionSpec()).isInteractive == true)
        #expect(StepKind.info.name == "info")
        #expect(StepKind.permission(PermissionSpec(kind: .camera)).name == "permission")
    }
}
