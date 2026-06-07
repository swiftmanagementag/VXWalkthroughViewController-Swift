//
//  WalkthroughPrimaryButton.swift
//  VXWalkthrough
//

import SwiftUI

/// The standard primary call-to-action button used by interactive pages.
struct WalkthroughPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isEnabled: Bool = true
    /// Optional per-button style. When `nil`, the theme's
    /// `resolvedActionButtonStyle` is used.
    var styleOverride: WalkthroughTheme.WalkthroughButtonStyle? = nil
    let action: () -> Void

    @Environment(\.walkthroughTheme) private var theme

    private var style: WalkthroughTheme.WalkthroughButtonStyle {
        styleOverride ?? theme.resolvedActionButtonStyle
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title).opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView().tint(style.foreground)
                }
            }
            .font(.headline)
            .foregroundStyle(style.foreground)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(buttonBackground)
            .opacity(isEnabled ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .accessibilityIdentifier("walkthrough.primaryButton")
    }

    @ViewBuilder
    private var buttonBackground: some View {
        switch style.cornerStyle {
        case let .radius(radius):
            style.background.clipShape(.rect(cornerRadius: radius))
        case .capsule:
            style.background.clipShape(.capsule)
        }
    }
}
