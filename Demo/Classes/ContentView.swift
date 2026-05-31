//
//  ContentView.swift
//  VXWalkthroughDemo
//

import SwiftUI
import VXWalkthrough
import VXWalkthroughScanner

struct ContentView: View {
    @State private var showWalkthrough = false
    @State private var lastEvent = "—"
    private let gate = WalkthroughPresentationGate()

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("VXWalkthrough Demo")
                .font(.largeTitle.bold())

            Text("Last action: \(lastEvent)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Show Walkthrough") { showWalkthrough = true }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding()
        .onAppear {
            // Present automatically the first time per app version.
            if gate.shouldPresent {
                showWalkthrough = true
                gate.setShown()
            }
        }
        .fullScreenCover(isPresented: $showWalkthrough) {
            WalkthroughView(demoWalkthrough)
                .actionHandler { action in
                    lastEvent = action.payload.summary
                    switch action.payload {
                    case let .login(creds):
                        return creds.password.isEmpty ? .failure("Enter a password") : .success("Welcome, \(creds.login)!")
                    default:
                        return .advance
                    }
                }
                .onPageChange { lastEvent = "page \($0)" }
                .onFinish { showWalkthrough = false }
                .walkthroughPermissionRequester(SystemPermissionRequester())
                .walkthroughQRScanner()
        }
    }

    private var demoWalkthrough: Walkthrough {
        Walkthrough(theme: theme) {
            InfoPage(
                "welcome",
                title: "See *No* Evil",
                body: "A modern SwiftUI onboarding flow.",
                image: .system("eye.slash")
            )
            InfoPage("hear", title: "Hear No Evil", image: .system("ear"))

            PickerPage(
                "plan",
                title: "Choose a plan",
                options: [
                    PickerOption(id: "free", title: "Free"),
                    PickerOption(id: "pro", title: "Pro"),
                    PickerOption(id: "max", title: "Max", isAvailable: false),
                ],
                selectedID: "free"
            )

            LoginPage(
                title: "Sign in",
                image: .system("person.crop.circle"),
                buttonTitle: "Sign In",
                scanEnabled: true
            )

            PermissionPage(
                .notifications,
                title: "Stay in the loop",
                image: .system("bell.badge"),
                rationale: "We'll let you know about important updates.",
                grantedMessage: "Thanks!",
                deniedMessage: "No problem — you can change this later."
            )

            ActionPage(
                "done",
                title: "You're all set!",
                image: .system("checkmark.seal"),
                buttonTitle: "Get Started"
            )
        }
    }

    private var theme: WalkthroughTheme {
        WalkthroughTheme(
            background: Color(red: 0.05, green: 0.07, blue: 0.12),
            accent: .blue,
            imageStyle: .round
        )
    }
}

private extension WalkthroughAction.Payload {
    var summary: String {
        switch self {
        case .action: "action"
        case let .input(values): "input(\(values.count) fields)"
        case let .login(creds): "login(\(creds.login))"
        case let .signup(email): "signup(\(email))"
        case let .picker(id): "picker(\(id))"
        case let .permission(kind): "permission(\(kind.rawValue))"
        }
    }
}

#Preview {
    ContentView()
}
