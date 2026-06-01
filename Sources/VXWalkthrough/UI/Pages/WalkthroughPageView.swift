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
        case let .input(spec):
            InputPageView(step: step, spec: spec, proxy: proxy)
        case let .action(spec):
            ActionPageView(step: step, buttonTitle: spec.buttonTitle, proxy: proxy)
        case let .picker(spec):
            PickerPageView(step: step, spec: spec, proxy: proxy)
        case let .login(spec):
            LoginPageView(step: step, spec: spec, proxy: proxy)
        case let .signup(spec):
            SignupPageView(step: step, spec: spec, proxy: proxy)
        case let .permission(spec):
            PermissionPageView(step: step, spec: spec, proxy: proxy)
        case let .custom(contentID):
            if let provider = customProviders[contentID] {
                provider(proxy)
            } else {
                InfoPageView(step: step)
            }
        }
    }
}
