//
//  ConfigurationTests.swift
//  VXWalkthroughTests
//
//  Covers the additive 2.3.0 configuration knobs: extended theme (button /
//  indicator / nav), LoginSpec per-field controls, ActionSpec button style,
//  the walkthroughAdvance hook, and per-step theme overrides. Every addition is
//  optional and defaults to the pre-2.3.0 behavior.
//

import Foundation
import SwiftUI
import Testing
@testable import VXWalkthrough

@MainActor
@Suite("Theme button / indicator / nav (2.3.0)")
struct ThemeConfigurationTests {
    @Test("New theme knobs default to nil (zero behavior change)")
    func defaultsAreNil() {
        let theme = WalkthroughTheme.default
        #expect(theme.actionButtonStyle == nil)
        #expect(theme.pageIndicatorColor == nil)
        #expect(theme.pageIndicatorSelectedColor == nil)
        #expect(theme.navControlTint == nil)
    }

    @Test("resolvedActionButtonStyle falls back to accent / white / buttonCornerRadius")
    func resolvedButtonFallback() {
        let theme = WalkthroughTheme(accent: .red, buttonCornerRadius: 20)
        let style = theme.resolvedActionButtonStyle
        #expect(style.background == .red)
        #expect(style.foreground == .white)
        #expect(style.cornerStyle == .radius(20))
    }

    @Test("An explicit actionButtonStyle wins over the fallback")
    func resolvedButtonOverride() {
        let custom = WalkthroughTheme.WalkthroughButtonStyle(
            background: .green, foreground: .black, cornerStyle: .capsule
        )
        let theme = WalkthroughTheme(accent: .red, actionButtonStyle: custom)
        #expect(theme.resolvedActionButtonStyle == custom)
        #expect(theme.resolvedActionButtonStyle.cornerStyle == .capsule)
    }

    @Test("Nav tint and selected indicator fall back to titleColor")
    func resolvedNavAndIndicator() {
        let theme = WalkthroughTheme(titleColor: .yellow)
        #expect(theme.resolvedNavControlTint == .yellow)
        #expect(theme.resolvedPageIndicatorSelectedColor == .yellow)
    }

    @Test("Explicit nav / indicator colors are honored")
    func explicitNavAndIndicator() {
        let theme = WalkthroughTheme(
            titleColor: .yellow,
            pageIndicatorColor: .gray,
            pageIndicatorSelectedColor: .blue,
            navControlTint: .pink
        )
        #expect(theme.resolvedNavControlTint == .pink)
        #expect(theme.resolvedPageIndicatorSelectedColor == .blue)
        #expect(theme.pageIndicatorColor == .gray)
    }
}

@Suite("LoginSpec per-field controls (2.3.0)")
struct LoginSpecConfigurationTests {
    @Test("Defaults preserve legacy behavior")
    func defaults() {
        let spec = LoginSpec()
        #expect(spec.loginPlaceholder == nil)
        #expect(spec.passwordPlaceholder == nil)
        #expect(spec.loginSecure == false)
        #expect(spec.passwordSecure == true)
        #expect(spec.scanTitle == nil)
    }

    @Test("Per-field placeholders fall back to the shared placeholder")
    func placeholderFallback() {
        let shared = LoginSpec(placeholder: "shared")
        #expect(shared.resolvedLoginPlaceholder == "shared")
        #expect(shared.resolvedPasswordPlaceholder == "shared")

        let perField = LoginSpec(
            placeholder: "shared",
            loginPlaceholder: "info@domain.com",
            passwordPlaceholder: "xxxx-xxxx-xxxx"
        )
        #expect(perField.resolvedLoginPlaceholder == "info@domain.com")
        #expect(perField.resolvedPasswordPlaceholder == "xxxx-xxxx-xxxx")
    }

    @Test("LoginPage DSL threads the new fields into its spec")
    func dslThreadsFields() {
        let walkthrough = Walkthrough {
            LoginPage(
                loginPlaceholder: "info@domain.com",
                passwordPlaceholder: "xxxx-xxxx-xxxx",
                passwordSecure: false,
                scanEnabled: true,
                scanTitle: "Scan voucher"
            )
        }
        guard case let .login(spec) = walkthrough.steps[0].kind else {
            Issue.record("expected login kind")
            return
        }
        #expect(spec.resolvedLoginPlaceholder == "info@domain.com")
        #expect(spec.resolvedPasswordPlaceholder == "xxxx-xxxx-xxxx")
        #expect(spec.passwordSecure == false)
        #expect(spec.scanTitle == "Scan voucher")
    }
}

@Suite("ActionSpec button style (2.3.0)")
struct ActionSpecConfigurationTests {
    @Test("ActionSpec.buttonStyle defaults to nil")
    func defaultNil() {
        #expect(ActionSpec().buttonStyle == nil)
    }

    @Test("ActionPage DSL carries a per-step button style")
    func dslCarriesStyle() {
        let style = WalkthroughTheme.WalkthroughButtonStyle(background: .orange)
        let walkthrough = Walkthrough {
            ActionPage("cta", buttonTitle: "Go", buttonStyle: style)
        }
        guard case let .action(spec) = walkthrough.steps[0].kind else {
            Issue.record("expected action kind")
            return
        }
        #expect(spec.buttonStyle == style)
    }
}

@MainActor
@Suite("walkthroughAdvance hook (2.3.0)")
struct WalkthroughAdvanceTests {
    @Test("The action forwards advance / previous / finish")
    func forwards() {
        var advanced = 0
        var previous = 0
        var finished = 0
        let action = WalkthroughAdvanceAction(
            advance: { advanced += 1 },
            previous: { previous += 1 },
            finish: { finished += 1 }
        )

        action()            // callAsFunction -> advance
        action.advance()
        action.previous()
        action.finish()

        #expect(advanced == 2)
        #expect(previous == 1)
        #expect(finished == 1)
    }

    @Test("Default environment action is a no-op")
    func defaultNoop() {
        let action = WalkthroughAdvanceAction()
        action()
        action.finish()
        // No crash / no observable effect is the contract.
    }
}

@Suite("Per-step theme override (2.3.0)")
struct StepThemeOverrideTests {
    @Test("Steps default to no theme override")
    func defaultNil() {
        let walkthrough = Walkthrough {
            InfoPage("a", title: "A")
        }
        #expect(walkthrough.steps[0].theme == nil)
    }

    @Test("A per-step theme is threaded through every page kind")
    func threadedThroughPages() {
        let override = WalkthroughTheme(background: .purple, titleColor: .white)
        let walkthrough = Walkthrough {
            InfoPage("info", title: "A", theme: override)
            ActionPage("action", buttonTitle: "Go", theme: override)
            LoginPage("login", theme: override)
            PermissionPage(.notifications, theme: override)
            CustomPage("custom", theme: override)
        }
        #expect(walkthrough.steps.allSatisfy { $0.theme == override })
    }
}
