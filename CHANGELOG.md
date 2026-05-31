# Changelog

All notable changes to VXWalkthrough are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

This release is a full rewrite of the framework from UIKit + Storyboards to a
declarative SwiftUI framework targeting Swift 6. See
[docs/ios26-refactor-plan.md](docs/ios26-refactor-plan.md) for the design and
migration plan. A dedicated migration guide will accompany the final release.

### Breaking changes

> [!WARNING]
> This is a major version with a redesigned public API. Apps on the previous
> UIKit-based releases must migrate to the new SwiftUI DSL; there is no runtime
> compatibility shim for the old dictionary-based configuration.

- **Rewritten in SwiftUI.** The library is now a declarative SwiftUI framework.
  All UIKit view controllers and the `VXWalkthroughViewController.storyboard`
  are removed.
- **Removed `[String: Any]` configuration and `VXWalkthroughField` keys.**
  Walkthroughs are now defined with the type-safe `Walkthrough { … }` result
  builder DSL and strongly-typed, `Sendable` `WalkthroughStep` models. There is
  no `[String: Any]` back-compat adapter — dependent apps migrate to the DSL.
- **Removed the `@objc VXWalkthroughViewControllerDelegate` protocol.** Page
  events and actions are now surfaced via `async`/`throws` closures and SwiftUI
  callbacks (`onFinish`, `onPageChange`, `onAction`).
- **Raised minimum deployment target to iOS 17 / iPadOS 17 / Mac Catalyst 17**
  (was iOS 16 / Catalyst 14). Built against the iOS 26 SDK; iOS 26 features
  (Liquid Glass) are adopted behind availability checks with iOS 17 fallbacks.
- **Removed the `QRCodeReader.swift` dependency.** The core framework now has
  zero required dependencies; QR scanning moves to an optional
  `VXWalkthroughScanner` target built on AVFoundation/VisionKit.
- **UIKit interop is now opt-in** via the separate `VXWalkthroughUIKit` target
  (`WalkthroughHostingController`).

### Added

- Swift 6 language mode with full strict-concurrency compliance.
- `@Observable` `WalkthroughModel` and per-step `StepState`
  (`idle`/`loading`/`success`/`error`).
- Built-in page types: info, input, login, signup, action, picker, and
  permission.
- Full permission request set: notifications, camera, microphone, photo
  library, location, contacts, and App Tracking Transparency.
- Themeable chrome via `WalkthroughTheme`, including optional iOS 26 Liquid
  Glass styling.
- Host extensibility: inject custom SwiftUI pages conforming to
  `WalkthroughPage`.

### Retained

- Opt-in localized `walkthrough_0…n` auto-population (parity with the previous
  `populate()` behavior) via `LocalizedStepsLoader`.
- "Shown once per app version" presentation gate (parity with
  `walkthroughShown()`), now injectable via `WalkthroughPresentationGate`.

## [1.0.17]

- Minor fixes for iOS 13.

## [1.0.16]

- Added task-specific page view controllers (login, signup, action, picker).
- Added option to scan a QR code on the login page.

## [1.0.15]

- Fix for iOS 11.

## [1.0.12]

- Better handling of startup in different orientations.
- Locking of rotations once started to prevent display issues.
- Recompiled and fixed warnings under Xcode 7.2.1.

## [1.0.11]

- Option to control and dynamically modify the population of tutorial screens.

## [1.0.10]

- Option of using fullscreen images (`roundImages = NO`).
