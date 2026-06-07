# Changelog

All notable changes to VXWalkthrough are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.3.0] - 2026-06-07

### Added

- **Theme: full chrome theming.** `WalkthroughTheme` gains optional
  `actionButtonStyle` (a new `WalkthroughButtonStyle` of `background` /
  `foreground` / `cornerStyle`), `pageIndicatorColor`,
  `pageIndicatorSelectedColor`, and `navControlTint`. These let the host
  guarantee adequate contrast for the primary CTA, page-control dots, and the
  Next / Previous / Close controls against a branded background. All default to
  `nil`, preserving the prior look (button filled with `accent` + white label,
  indicator/nav derived from `titleColor`).
- **LoginSpec / LoginPage: per-field control.** New `loginPlaceholder` and
  `passwordPlaceholder` (each falling back to the shared `placeholder`),
  `loginSecure` (default `false`) and `passwordSecure` (default `true`) secure-
  entry toggles, and an optional `scanTitle` that gives the scan button a visible
  label (icon-only when unset).
- **ActionSpec / ActionPage: themed button.** The action button now honors the
  theme's `actionButtonStyle`, and an optional per-step `buttonStyle` override is
  available on `ActionSpec` / `ActionPage`.
- **Custom pages: `walkthroughAdvance` hook.** A new
  `@Environment(\.walkthroughAdvance)` action (`advance()` / `previous()` /
  `finish()`, callable directly) lets a custom page drive navigation without
  threading the page proxy through subviews.
- **Per-step theme override.** Every DSL page (and `WalkthroughStep`) accepts an
  optional `theme:` that overrides the walkthrough theme for that page's content
  (background, title/body colors + fonts, button). The overlaid page chrome
  (indicator / nav) and cross-page circle sizing still use the base theme.

All additions are optional and defaulted: re-pinning to 2.3.0 is a drop-in with
zero behavior change until opted in.

## [2.2.2] - 2026-06-01

### Fixed

- The terminal success/failure state message on interactive pages now renders
  inline markup (`*…*` / `<b>…</b>`) as bold, consistent with page titles.
  Previously the message was shown as plain text, so markup appeared as literal
  tags. Additive, no API change.

## [2.2.1] - 2026-06-01

### Fixed

- Walkthrough content was misaligned after a device rotation or window resize
  (iPad multitasking, Mac Catalyst). The pager now spans the full width so pages
  snap edge-to-edge (previously the horizontal safe-area inset made pages
  narrower than the viewport, leaving a sliver of the adjacent page in
  landscape), and it re-snaps to the current page when the width changes.

## [2.2.0] - 2026-06-01

### Added

- Configurable circular images for `ImageStyle.round`. A new
  `WalkthroughTheme.CircleStyle` (`maxDiameter`, `margin`, `borderWidth`,
  `borderColor`, `showsShadow`) controls the circle's size cap and chrome, set
  via the new `WalkthroughTheme(circleStyle:)` parameter.

### Changed

- `ImageStyle.round` now sizes the circle responsively: the diameter is the
  largest that fits across **every** page (leaving a margin), applied uniformly,
  and recalculated on rotation / window resize (iPad multitasking, Mac Catalyst).
  Previously circles were a fixed 160pt. Existing apps get larger, responsive
  circles automatically; cap them with `circleStyle.maxDiameter` to restore a
  smaller fixed feel.

## [2.1.1] - 2026-06-01

### Changed

- `ImageStyle.fit` now renders the full-width, aspect-fit image with rounded
  corners (16pt), restoring the pre-2.x full-width look. No app-side change
  required.

## [2.1.0] - 2026-06-01

### Breaking changes

> [!WARNING]
> System permissions are now **opt-in**. Apps that present a `PermissionPage`
> must add the new `VXWalkthroughPermissions` product, enable the relevant
> package **traits**, and inject `SystemPermissionRequester()`. Without this,
> permission pages resolve to `.advance` (they skip themselves) rather than
> prompting. See [docs/migration-guide.md](docs/migration-guide.md).

- **`SystemPermissionRequester` moved out of the core product** into the new
  optional `VXWalkthroughPermissions` product. The core `VXWalkthrough` product
  no longer references UserNotifications / AVFoundation / Photos / Contacts /
  CoreLocation / AppTrackingTransparency, so apps that don't request permissions
  are no longer forced to declare unused purpose strings (fixes App Store
  rejection **ITMS-90683**).
- The `walkthroughPermissionRequester` environment default is now
  `NoopPermissionRequester` (reports every kind as `.unavailable`, which the
  resolver maps to `.advance`).
- Minimum tools version raised to **Swift 6.1** (required for package traits).

### Added

- **`VXWalkthroughPermissions` product** with per-`PermissionKind` SwiftPM
  **traits** (default: none): `PermissionsNotifications`, `PermissionsCamera`,
  `PermissionsMicrophone`, `PermissionsPhotos`, `PermissionsLocation`,
  `PermissionsContacts`, `PermissionsTracking`. Enabling a trait links only that
  framework; disabled kinds (and all kinds on non-iOS) return `.unavailable`.
- **`NoopPermissionRequester`** in core as the no-frameworks default.
- **`ImageStyle.fit`** — a full-width, aspect-fit image style that renders wide
  artwork without cropping. Additive; existing `.round`/`.card`/`.fullBleed`
  styles are unchanged.

### Added (previously unreleased)

- **Legacy loose-image fallback.** `WalkthroughImage.named(_:)` now resolves
  from loose `.png`/`.jpg`/`.jpeg` files in a bundle when no asset-catalog entry
  exists, restoring compatibility with projects that ship `walkthrough_0…n` art
  as loose files. Resolution searches the host app bundle before the library
  bundle (`preferred → Bundle.main → .module`). Use
  `.walkthroughImageBundle(_:)` to point at a custom resource bundle. This is
  additive and non-breaking — asset-catalog images are unaffected.

## [2.0.0] - 2026-05-31

This release is a full rewrite of the framework from UIKit + Storyboards to a
declarative SwiftUI framework targeting Swift 6. See
[docs/ios26-refactor-plan.md](docs/ios26-refactor-plan.md) for the design and
migration plan and [docs/migration-guide.md](docs/migration-guide.md) for the
1.x -> 2.0 migration guide.

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
