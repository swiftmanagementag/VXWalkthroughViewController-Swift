# VXWalkthrough

A modern, declarative **SwiftUI** framework for building app onboarding and
walkthrough flows. Display information, collect input, request permissions, and
drop in your own custom pages — all from a type-safe result-builder DSL.

> **Version 2.0** is a full rewrite for Swift 6 and SwiftUI. For the previous
> UIKit/storyboard API see the `1.x` releases and the
> [migration guide](docs/migration-guide.md).

## Features

- Declarative `Walkthrough { ... }` DSL — no storyboards, no dictionaries.
- Built-in page types: **info**, **input**, **login**, **signup**, **action**,
  **picker**, and **permission**.
- Full permission set: notifications, camera, microphone, photo library,
  location, contacts, and App Tracking Transparency.
- Host-extensible: inject your own SwiftUI pages with `CustomPage`.
- `async`/`await` action handling with a typed `StepOutcome` state machine.
- Themeable, with optional iOS 26 **Liquid Glass** chrome.
- Accessible: Dynamic Type, VoiceOver labels, reduce-motion support, stable
  accessibility identifiers.
- Optional QR/barcode scanning and UIKit interop as separate products.
- Zero required dependencies.

## Requirements

- iOS 17+ / iPadOS 17+ / Mac Catalyst 17+ (built with the iOS 26 SDK)
- Swift 6 / Xcode 26

## Installation

Swift Package Manager:

```swift
.package(url: "https://github.com/swiftmanagementag/VXWalkthroughViewController-Swift", .upToNextMajor(from: "2.0.0"))
```

Products:

- `VXWalkthrough` — the core SwiftUI framework.
- `VXWalkthroughScanner` — optional QR/barcode scanning.
- `VXWalkthroughUIKit` — optional `UIHostingController` convenience.

## Usage

```swift
import SwiftUI
import VXWalkthrough

struct OnboardingView: View {
    @Binding var isPresented: Bool

    var body: some View {
        WalkthroughView(
            Walkthrough(theme: .default) {
                InfoPage("welcome", title: "See *No* Evil", image: .named("walkthrough_0"))
                InfoPage("hear", title: "Hear No Evil", image: .named("walkthrough_1"))

                LoginPage(loginPrompt: "Email", passwordPrompt: "Password", scanEnabled: true)

                PermissionPage(.notifications, rationale: "Stay up to date")

                ActionPage("done", title: "You're all set!", buttonTitle: "Get Started")
            }
        )
        .actionHandler { action in
            switch action.payload {
            case let .login(creds):
                do { try await api.signIn(creds); return .success("Welcome back!") }
                catch { return .failure("Could not sign in") }
            default:
                return .advance
            }
        }
        .onFinish { isPresented = false }
    }
}
```

### Show it once per app version

```swift
let gate = WalkthroughPresentationGate()
if gate.shouldPresent {
    showOnboarding = true
    gate.setShown()
}
```

### QR scanning

```swift
import VXWalkthroughScanner

WalkthroughView(walkthrough)   // a LoginPage with scanEnabled: true
    .walkthroughQRScanner()
```

On capable devices this uses VisionKit's `DataScannerViewController`, falling
back automatically to an AVFoundation scanner on Mac Catalyst or older hardware.
Voucher URLs are parsed as before (the `voucher` query item becomes the value).

### UIKit hosts

```swift
import VXWalkthroughUIKit

let vc = WalkthroughHostingController(walkthrough)
present(vc, animated: true)
```

### Custom pages

```swift
Walkthrough { CustomPage("promo") }

WalkthroughView(walkthrough)
    .walkthroughCustomPage("promo") { proxy in
        MyPromoView(onContinue: proxy.advance)
    }
```

### Localized auto-population (parity with 1.x)

Define `walkthrough_0`, `walkthrough_1`, … in your string catalog and:

```swift
let walkthrough = Walkthrough(steps: LocalizedStepsLoader().load())
```

## Documentation

- [Migration guide (1.x -> 2.0)](docs/migration-guide.md)
- [Modernization plan](docs/ios26-refactor-plan.md)
- DocC: build documentation for the `VXWalkthrough` scheme in Xcode.

## Credits

VXWalkthrough is brought to you by
[Swift Management AG](https://www.swiftmanagement.ch) and contributors. The
original UIKit implementation was based on Yari D'areglia's BWWalkthrough and
Sam Vermette's SVWebViewController.

## License

VXWalkthrough is released under the MIT License. See [LICENSE](LICENSE) for the
full text.
