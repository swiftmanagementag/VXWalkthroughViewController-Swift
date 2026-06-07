//
//  WalkthroughAdvance.swift
//  VXWalkthrough
//
//  An environment action that lets host-provided custom pages drive navigation
//  (advance / previous / finish) without threading the page proxy through every
//  subview.
//

import SwiftUI

/// A navigation control surface exposed to custom pages through the
/// environment. Calling the action (or `advance()`) moves to the next page
/// (finishing on the last page), mirroring `WalkthroughPageProxy`.
///
/// ```swift
/// struct ExamDatePage: View {
///     @Environment(\.walkthroughAdvance) private var advance
///     var body: some View {
///         Button("Continue") { advance() }
///     }
/// }
/// ```
public struct WalkthroughAdvanceAction: Sendable {
    private let _advance: @MainActor () -> Void
    private let _previous: @MainActor () -> Void
    private let _finish: @MainActor () -> Void

    public init(
        advance: @escaping @MainActor () -> Void = {},
        previous: @escaping @MainActor () -> Void = {},
        finish: @escaping @MainActor () -> Void = {}
    ) {
        _advance = advance
        _previous = previous
        _finish = finish
    }

    /// Advance to the next page (or finish on the last page).
    @MainActor public func advance() { _advance() }

    /// Go back one page.
    @MainActor public func previous() { _previous() }

    /// Finish/close the walkthrough.
    @MainActor public func finish() { _finish() }

    /// Convenience: calling the action advances.
    @MainActor public func callAsFunction() { _advance() }
}

private struct WalkthroughAdvanceKey: EnvironmentKey {
    static let defaultValue = WalkthroughAdvanceAction()
}

public extension EnvironmentValues {
    /// A navigation action available to custom pages. The walkthrough injects a
    /// live action per page; outside a walkthrough it is a no-op.
    var walkthroughAdvance: WalkthroughAdvanceAction {
        get { self[WalkthroughAdvanceKey.self] }
        set { self[WalkthroughAdvanceKey.self] = newValue }
    }
}
