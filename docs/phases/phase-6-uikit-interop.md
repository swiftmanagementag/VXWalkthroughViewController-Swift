# Phase 6 — UIKit Interop & Migration Guide

> Branch: `ios26_refactor`
> Status: In progress

## Objectives

- `WalkthroughHostingController` — a `UIHostingController` convenience that hosts
  a `WalkthroughView` for UIKit-based apps. iOS / Mac Catalyst only.
  - Convenience init taking a `Walkthrough`, optional `onFinish` (defaults to
    dismissing the controller), and a `configure` transform for applying extra
    modifiers (theme, custom pages, `.walkthroughQRScanner()`, etc.).
  - Defaults to full-screen modal presentation (legacy parity).
- `docs/migration-guide.md` — maps the legacy dictionary/delegate API to the new
  typed DSL, documenting the breaking changes.

## Risks / dependencies

- UIKit is unavailable on plain macOS. Mitigation: gate the controller with
  `#if canImport(UIKit)`; the target still compiles on macOS.

## Checklist

- [ ] `WalkthroughHostingController`.
- [ ] Migration guide doc.
- [ ] `swift build` green; iOS build of `VXWalkthroughUIKit` green.

## Acceptance criteria

- UIKit apps can present a walkthrough with a few lines via
  `WalkthroughHostingController`.
- The migration guide clearly shows old -> new for each legacy feature.
- iOS Simulator build of the interop target succeeds.
