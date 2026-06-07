//
//  ContentView.swift
//  VXWalkthroughDemo
//

import SwiftUI
import UserNotifications
import VXWalkthrough
import VXWalkthroughScanner

// The core no longer ships a system permission requester (so apps that don't
// request permissions link no privacy frameworks). Production apps should add
// the `VXWalkthroughPermissions` product with the traits they need and inject
// `SystemPermissionRequester()`. This demo keeps its single dependency on the
// core by providing a tiny inline notifications requester instead.
private struct DemoNotificationsRequester: PermissionRequesting {
    func status(for kind: PermissionKind) async -> PermissionStatus {
        guard kind == .notifications else { return .unavailable }
        switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral: return .granted
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    @discardableResult
    func request(_ kind: PermissionKind) async -> PermissionStatus {
        guard kind == .notifications else { return .unavailable }
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted ? .granted : .denied
        } catch {
            return .denied
        }
    }
}

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
                .walkthroughCustomPage("ready") { _ in DemoReadyPage() }
                .walkthroughPermissionRequester(DemoNotificationsRequester())
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

            // Aspect-fit demo: wide artwork shows in full (no crop) because the
            // theme uses `imageStyle: .fit`.
            InfoPage(
                "wide",
                title: "Wide artwork, un-cropped",
                body: "`ImageStyle.fit` shows the whole illustration.",
                image: .system("photo.on.rectangle.angled")
            )

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
                passwordPrompt: "Voucher code",
                loginPlaceholder: "info@domain.com",
                passwordPlaceholder: "xxxx-xxxx-xxxx",
                passwordSecure: false,
                buttonTitle: "Sign In",
                scanEnabled: true,
                scanTitle: "Scan"
            )

            // 2.3: a custom page that drives navigation via the environment.
            CustomPage("ready")

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
            // `.fit` renders wide artwork in full without cropping.
            imageStyle: .fit,
            // 2.3: theme the CTA, page dots, and nav controls explicitly.
            actionButtonStyle: .init(background: .cyan, foreground: .black, cornerStyle: .capsule),
            pageIndicatorColor: .white.opacity(0.3),
            pageIndicatorSelectedColor: .cyan,
            navControlTint: .cyan
        )
    }
}

/// A custom page that drives navigation through the `walkthroughAdvance`
/// environment action rather than a captured proxy.
private struct DemoReadyPage: View {
    @Environment(\.walkthroughAdvance) private var advance
    @Environment(\.walkthroughTheme) private var theme

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.thumbsup")
                .font(.system(size: 56))
                .foregroundStyle(theme.titleColor)
            Text("Almost there")
                .font(theme.titleFont)
                .foregroundStyle(theme.titleColor)
            Button("Finish") { advance.finish() }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
