//
//  WalkthroughView.swift
//  VXWalkthrough
//
//  The public SwiftUI entry point.
//

import SwiftUI

/// A declarative, themeable onboarding / walkthrough view.
///
/// ```swift
/// WalkthroughView(
///     Walkthrough {
///         InfoPage("welcome", title: "Welcome", image: .named("walkthrough_0"))
///         ActionPage("get-started", title: "Ready?", buttonTitle: "Let's go")
///     }
/// )
/// .onFinish { dismiss() }
/// ```
public struct WalkthroughView: View {
    private let walkthrough: Walkthrough
    private var showsClose: Bool = true
    private var onFinish: (@MainActor () -> Void)?
    private var onPageChange: (@MainActor (Int) -> Void)?
    private var onAction: (@MainActor (WalkthroughAction) -> Void)?
    private var actionHandler: WalkthroughActionHandler?
    private var customProviders: [String: @MainActor (WalkthroughPageProxy) -> AnyView] = [:]

    @State private var model: WalkthroughModel?

    public init(_ walkthrough: Walkthrough) {
        self.walkthrough = walkthrough
    }

    public var body: some View {
        ZStack {
            if let model {
                WalkthroughContainer(
                    model: model,
                    showsClose: showsClose,
                    customProviders: customProviders
                )
            } else {
                walkthrough.theme.background.ignoresSafeArea()
            }
        }
        .walkthroughTheme(walkthrough.theme)
        .task(id: walkthrough) {
            let model = WalkthroughModel(walkthrough: walkthrough)
            model.onFinish = onFinish
            model.onPageChange = onPageChange
            model.onAction = onAction
            model.actionHandler = actionHandler
            self.model = model
        }
    }

    // MARK: Modifiers

    /// Called when the walkthrough finishes (last page advanced or closed).
    public func onFinish(_ action: @escaping @MainActor () -> Void) -> Self {
        var copy = self
        copy.onFinish = action
        return copy
    }

    /// Called whenever the visible page changes.
    public func onPageChange(_ action: @escaping @MainActor (Int) -> Void) -> Self {
        var copy = self
        copy.onPageChange = action
        return copy
    }

    /// Observe interactive page actions (fire-and-forget).
    public func onAction(_ action: @escaping @MainActor (WalkthroughAction) -> Void) -> Self {
        var copy = self
        copy.onAction = action
        return copy
    }

    /// Handle interactive page actions asynchronously, returning a `StepOutcome`
    /// that drives the originating page's state and navigation.
    public func actionHandler(_ handler: @escaping WalkthroughActionHandler) -> Self {
        var copy = self
        copy.actionHandler = handler
        return copy
    }

    /// Whether to show the close button (default `true`).
    public func showsCloseButton(_ shows: Bool) -> Self {
        var copy = self
        copy.showsClose = shows
        return copy
    }

    /// Registers a host-provided SwiftUI page for a `.custom(contentID:)` step.
    public func walkthroughCustomPage<Content: View>(
        _ contentID: String,
        @ViewBuilder _ content: @escaping @MainActor (WalkthroughPageProxy) -> Content
    ) -> Self {
        var copy = self
        copy.customProviders[contentID] = { proxy in AnyView(content(proxy)) }
        return copy
    }
}

/// A DSL component for a host-provided SwiftUI page.
public struct CustomPage: WalkthroughStepConvertible, Sendable {
    public var id: String
    public var sort: Int
    public var theme: WalkthroughTheme?

    public init(_ id: String, sort: Int = 0, theme: WalkthroughTheme? = nil) {
        self.id = id
        self.sort = sort
        self.theme = theme
    }

    public func makeSteps() -> [WalkthroughStep] {
        [WalkthroughStep(id: id, kind: .custom(contentID: id), sort: sort, theme: theme)]
    }
}
