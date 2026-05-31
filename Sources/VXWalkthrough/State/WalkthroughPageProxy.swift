//
//  WalkthroughPageProxy.swift
//  VXWalkthrough
//

import Foundation

/// A lightweight handle handed to each page, exposing a clean control surface
/// over the underlying `WalkthroughModel` for a specific step.
@MainActor
public struct WalkthroughPageProxy {
    private let model: WalkthroughModel
    public let stepID: String

    public init(model: WalkthroughModel, stepID: String) {
        self.model = model
        self.stepID = stepID
    }

    /// The current runtime state of this page.
    public var state: StepState { model.state(for: stepID) }

    public var isFirst: Bool { model.isFirst }
    public var isLast: Bool { model.isLast }

    /// Advance to the next page (or finish on the last page).
    public func advance() { model.goNext() }

    /// Go back one page.
    public func previous() { model.goPrevious() }

    /// Finish/close the walkthrough.
    public func finish() { model.finish() }

    /// Submit a typed payload to the host action handler.
    public func submit(_ payload: WalkthroughAction.Payload) async {
        await model.perform(WalkthroughAction(stepID: stepID, payload: payload))
    }

    /// Directly set this page's state (e.g. local validation feedback).
    public func setState(_ state: StepState) {
        model.setState(state, for: stepID)
    }

    /// Notifies the host's fire-and-forget action observer.
    public func emit(_ payload: WalkthroughAction.Payload) {
        model.notify(WalkthroughAction(stepID: stepID, payload: payload))
    }

    /// Applies an outcome to this page directly (state + navigation).
    public func apply(_ outcome: StepOutcome) {
        model.applyOutcome(outcome, to: stepID)
    }
}
