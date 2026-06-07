# Migration Guide: VXWalkthrough 1.x (UIKit) -> 2.0 (SwiftUI)

VXWalkthrough 2.0 is a full SwiftUI rewrite. The UIKit view controllers,
storyboards, the `[String: Any]` configuration, the `VXWalkthroughField` keys,
and the `@objc` delegate are **removed**. This guide maps the old API to the new
one.

> [!IMPORTANT]
> **Upgrading 2.0 -> 2.1?** System permissions are now **opt-in**. If your flow
> includes a `PermissionPage`, you must add the `VXWalkthroughPermissions`
> product, enable the matching package **traits**, and inject
> `SystemPermissionRequester()`. See [Permissions](#7-permissions-opt-in-in-21).
> If you don't, permission pages simply advance (no prompt). The upside: apps
> without a `PermissionPage` no longer link Contacts/Photos/Location/Tracking
> and don't need unused purpose strings (fixes App Store ITMS-90683).

## 1. Defining a walkthrough

Before (dictionary + localized keys):

```swift
let walkthrough = VXWalkthroughViewController.create(delegate: self, backgroundColor: color)
walkthrough?.populate() // reads walkthrough_0, walkthrough_1, ...
var item = walkthrough?.createItem("ITWALKTHROUGH_LOGIN", item: [
    VXWalkthroughViewController.storyboardID: VXWalkthroughPageLoginViewController.storyboardID,
    VXWalkthroughField.loginPrompt: "Email",
    VXWalkthroughField.passwordPrompt: "Password",
])
item?[VXWalkthroughField.isScanEnabled] = true
walkthrough?.items["login"] = item
```

After (typed DSL):

```swift
let walkthrough = Walkthrough(theme: .default) {
    InfoPage("walkthrough_0", title: "See *No* Evil", image: .named("walkthrough_0"))
    LoginPage(loginPrompt: "Email", passwordPrompt: "Password", scanEnabled: true)
}
```

Localized auto-population is still available, opt-in:

```swift
let steps = LocalizedStepsLoader().load() // walkthrough_0...n
let walkthrough = Walkthrough(steps: steps)
```

## 2. Presenting

SwiftUI:

```swift
.sheet(isPresented: $show) {
    WalkthroughView(walkthrough)
        .onFinish { show = false }
}
```

UIKit (via the optional `VXWalkthroughUIKit` product):

```swift
import VXWalkthroughUIKit

let vc = WalkthroughHostingController(walkthrough)
present(vc, animated: true) // dismisses itself on finish by default
```

## 3. Delegate -> closures / async handler

| Legacy delegate method | New API |
| --- | --- |
| `walkthroughCloseButtonPressed(_:)` | `.onFinish { ... }` |
| `walkthroughPageDidChange(_:)` | `.onPageChange { index in ... }` |
| `walkthroughNextButtonPressed` / `PrevButtonPressed` | (handled internally; observe `onPageChange`) |
| `walkthroughActionButtonPressed(_:item:)` | `.actionHandler { action in ... }` returning a `StepOutcome`, or `.onAction { action in ... }` to observe |

Example login handling:

```swift
WalkthroughView(walkthrough)
    .actionHandler { action in
        if case let .login(creds) = action.payload {
            do { try await api.signIn(creds); return .success("Welcome!") }
            catch { return .failure("Could not sign in") }
        }
        return .advance
    }
```

`StepOutcome` drives the page: `.success`/`.successStay`/`.failure`/`.advance`/`.none`
replace the legacy `success`/`error` string keys.

## 4. Field keys -> typed specs

| Legacy `VXWalkthroughField` | New |
| --- | --- |
| `title`, `image` | `InfoPage(title:image:)`, `WalkthroughImage` |
| `loginPrompt`, `passwordPrompt`, `placeholderValue` | `LoginPage(loginPrompt:passwordPrompt:placeholder:)` |
| `emailPrompt` | `SignupPage(emailPrompt:)` |
| `buttonTitle` | per-page `buttonTitle:` |
| `options`, `pickerValue` | `PickerPage(options:selectedID:)` + `PickerOption` |
| `isScanEnabled` | `LoginPage(scanEnabled: true)` + `.walkthroughQRScanner()` |
| `success`, `error` | `StepOutcome` returned from the action handler |

## 5. "Shown once per version"

Before: `VXWalkthroughViewController.walkthroughShown()` / `setWalkthroughShown(_:)`.

After:

```swift
let gate = WalkthroughPresentationGate()
if gate.shouldPresent {
    show = true
    gate.setShown()
}
```

## 6. QR scanning

Add the `VXWalkthroughScanner` product and apply the modifier:

```swift
import VXWalkthroughScanner

WalkthroughView(walkthrough)        // LoginPage(scanEnabled: true)
    .walkthroughQRScanner()
```

Voucher URLs are parsed the same way as before (the `voucher` query item becomes
the field value).

## 7. Permissions (opt-in in 2.1)

Define the pages as before:

```swift
Walkthrough {
    PermissionPage(.notifications, rationale: "Stay up to date")
    PermissionPage(.camera, rationale: "Scan documents")
}
```

To actually prompt, opt into the system backends (since 2.1):

1. Enable the traits you need on the package dependency:

```swift
.package(
    url: "https://github.com/swiftmanagementag/VXWalkthroughViewController-Swift",
    .upToNextMajor(from: "2.1.0"),
    traits: ["PermissionsNotifications", "PermissionsCamera"]
)
```

2. Add the `VXWalkthroughPermissions` product to your target and inject the
   requester:

```swift
import VXWalkthroughPermissions

WalkthroughView(walkthrough)
    .walkthroughPermissionRequester(SystemPermissionRequester())
```

3. Add `NS…UsageDescription` keys to `Info.plist` **only for the traits you
   enable**.

Available traits (default: none): `PermissionsNotifications`,
`PermissionsCamera`, `PermissionsMicrophone`, `PermissionsPhotos`,
`PermissionsLocation`, `PermissionsContacts`, `PermissionsTracking`.

Without a requester (or for a kind whose trait is off), a `PermissionPage`
resolves to `.advance` and skips itself. You can still inject a custom
requester conforming to `PermissionRequesting` for testing/analytics with
`.walkthroughPermissionRequester(_:)` without the permissions product.

## 8. Theming

```swift
let theme = WalkthroughTheme(background: .black, accent: .blue, imageStyle: .round)
Walkthrough(theme: theme) { ... }
```

Image styles: `.round` (default), `.card`, `.fullBleed`, and `.fit`
(full-width, aspect-fit — shows wide artwork without cropping, added in 2.1).

As of 2.2, `.round` sizes the circle responsively — the largest diameter that
fits across all pages, recalculated on rotation/resize. Tune the cap and chrome
with `CircleStyle`:

```swift
let theme = WalkthroughTheme(
    imageStyle: .round,
    circleStyle: .init(maxDiameter: 320, margin: 24, borderWidth: 3,
                       borderColor: .white, showsShadow: true)
)
```

As of 2.3, the theme also exposes the CTA, page-control dots, and nav controls,
so they keep contrast on a branded background (all optional, defaulting to the
prior look):

```swift
let theme = WalkthroughTheme(
    background: brandCyan,
    titleColor: .black,
    actionButtonStyle: .init(background: .black, foreground: .white, cornerStyle: .capsule),
    pageIndicatorColor: .black.opacity(0.3),
    pageIndicatorSelectedColor: .black,
    navControlTint: .black
)
```

A single step can override the theme with the optional `theme:` parameter on any
page (e.g. `ActionPage("cta", ..., theme: highContrastTheme)`); the overlaid
page chrome and circle sizing still follow the base theme.

## 9. Custom pages

```swift
Walkthrough {
    CustomPage("promo")
}
// ...
WalkthroughView(walkthrough)
    .walkthroughCustomPage("promo") { proxy in
        MyPromoView(onContinue: proxy.advance)
    }
```

A custom page can also drive navigation through the environment instead of a
captured proxy:

```swift
struct MyPromoView: View {
    @Environment(\.walkthroughAdvance) private var advance
    var body: some View {
        Button("Continue") { advance() }   // advance() / advance.previous() / advance.finish()
    }
}
```
