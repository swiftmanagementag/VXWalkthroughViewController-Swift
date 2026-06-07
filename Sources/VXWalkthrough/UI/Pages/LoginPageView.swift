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
                    loginField
                }

                labeledField(spec.passwordPrompt) {
                    passwordField
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
                        scanButton
                    }
                }
            }
        }
        .onAppear {
            if login.isEmpty { login = spec.loginValue }
            if password.isEmpty { password = spec.passwordValue }
        }
    }

    private var loginPlaceholder: String {
        let resolved = spec.resolvedLoginPlaceholder
        return resolved.isEmpty ? "info@domain.com" : resolved
    }

    @ViewBuilder
    private var loginField: some View {
        if spec.loginSecure {
            SecureField(loginPlaceholder, text: $login)
                .focused($focus, equals: .login)
                .accessibilityIdentifier("walkthrough.login.email")
        } else {
            TextField(loginPlaceholder, text: $login)
                .focused($focus, equals: .login)
                .emailFieldConfiguration()
                .accessibilityIdentifier("walkthrough.login.email")
        }
    }

    @ViewBuilder
    private var passwordField: some View {
        if spec.passwordSecure {
            SecureField(spec.resolvedPasswordPlaceholder, text: $password)
                .focused($focus, equals: .password)
                .passwordFieldConfiguration()
                .accessibilityIdentifier("walkthrough.login.password")
        } else {
            TextField(spec.resolvedPasswordPlaceholder, text: $password)
                .focused($focus, equals: .password)
                .accessibilityIdentifier("walkthrough.login.password")
        }
    }

    @ViewBuilder
    private var scanButton: some View {
        Button {
            Task { await scan() }
        } label: {
            if let scanTitle = spec.scanTitle, !scanTitle.isEmpty {
                Label(scanTitle, systemImage: "qrcode.viewfinder")
                    .font(.headline)
                    .frame(minHeight: 50)
                    .padding(.horizontal, 12)
            } else {
                Image(systemName: "qrcode.viewfinder")
                    .font(.title2)
                    .frame(width: 50, height: 50)
            }
        }
        .buttonStyle(.bordered)
        .tint(theme.accent)
        .accessibilityIdentifier("walkthrough.login.scan")
        .accessibilityLabel(spec.scanTitle.map { $0.isEmpty ? "Scan code" : $0 } ?? "Scan code")
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
