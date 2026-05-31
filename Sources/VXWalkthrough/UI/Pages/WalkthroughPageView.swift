//
//  WalkthroughPageView.swift
//  VXWalkthrough
//
//  Resolves a step's `kind` to the appropriate page view. Kinds without a
//  dedicated view yet fall back to a functional action page; dedicated views
//  are introduced in later phases.
//

import SwiftUI

struct WalkthroughPageView: View {
    let step: WalkthroughStep
    let proxy: WalkthroughPageProxy
    let customProviders: [String: @MainActor (WalkthroughPageProxy) -> AnyView]

    var body: some View {
        switch step.kind {
        case .info:
            InfoPageView(step: step)
        case let .action(spec):
            ActionPageView(step: step, buttonTitle: spec.buttonTitle, proxy: proxy)
        case let .custom(contentID):
            if let provider = customProviders[contentID] {
                provider(proxy)
            } else {
                InfoPageView(step: step)
            }
        default:
            // Functional placeholder until the kind's dedicated view ships.
            ActionPageView(step: step, buttonTitle: fallbackButtonTitle, proxy: proxy)
        }
    }

    private var fallbackButtonTitle: String {
        switch step.kind {
        case let .input(spec): spec.buttonTitle
        case let .login(spec): spec.buttonTitle
        case let .signup(spec): spec.buttonTitle
        case let .picker(spec): spec.buttonTitle
        case let .permission(spec): spec.buttonTitle
        default: "Continue"
        }
    }
}
