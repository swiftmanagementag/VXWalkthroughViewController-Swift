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

                // A SECOND route to the same outcome — e.g. buy instead of
                // signing in, where a purchase also unlocks the sets.
                //
                // ⚠️ BELOW the sign-in row, not beside it. The scan button shares
                // that row because it is the same action by another input; this is
                // a different action, and putting it alongside reads as a third way
                // to sign in.
                // ⛔ It emits `.action`, not a new payload case: the primary here
                // emits `.login`, so `.action` is unambiguous on this page, and a
                // new case would force every existing host to handle one it can
                // never receive.
                if let secondary = spec.secondaryTitle, !secondary.isEmpty {
                    Button(secondary) {
                        focus = nil
                        Task { await proxy.submit(.action) }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.accent)
                    .frame(maxWidth: .infinity, minHeight: Self.actionHeight)
                    .accessibilityIdentifier("walkthrough.login.secondary")
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

    /// Shared with `WalkthroughPrimaryButton`'s own metrics — the two buttons sit side
    /// by side, so a number that lives in only one of them drifts the moment either is
    /// touched.
    private static let actionHeight: CGFloat = 50
    private static let actionCornerRadius: CGFloat = 12

    @ViewBuilder
    private var scanButton: some View {
        Button {
            Task { await scan() }
        } label: {
            if let scanTitle = spec.scanTitle, !scanTitle.isEmpty {
                Label(scanTitle, systemImage: "qrcode.viewfinder")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: Self.actionHeight)
                    .background(theme.accent, in: .rect(cornerRadius: Self.actionCornerRadius))
            } else {
                Image(systemName: "qrcode.viewfinder")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: Self.actionHeight, height: Self.actionHeight)
                    .background(theme.accent, in: .rect(cornerRadius: Self.actionCornerRadius))
            }
        }
        // ⚠️ `.plain`, matching `WalkthroughPrimaryButton`. It was `.bordered`, which adds
        // its OWN padding around a label already at `minHeight 50` — so the scan button
        // rendered TALLER than the Login button beside it, which is the mismatch the
        // operator's screenshot showed. Owning the background is what makes the two
        // agree, and it is also what allows a solid accent with a white label: a
        // `.bordered` button tints its TEXT, never its fill.
        .buttonStyle(.plain)
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
            // 👤 Operator 2026-09-04: the inputs should be a little taller with rounded
            // edges. `.roundedBorder` is the SYSTEM style — short, hairline-bordered, and
            // not themeable — so the chrome is owned here instead.
            field()
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(theme.fieldBackground, in: .rect(cornerRadius: 10))
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
