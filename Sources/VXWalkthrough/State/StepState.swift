//
//  StepState.swift
//  VXWalkthrough
//

import Foundation

/// The runtime state of an interactive walkthrough step.
///
/// Replaces the legacy `success` / `error` string keys with an explicit,
/// type-safe state machine that the runtime drives around `async` actions.
public enum StepState: Sendable, Equatable {
    case idle
    case loading
    case success(String?)
    case failure(String?)

    public var isLoading: Bool { self == .loading }

    public var isTerminal: Bool {
        switch self {
        case .success, .failure: true
        case .idle, .loading: false
        }
    }

    /// A user-facing message associated with a success/failure state, if any.
    public var message: String? {
        switch self {
        case let .success(message), let .failure(message): message
        case .idle, .loading: nil
        }
    }
}

/// The result a host returns from an action handler, instructing the runtime
/// how to update the originating step and whether to advance.
public enum StepOutcome: Sendable, Equatable {
    /// Mark the step successful (optionally showing a message) and advance.
    case success(String? = nil)
    /// Mark the step successful but stay on the page.
    case successStay(String? = nil)
    /// Mark the step failed and show a message.
    case failure(String? = nil)
    /// Advance to the next page without changing state.
    case advance
    /// Do nothing.
    case none
}
