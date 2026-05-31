//
//  WalkthroughStep.swift
//  VXWalkthrough
//

import Foundation

/// The kind of a walkthrough step, with its per-kind configuration.
public enum StepKind: Sendable, Equatable {
    case info
    case input(InputSpec)
    case login(LoginSpec)
    case signup(SignupSpec)
    case action(ActionSpec)
    case picker(PickerSpec)
    case permission(PermissionSpec)
    /// A host-provided SwiftUI page, resolved by id at render time.
    case custom(contentID: String)

    /// A stable analytics/debug identifier for the kind.
    public var name: String {
        switch self {
        case .info: "info"
        case .input: "input"
        case .login: "login"
        case .signup: "signup"
        case .action: "action"
        case .picker: "picker"
        case .permission: "permission"
        case .custom: "custom"
        }
    }

    /// Whether the kind collects input or performs an action (vs. pure display).
    public var isInteractive: Bool {
        switch self {
        case .info: false
        case .custom: true
        case .input, .login, .signup, .action, .picker, .permission: true
        }
    }
}

/// A single page in a walkthrough. Pure, `Sendable` data: it carries no view
/// or behavior closures. Host behavior is supplied via the runtime's action
/// handler, keyed by `id`.
public struct WalkthroughStep: Identifiable, Sendable, Equatable {
    public var id: String
    public var kind: StepKind
    public var title: AttributedTitle
    public var body: AttributedTitle?
    public var image: WalkthroughImage
    public var sort: Int

    public init(
        id: String,
        kind: StepKind = .info,
        title: AttributedTitle = "",
        body: AttributedTitle? = nil,
        image: WalkthroughImage = .none,
        sort: Int = 0
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.image = image
        self.sort = sort
    }
}

public extension Array where Element == WalkthroughStep {
    /// Steps ordered by `sort` (stable for equal sort values, preserving the
    /// original declaration order).
    func sortedBySort() -> [WalkthroughStep] {
        enumerated()
            .sorted { lhs, rhs in
                if lhs.element.sort != rhs.element.sort {
                    return lhs.element.sort < rhs.element.sort
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}
