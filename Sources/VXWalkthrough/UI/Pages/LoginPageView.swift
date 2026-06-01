//
//  LoginPageView.swift
//  VXWalkthrough
//

import SwiftUI

/// Email + password login page with optional QR scan.
struct LoginPageView: View {
    let step: WalkthroughStep
    let spec: LoginSpec
    let proxy: WalkthroughPageProxy

    @State private var login: String = ""
    @State private var password: String = ""
    @FocusState private var focus: Field?
    @Environment(\.walkthroughTheme) private var theme
    @Environment(\.walkthroughScanHandler) private var scanHandler

    private enum Field { case login, password }

    private var isValid: Bool {
        Validation.isValidEmail(login) && !password.isEmpty
    }

    private var showsScan: Bool { spec.scanEnabled && scanHandler != nil }

    var body: some View {
        PageScaffold(step: step, state: proxy.state) {
            VStack(spacing: 16) {
                labeledField(spec.loginPrompt) {
                    TextField(spec.placeholder.isEmpty ? "info@domain.com" : spec.placeholder, text: $login)
                        .focused($focus, equals: .login)
                        .emailFieldConfiguration()
                        .accessibilityIdentifier("walkthrough.login.email")
                }

                labeledField(spec.passwordPrompt) {
                    SecureField(spec.placeholder, text: $password)
                        .focused($focus, equals: .password)
                        .passwordFieldConfiguration()
                        .accessibilityIdentifier("walkthrough.login.password")
                }

                HStack(spacing: 12) {
                    WalkthroughPrimaryButton(
                        title: spec.buttonTitle,
                        isLoading: proxy.state.isLoading,
                        isEnabled: isValid
                    ) {
                        focus = nil
                        Task { await proxy.submit(.login(Credentials(login: login, password: password))) }
                    }

                    if showsScan {
                        Button {
                            Task { await scan() }
                        } label: {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.title2)
                                .frame(width: 50, height: 50)
                        }
                        .buttonStyle(.bordered)
                        .tint(theme.accent)
                        .accessibilityIdentifier("walkthrough.login.scan")
                        .accessibilityLabel("Scan code")
                    }
                }
            }
        }
        .onAppear {
            if login.isEmpty { login = spec.loginValue }
            if password.isEmpty { password = spec.passwordValue }
        }
    }

    private func scan() async {
        guard let scanHandler, let code = await scanHandler() else { return }
        password = code
    }

    @ViewBuilder
    private func labeledField(_ prompt: String, @ViewBuilder field: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if !prompt.isEmpty {
                Text(prompt).font(.caption).foregroundStyle(theme.bodyColor)
            }
            field().textFieldStyle(.roundedBorder)
        }
    }
}

extension View {
    @ViewBuilder
    func emailFieldConfiguration() -> some View {
        #if os(iOS)
            keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        #else
            self
        #endif
    }

    @ViewBuilder
    func passwordFieldConfiguration() -> some View {
        #if os(iOS)
            textContentType(.password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        #else
            self
        #endif
    }
}
