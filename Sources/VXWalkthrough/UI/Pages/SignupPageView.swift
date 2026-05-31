//
//  SignupPageView.swift
//  VXWalkthrough
//

import SwiftUI

/// Email signup page.
struct SignupPageView: View {
    let step: WalkthroughStep
    let spec: SignupSpec
    let proxy: WalkthroughPageProxy

    @State private var email: String = ""
    @FocusState private var focused: Bool
    @Environment(\.walkthroughTheme) private var theme

    private var isValid: Bool { Validation.isValidEmail(email) }

    var body: some View {
        PageScaffold(step: step, state: proxy.state) {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    if !spec.emailPrompt.isEmpty {
                        Text(spec.emailPrompt).font(.caption).foregroundStyle(theme.bodyColor)
                    }
                    TextField(spec.placeholder.isEmpty ? "info@domain.com" : spec.placeholder, text: $email)
                        .textFieldStyle(.roundedBorder)
                        .focused($focused)
                        .emailFieldConfiguration()
                        .accessibilityIdentifier("walkthrough.signup.email")
                }

                WalkthroughPrimaryButton(
                    title: spec.buttonTitle,
                    isLoading: proxy.state.isLoading,
                    isEnabled: isValid
                ) {
                    focused = false
                    Task { await proxy.submit(.signup(email: email)) }
                }
            }
        }
        .onAppear { if email.isEmpty { email = spec.emailValue } }
    }
}
