//
//  ActionPageView.swift
//  VXWalkthrough
//

import SwiftUI

/// A page with a single primary call-to-action.
struct ActionPageView: View {
    let step: WalkthroughStep
    let buttonTitle: String
    var buttonStyle: WalkthroughTheme.WalkthroughButtonStyle? = nil
    let proxy: WalkthroughPageProxy

    var body: some View {
        PageScaffold(step: step, state: proxy.state) {
            WalkthroughPrimaryButton(
                title: buttonTitle,
                isLoading: proxy.state.isLoading,
                styleOverride: buttonStyle
            ) {
                Task { await proxy.submit(.action) }
            }
        }
    }
}
