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
    let action: () -> Void

    @Environment(\.walkthroughTheme) private var theme

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title).opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView().tint(.white)
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(theme.accent, in: .rect(cornerRadius: theme.buttonCornerRadius))
            .opacity(isEnabled ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .accessibilityIdentifier("walkthrough.primaryButton")
    }
}
