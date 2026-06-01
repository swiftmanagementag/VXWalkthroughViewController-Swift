# ``VXWalkthrough``

A modern, declarative SwiftUI framework for app onboarding and walkthroughs.

## Overview

VXWalkthrough lets you describe an onboarding flow with a type-safe result
builder and render it with a single SwiftUI view. It supports displaying
information, collecting input, requesting permissions, and embedding your own
custom pages.

```swift
WalkthroughView(
    Walkthrough {
        InfoPage("welcome", title: "Welcome", image: .named("walkthrough_0"))
        LoginPage(scanEnabled: true)
        PermissionPage(.notifications, rationale: "Stay up to date")
        ActionPage("done", title: "All set!", buttonTitle: "Start")
    }
)
.actionHandler { action in /* ... */ .advance }
.onFinish { /* dismiss */ }
```

## Topics

### Building a walkthrough

- ``Walkthrough``
- ``WalkthroughBuilder``
- ``WalkthroughStep``
- ``StepKind``
- ``WalkthroughTheme``

### Pages

- ``InfoPage``
- ``InputPage``
- ``LoginPage``
- ``SignupPage``
- ``ActionPage``
- ``PickerPage``
- ``PermissionPage``
- ``CustomPage``

### Presenting & runtime

- ``WalkthroughView``
- ``WalkthroughModel``
- ``WalkthroughPageProxy``
- ``StepState``
- ``StepOutcome``
- ``WalkthroughAction``

### Permissions

- ``PermissionKind``
- ``PermissionRequesting``
- ``PermissionStatus``
- ``PermissionResolver``
- ``SystemPermissionRequester``

### Presentation gating & localization

- ``WalkthroughPresentationGate``
- ``KeyValueStore``
- ``LocalizedStepsLoader``
- ``AttributedTitle``
- ``Validation``
