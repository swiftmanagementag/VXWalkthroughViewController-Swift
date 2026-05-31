# Migration Guide: VXWalkthrough 1.x (UIKit) -> 2.0 (SwiftUI)

VXWalkthrough 2.0 is a full SwiftUI rewrite. The UIKit view controllers,
storyboards, the `[String: Any]` configuration, the `VXWalkthroughField` keys,
and the `@objc` delegate are **removed**. This guide maps the old API to the new
one.

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

## 7. Permissions (new)

```swift
Walkthrough {
    PermissionPage(.notifications, rationale: "Stay up to date")
    PermissionPage(.camera, rationale: "Scan documents")
}
```

Inject a custom requester for testing/analytics with
`.walkthroughPermissionRequester(_:)`.

## 8. Theming

```swift
let theme = WalkthroughTheme(background: .black, accent: .blue, imageStyle: .round)
Walkthrough(theme: theme) { ... }
```

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
