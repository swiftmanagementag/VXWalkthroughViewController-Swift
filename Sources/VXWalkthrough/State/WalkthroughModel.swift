//
//  WalkthroughModel.swift
//  VXWalkthrough
//

import Foundation
import Observation

/// The async handler a host supplies to react to interactive page actions.
public typealias WalkthroughActionHandler = @MainActor (WalkthroughAction) async -> StepOutcome

/// The runtime coordinator for a walkthrough: navigation, per-step state, and
/// host event dispatch. `@Observable` so SwiftUI views update automatically.
@MainActor
@Observable
public final class WalkthroughModel {
    public private(set) var steps: [WalkthroughStep]
    public var theme: WalkthroughTheme
    public private(set) var currentIndex: Int = 0
    private var stepStates: [String: StepState] = [:]

    /// Host hooks (assigned by `WalkthroughView`).
    public var actionHandler: WalkthroughActionHandler?
    public var onFinish: (@MainActor () -> Void)?
    public var onPageChange: (@MainActor (Int) -> Void)?
    public var onAction: (@MainActor (WalkthroughAction) -> Void)?

    public init(walkthrough: Walkthrough) {
        steps = walkthrough.steps
        theme = walkthrough.theme
    }

    public init(steps: [WalkthroughStep], theme: WalkthroughTheme = .default) {
        self.steps = steps.sortedBySort()
        self.theme = theme
    }

    // MARK: Derived

    public var numberOfPages: Int { steps.count }
    public var isEmpty: Bool { steps.isEmpty }
    public var isFirst: Bool { currentIndex <= 0 }
    public var isLast: Bool { currentIndex >= steps.count - 1 }

    public var currentStep: WalkthroughStep? {
        steps.indices.contains(currentIndex) ? steps[currentIndex] : nil
    }

    public func state(for id: String) -> StepState {
        stepStates[id] ?? .idle
    }

    public func setState(_ state: StepState, for id: String) {
        stepStates[id] = state
    }

    /// The id of the current step (used to bind a `scrollPosition`).
    public var currentStepID: String? { currentStep?.id }

    // MARK: Navigation

    public func go(to index: Int) {
        let clamped = max(0, min(index, steps.count - 1))
        guard clamped != currentIndex else { return }
        currentIndex = clamped
        onPageChange?(currentIndex)
    }

    /// Syncs the index from a scroll-driven id change without re-emitting noise.
    public func syncIndex(toStepID id: String?) {
        guard let id, let index = steps.firstIndex(where: { $0.id == id }) else { return }
        guard index != currentIndex else { return }
        currentIndex = index
        onPageChange?(currentIndex)
    }

    public func goNext() {
        if isLast {
            finish()
        } else {
            go(to: currentIndex + 1)
        }
    }

    public func goPrevious() {
        guard !isFirst else { return }
        go(to: currentIndex - 1)
    }

    public func finish() {
        onFinish?()
    }

    // MARK: Actions

    /// Dispatches an action to the host handler, driving the originating step's
    /// state and applying the returned `StepOutcome`.
    public func perform(_ action: WalkthroughAction) async {
        onAction?(action)
        guard let handler = actionHandler else {
            // No handler: treat as a plain advance.
            goNext()
            return
        }
        setState(.loading, for: action.stepID)
        let outcome = await handler(action)
        apply(outcome, to: action.stepID)
    }

    /// Notifies the fire-and-forget action observer without invoking the async
    /// handler (used by self-resolving pages such as permissions).
    public func notify(_ action: WalkthroughAction) {
        onAction?(action)
    }

    /// Applies an outcome to a step directly (used by self-resolving pages).
    public func applyOutcome(_ outcome: StepOutcome, to stepID: String) {
        apply(outcome, to: stepID)
    }

    private func apply(_ outcome: StepOutcome, to stepID: String) {
        switch outcome {
        case let .success(message):
            setState(.success(message), for: stepID)
            goNext()
        case let .successStay(message):
            setState(.success(message), for: stepID)
        case let .failure(message):
            setState(.failure(message), for: stepID)
        case .advance:
            setState(.idle, for: stepID)
            goNext()
        case .none:
            setState(.idle, for: stepID)
        }
    }
}
