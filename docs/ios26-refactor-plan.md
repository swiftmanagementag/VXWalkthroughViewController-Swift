# VXWalkthrough — iOS 26 / Swift 6 Modernization Plan

> Branch: `ios26_refactor`
> Status: Planning
> Owner: TBD
> Last updated: 2026-05-31

## 1. Goal

Fully rewrite `VXWalkthroughViewController-Swift` from a UIKit + Storyboard library
into a modern, declarative **SwiftUI** onboarding/walkthrough framework, while
preserving (and improving) the dynamic, extensible nature that makes it useful
across multiple apps:

- **Display information** (text + image + rich/markdown-ish styling).
- **Collect information** (login, signup, free-form input, pickers/选择).
- **Request permissions** (camera, notifications, location, tracking, etc.).
- **User-extensible** (host apps can inject their own SwiftUI pages and actions).

### Target platforms & toolchain

| Item | Current | Target |
| --- | --- | --- |
| Build toolchain | Swift 5.8 (tools) | **Swift 6.x (6.4 toolchain, Xcode 26 / iOS 26 SDK)** |
| Language mode | Swift 5 | **Swift 6 language mode** (full strict concurrency) |
| UI | UIKit + `.storyboard`/`.xib` | **SwiftUI** (declarative, multiplatform) |
| Min deployment | iOS 16 / Catalyst 14 | **iOS 17 / iPadOS 17 / Mac Catalyst 17** |
| Distribution | SPM (+ legacy CocoaPods notes) | **SPM-first**; CocoaPods deprecated |
| Dependencies | forked `QRCodeReader.swift` | **Zero required deps**; QR via AVFoundation/VisionKit in an optional target |

Deploying to iOS 17 unlocks the **Observation framework** (`@Observable`),
`ScrollView` scroll transitions, `TabView(.page)` paging, `PhaseAnimator`,
`ContentUnavailableView`, and Swift Concurrency without back-deployment hacks.

---

## 2. Current architecture (baseline)

A ~1,300-line UIKit library, storyboard-driven, configured through weakly-typed
`[String: Any]` dictionaries.

```
Sources/VXWalkthrough/
├─ VXWalkthroughViewController.swift          # Container: paging UIScrollView, page control, delegate, items dict
├─ VXWalkthroughPageViewController.swift       # Base page: image+title, bold markup, parallax animations, email validation
├─ VXWalkthroughPageLoginViewController.swift  # Email/password + QR scan (QRCodeReader dep)
├─ VXWalkthroughPageSignupViewController.swift # Email capture
├─ VXWalkthroughPageActionViewController.swift # Single action button
├─ VXWalkthroughPagePickerViewController.swift # Option carousel
└─ Resources/
   ├─ VXWalkthroughViewController.storyboard   # 601-line storyboard defining every page
   └─ *@2x.png                                 # Arrow / Go / Scan glyphs
Demo/                                          # .xib-based UIKit demo app
```

### Key behaviors to preserve (feature parity matrix)

| Capability | Current implementation | New home |
| --- | --- | --- |
| Horizontal paging | `UIScrollView` + manual VFL constraints | `TabView(.page)` / custom pager |
| Page control / next / prev / close | IBOutlets + `@IBAction` | SwiftUI controls + bindings |
| Parallax per-subview animation | `walkthroughDidScroll` + `CATransform3D` (linear/curve/zoom/inOut) | `scrollTransition` / `GeometryReader` effects |
| Title bold markup (`*x*`, `<b>x</b>`) | `NSRegularExpression` → `NSAttributedString` | `AttributedString` + Markdown |
| Round vs full-screen images | `roundImages` flag | `WalkthroughTheme.imageStyle` |
| Dynamic population from `Localizable.strings` (`walkthrough_0…n`) | `populate()` loop | Opt-in `LocalizedStepsLoader` |
| Item config | `[String: Any]` + `VXWalkthroughField` string keys | Strongly-typed `WalkthroughStep` models |
| Login (email/pwd) + QR scan | `VXWalkthroughPageLoginViewController` + `QRCodeReader` | `LoginPage` + optional `VXWalkthroughScanner` |
| Signup (email) | `VXWalkthroughPageSignupViewController` | `SignupPage` |
| Action button | `VXWalkthroughPageActionViewController` | `ActionPage` |
| Option picker carousel | `VXWalkthroughPagePickerViewController` | `PickerPage` |
| Success / error state per page | `VXWalkthroughField.success`/`.error` strings | `StepState` enum (`.idle/.loading/.success/.error`) |
| "Shown once per version" gate | `walkthroughShown()` via `UserDefaults` keyed by build | `WalkthroughPresentationGate` (injectable storage) |
| Delegate callbacks | `@objc` `VXWalkthroughViewControllerDelegate` | `async` actions + event closures / `AsyncStream` |
| Host extensibility | custom storyboard IDs + subclassing | `WalkthroughPage` protocol + `@ViewBuilder` injection |

### Problems being addressed

1. **Not SwiftUI** — storyboards/xibs are hard to theme, test, and reuse.
2. **Weakly typed config** — `[String: Any]` is error-prone and not `Sendable`.
3. **Unsound concurrency** — UIViewControllers declared `Sendable`; `@objc`
   delegate; manual `DispatchQueue` timing hacks. Will not pass Swift 6 strict
   concurrency cleanly.
4. **Fragile resource loading** — manual `Bundle` name guessing for images.
5. **Forked dependency** — `QRCodeReader.swift` fork adds maintenance + supply-chain risk.
6. **Manual keyboard handling** — `NotificationCenter` + frame shifting (SwiftUI handles this).
7. **Manual Auto Layout** via Visual Format Language strings.

---

## 3. Target architecture

A small, dependency-free SwiftUI core with an optional scanner add-on and an
optional UIKit-interop shim for incremental adoption in existing apps.

```
Package.swift                       # swift-tools 6.x, iOS/Catalyst v17, Swift 6 mode
Sources/
├─ VXWalkthrough/                   # Core SwiftUI framework (no external deps)
│  ├─ Model/
│  │  ├─ WalkthroughStep.swift      # Typed step model (Sendable, Identifiable)
│  │  ├─ WalkthroughPage.swift      # Protocol for custom pages
│  │  ├─ WalkthroughConfiguration.swift
│  │  ├─ WalkthroughTheme.swift     # Colors, fonts, image style, motion
│  │  └─ WalkthroughBuilder.swift   # @resultBuilder DSL
│  ├─ State/
│  │  ├─ WalkthroughModel.swift     # @Observable @MainActor coordinator
│  │  ├─ StepState.swift            # idle/loading/success/error
│  │  └─ WalkthroughPresentationGate.swift  # "shown per version" (injectable)
│  ├─ Pages/
│  │  ├─ InfoPage.swift             # display: image + styled title/body
│  │  ├─ InputPage.swift            # generic field collection
│  │  ├─ LoginPage.swift            # email/password
│  │  ├─ SignupPage.swift           # email
│  │  ├─ ActionPage.swift           # single CTA
│  │  ├─ PickerPage.swift           # option selection
│  │  └─ PermissionPage.swift       # permission request flow
│  ├─ UI/
│  │  ├─ WalkthroughView.swift      # Public entry SwiftUI view (the pager)
│  │  ├─ Pager.swift                # TabView(.page) wrapper + transitions
│  │  ├─ PageChrome.swift           # page indicator, next/prev/close, safe areas
│  │  └─ Effects/ParallaxModifier.swift
│  ├─ Permissions/
│  │  └─ PermissionRequesting.swift # protocol; default system implementations
│  ├─ Localization/
│  │  └─ LocalizedStepsLoader.swift # opt-in walkthrough_0…n loader (parity)
│  └─ Markup/AttributedTitle.swift  # *bold* / <b> / Markdown → AttributedString
│
├─ VXWalkthroughScanner/            # OPTIONAL target (AVFoundation/VisionKit QR)
│  └─ ScannerView.swift             # DataScannerViewController wrapper
│
└─ VXWalkthroughUIKit/              # OPTIONAL interop + back-compat shim
   ├─ WalkthroughHostingController.swift   # UIHostingController convenience
   └─ LegacyItemAdapter.swift              # [String:Any] → WalkthroughStep bridge

Tests/
├─ VXWalkthroughTests/              # Swift Testing — models, builder, gate, markup
└─ VXWalkthroughUITests/            # (Demo target) snapshot / smoke tests

Demo/                              # Rewritten SwiftUI multiplatform demo
```

### 3.1 Type-safe configuration (replaces `[String: Any]`)

```swift
public struct WalkthroughStep: Identifiable, Sendable {
    public let id: String
    public var kind: Kind
    public var title: AttributedTitle          // markdown / *bold* aware
    public var body: AttributedTitle?
    public var image: WalkthroughImage?         // .named / .system / .remote
    public var sort: Int

    public enum Kind: Sendable {
        case info
        case input(InputSpec)
        case login(LoginSpec)
        case signup(SignupSpec)
        case action(ActionSpec)
        case picker(PickerSpec)
        case permission(PermissionSpec)
        case custom(AnyWalkthroughPage)         // host-provided SwiftUI page
    }
}
```

### 3.2 Declarative builder DSL

```swift
let walkthrough = Walkthrough(theme: .branded) {
    InfoPage("welcome", title: "See *No* Evil", image: .named("walkthrough_0"))
    InfoPage("hear",    title: "Hear No Evil",  image: .named("walkthrough_1"))

    LoginPage(emailPrompt: "Email", passwordPrompt: "Password",
              scanEnabled: true) { credentials in
        try await api.signIn(credentials)       // async; throws → .error state
    }

    PermissionPage(.notifications, rationale: "Stay in the loop") { granted in
        analytics.log(.notificationsPermission(granted))
    }

    // Host extensibility: any SwiftUI view becomes a page
    CustomPage(id: "promo") { proxy in
        MyMarketingView(onContinue: proxy.advance)
    }
}
```

### 3.3 Presenting it

```swift
// SwiftUI
.sheet(isPresented: $showOnboarding) {
    WalkthroughView(walkthrough)
        .onFinish { showOnboarding = false }
}

// Version-gated convenience (parity with walkthroughShown())
if WalkthroughPresentationGate.shared.shouldPresent {
    showOnboarding = true
}

// UIKit host (existing apps) — via VXWalkthroughUIKit
let vc = WalkthroughHostingController(walkthrough)
present(vc, animated: true)
```

### 3.4 Concurrency model

- All UI types are `@MainActor`. `WalkthroughModel` is `@Observable @MainActor`.
- Config models (`WalkthroughStep`, specs, theme) are value types and `Sendable`.
- Page actions are `async throws` closures; the model drives `StepState`
  (`.loading` → `.success`/`.error`) and surfaces errors inline — replacing the
  old `success`/`error` string keys.
- Events exposed both as ergonomic closures (`onFinish`, `onPageChange`,
  `onAction`) and optionally an `AsyncStream<WalkthroughEvent>` for advanced hosts.
- No `@objc`, no `DispatchQueue.asyncAfter` timing hacks, no manual keyboard
  notification handling.

### 3.5 Theming & accessibility

- `WalkthroughTheme`: background, accent, title/body fonts, `imageStyle`
  (`.round` / `.fullBleed` / `.card`), motion profile, button shape. Injected via
  the SwiftUI environment. Optional iOS 26 **Liquid Glass** styling for chrome.
- Respect `@Environment(\.accessibilityReduceMotion)` to disable parallax.
- Dynamic Type, VoiceOver labels, and stable `accessibilityIdentifier`s on all
  interactive controls (next/prev/close/fields/buttons) for UI testing.

---

## 4. Migration phases

Phased delivery with tests after each phase (lowers integration risk).

### Phase 0 — Tooling & package skeleton
- Bump `Package.swift` to `swift-tools-version: 6.0+`, platforms `.iOS(.v17)`,
  `.macCatalyst(.v17)`; enable Swift 6 language mode; add `VXWalkthroughScanner`,
  `VXWalkthroughUIKit`, and test targets.
- Remove `QRCodeReader.swift` dependency from the core target.
- Add CI (GitHub Actions): build + test for iOS Simulator and Mac Catalyst.
- **Exit:** package resolves and builds empty targets on all platforms.

### Phase 1 — Core domain models
- `WalkthroughStep`, specs, `WalkthroughTheme`, `AttributedTitle` (markup parser),
  `@resultBuilder` DSL, `WalkthroughPresentationGate`, `LocalizedStepsLoader`.
- Unit tests (Swift Testing) for markup parsing, sort ordering, version gate,
  localized auto-population parity.
- **Exit:** models + DSL fully unit-tested, zero UI.

### Phase 2 — SwiftUI rendering engine
- `WalkthroughView`, `Pager` (`TabView(.page)`), `PageChrome`, parallax modifier,
  `InfoPage`. Wire `WalkthroughModel`.
- **Exit:** info-only walkthrough renders + pages on device/simulator + Catalyst.

### Phase 3 — Built-in interactive pages
- `InputPage`, `ActionPage`, `PickerPage` with `StepState` + async actions and
  SwiftUI keyboard handling.
- **Exit:** picker/action/input parity with originals.

### Phase 4 — Auth + permissions
- `LoginPage`, `SignupPage` (email validation via modern `/^…$/` regex literal),
  `PermissionPage` with `PermissionRequesting` protocol (notifications, camera,
  location, ATT) and default system implementations.
- **Exit:** login/signup/permission flows validated.

### Phase 5 — Optional scanner module
- `VXWalkthroughScanner` using VisionKit `DataScannerViewController` (fallback
  `AVCaptureMetadataOutput`); `LoginPage.scanEnabled` integrates when linked.
- **Exit:** QR scan works; core builds without the scanner target.

### Phase 6 — Public API + UIKit interop + back-compat
- Finalize public surface; `WalkthroughHostingController`; `LegacyItemAdapter`
  mapping old `[String:Any]` + `VXWalkthroughField` keys → typed steps so
  existing call sites migrate incrementally.
- Mark old symbols `@available(*, deprecated, message:)` where a shim exists.
- **Exit:** an existing app can adopt with minimal changes.

### Phase 7 — Demo, docs, release
- Rewrite `Demo/` as a SwiftUI multiplatform app (iOS + Catalyst); delete
  `.xib`/storyboard/`@UIApplicationMain`.
- Migrate `Localizable.strings` → **String Catalog** (`.xcstrings`).
- DocC documentation, update `README.md`, `CHANGELOG.md`, semantic version bump
  (major — breaking API).
- **Exit:** tagged release candidate, docs published.

---

## 5. Key decisions (made, revisit if needed)

1. **iOS 17 minimum** (per request). Drops iOS 16; unlocks Observation + scroll
   transitions without back-deployment shims.
2. **SPM-first; CocoaPods deprecated.** No `.podspec` currently exists; document
   SPM as the only supported channel.
3. **Zero required dependencies.** QR scanning isolated in an optional target via
   first-party AVFoundation/VisionKit (removes the `QRCodeReader.swift` fork).
4. **Keep the `VXWalkthrough` module name** for import compatibility; add a
   `VXWalkthroughUIKit` shim rather than breaking every call site at once.
5. **Storyboards/xibs removed entirely** in favor of SwiftUI.
6. **Swift Testing** (not XCTest) for new tests.

## 6. Open questions for the maintainer

- Confirm **iOS 17** floor (vs 18) — affects available SwiftUI APIs.
- Is the **`[String:Any]` legacy adapter** required, or can dependent apps move
  straight to the typed DSL? (Drives Phase 6 scope.)
- Which **permissions** must ship in v1 (notifications / camera / location / ATT)?
- Retain the **localized `walkthrough_0…n` auto-population** convention, or make
  the explicit DSL the only path?
- Branding/theme: adopt **iOS 26 Liquid Glass** chrome by default, or keep a
  neutral themeable look?

## 7. Risks & mitigations

| Risk | Mitigation |
| --- | --- |
| Breaking change for dependent apps | `VXWalkthroughUIKit` shim + `LegacyItemAdapter`; phased deprecations |
| Parallax fidelity vs UIKit `CATransform3D` | Recreate via `scrollTransition`; gate behind reduce-motion; visual QA |
| Catalyst-specific layout/permission quirks | Build + smoke test Catalyst every phase in CI |
| Scanner camera entitlements/privacy strings | Document required `Info.plist` keys; keep scanner optional |
| Scope creep across page types | Strict phase exit criteria; parity matrix as the contract |

---

## Appendix A — Files to remove/replace at completion

- `Sources/VXWalkthrough/*ViewController.swift` (all 6 UIKit controllers)
- `Sources/VXWalkthrough/Resources/VXWalkthroughViewController.storyboard`
- `Demo/` `.xib`s, `MainWindow.xib`, `AppDelegate` (`@UIApplicationMain`)
- `QRCodeReader.swift` package dependency
