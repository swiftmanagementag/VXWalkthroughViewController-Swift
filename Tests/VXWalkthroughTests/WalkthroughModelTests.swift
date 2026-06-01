import Testing
import Foundation
@testable import VXWalkthrough

@MainActor
@Suite("WalkthroughModel")
struct WalkthroughModelTests {
    private func makeModel(_ count: Int = 3) -> WalkthroughModel {
        let steps = (0 ..< count).map { WalkthroughStep(id: "p\($0)", kind: .action(ActionSpec()), sort: $0) }
        return WalkthroughModel(steps: steps)
    }

    @Test("Initial state")
    func initial() {
        let model = makeModel()
        #expect(model.currentIndex == 0)
        #expect(model.numberOfPages == 3)
        #expect(model.isFirst)
        #expect(!model.isLast)
        #expect(model.currentStepID == "p0")
    }

    @Test("Next and previous navigation with bounds")
    func navigation() {
        let model = makeModel()
        model.goNext()
        #expect(model.currentIndex == 1)
        model.goNext()
        #expect(model.currentIndex == 2)
        #expect(model.isLast)
        model.goPrevious()
        #expect(model.currentIndex == 1)
        model.goPrevious()
        model.goPrevious() // clamped at 0
        #expect(model.currentIndex == 0)
    }

    @Test("onPageChange fires on navigation only")
    func pageChangeEvents() {
        let model = makeModel()
        var changes: [Int] = []
        model.onPageChange = { changes.append($0) }
        model.goNext()
        model.go(to: 2)
        model.go(to: 2) // no-op, same index
        #expect(changes == [1, 2])
    }

    @Test("Finishing on the last page calls onFinish")
    func finishOnLast() {
        let model = makeModel(2)
        var finished = false
        model.onFinish = { finished = true }
        model.goNext() // -> index 1 (last)
        #expect(!finished)
        model.goNext() // last -> finish
        #expect(finished)
        #expect(model.currentIndex == 1)
    }

    @Test("syncIndex reacts to scroll-driven id changes")
    func syncIndex() {
        let model = makeModel()
        model.syncIndex(toStepID: "p2")
        #expect(model.currentIndex == 2)
        model.syncIndex(toStepID: "missing")
        #expect(model.currentIndex == 2)
    }

    @Test("perform applies .success outcome and advances")
    func performSuccess() async {
        let model = makeModel()
        model.actionHandler = { _ in .success("Welcome") }
        await model.perform(WalkthroughAction(stepID: "p0", payload: .action))
        #expect(model.state(for: "p0") == .success("Welcome"))
        #expect(model.currentIndex == 1)
    }

    @Test("perform applies .failure outcome and stays")
    func performFailure() async {
        let model = makeModel()
        model.actionHandler = { _ in .failure("Bad credentials") }
        await model.perform(WalkthroughAction(stepID: "p0", payload: .login(Credentials(login: "a", password: "b"))))
        #expect(model.state(for: "p0") == .failure("Bad credentials"))
        #expect(model.currentIndex == 0)
    }

    @Test("perform applies .successStay without advancing")
    func performSuccessStay() async {
        let model = makeModel()
        model.actionHandler = { _ in .successStay("Saved") }
        await model.perform(WalkthroughAction(stepID: "p0", payload: .action))
        #expect(model.state(for: "p0") == .success("Saved"))
        #expect(model.currentIndex == 0)
    }

    @Test("perform with no handler advances")
    func performNoHandler() async {
        let model = makeModel()
        await model.perform(WalkthroughAction(stepID: "p0", payload: .action))
        #expect(model.currentIndex == 1)
    }

    @Test("onAction observer receives the action")
    func onActionObserver() async {
        let model = makeModel()
        var received: WalkthroughAction?
        model.onAction = { received = $0 }
        model.actionHandler = { _ in .none }
        let action = WalkthroughAction(stepID: "p0", payload: .signup(email: "a@b.com"))
        await model.perform(action)
        #expect(received == action)
    }
}
