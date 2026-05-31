//
//  WalkthroughHostingController.swift
//  VXWalkthroughUIKit
//
//  UIKit convenience for presenting a SwiftUI `WalkthroughView`.
//

#if canImport(UIKit)

    import SwiftUI
    import UIKit
    import VXWalkthrough

    /// Hosts a `WalkthroughView` for presentation from UIKit code.
    ///
    /// ```swift
    /// let walkthrough = Walkthrough {
    ///     InfoPage("welcome", title: "Welcome")
    ///     ActionPage("go", title: "Ready?", buttonTitle: "Start")
    /// }
    /// let vc = WalkthroughHostingController(walkthrough)
    /// present(vc, animated: true)
    /// ```
    @MainActor
    public final class WalkthroughHostingController: UIHostingController<AnyView> {
        /// - Parameters:
        ///   - walkthrough: The walkthrough to present.
        ///   - onFinish: Called when the walkthrough finishes. Defaults to
        ///     dismissing this controller.
        ///   - actionHandler: Optional async handler for interactive page actions.
        ///   - configure: Optional transform to apply additional view modifiers
        ///     (custom pages, scanner, permission requester, etc.).
        public init(
            _ walkthrough: Walkthrough,
            onFinish: (@MainActor () -> Void)? = nil,
            actionHandler: WalkthroughActionHandler? = nil,
            configure: (@MainActor (WalkthroughView) -> AnyView)? = nil
        ) {
            super.init(rootView: AnyView(EmptyView()))

            var view = WalkthroughView(walkthrough)
            if let actionHandler {
                view = view.actionHandler(actionHandler)
            }
            let finished = view.onFinish { [weak self] in
                if let onFinish {
                    onFinish()
                } else {
                    self?.dismiss(animated: true)
                }
            }

            rootView = configure?(finished) ?? AnyView(finished)
            modalPresentationStyle = .fullScreen
        }

        @available(*, unavailable)
        @MainActor required dynamic init?(coder _: NSCoder) {
            fatalError("init(coder:) is not supported")
        }
    }

#endif
