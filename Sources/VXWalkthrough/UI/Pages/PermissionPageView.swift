//
//  PermissionPageView.swift
//  VXWalkthrough
//

import SwiftUI

/// Requests a system permission, driving page state from the result.
struct PermissionPageView: View {
    let step: WalkthroughStep
    let spec: PermissionSpec
    let proxy: WalkthroughPageProxy

    @Environment(\.walkthroughTheme) private var theme
    @Environment(\.walkthroughPermissionRequester) private var requester

    var body: some View {
        PageScaffold(step: step, state: proxy.state) {
            VStack(spacing: 16) {
                if !spec.rationale.isEmpty {
                    Text(spec.rationale)
                        .font(theme.bodyFont)
                        .foregroundStyle(theme.bodyColor)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("walkthrough.permission.rationale")
                }

                WalkthroughPrimaryButton(
                    title: spec.buttonTitle,
                    isLoading: proxy.state.isLoading
                ) {
                    Task { await request() }
                }
            }
        }
    }

    private func request() async {
        proxy.setState(.loading)
        let status = await requester.request(spec.kind)
        proxy.emit(.permission(spec.kind))
        proxy.apply(PermissionResolver.outcome(for: status, spec: spec))
    }
}
