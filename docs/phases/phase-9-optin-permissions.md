# Phase 9 — Opt-in permissions (product + traits) and aspect-fit images

## Objectives

1. Stop the core `VXWalkthrough` product from referencing privacy-sensitive
   system APIs (Contacts, Photos, Location, Tracking, Microphone, Camera) so
   apps that do not use `PermissionPage` are not forced to declare unused
   purpose strings (App Store ITMS-90683).
2. Let consumers link only the permission backends they use, with per-kind
   granularity.
3. Render wide illustrations un-cropped via a new aspect-fit `ImageStyle`.

## Decisions (confirmed)

- **Hybrid** approach: a separate optional `VXWalkthroughPermissions` product
  **and** SwiftPM **traits** per `PermissionKind` inside it (Swift 6.1+).
- Supported image formats unchanged (png/jpg/jpeg); loose-image loading already
  shipped in Phase 8. This phase only adds the aspect-fit content mode.
- Target release **2.1.0** with a documented migration (effectively breaking for
  current `PermissionPage` users).

## Approach

### Core stays clean

- New `NoopPermissionRequester` (returns `.unavailable` for every kind) becomes
  the `walkthroughPermissionRequester` environment default. `.unavailable`
  already maps to `.advance` in `PermissionResolver`, so a `PermissionPage` with
  no injected requester degrades gracefully (advances).
- `SystemPermissionRequester` is removed from core. The protocol, status,
  resolver, `PermissionKind`, `PermissionSpec`, `PermissionPage`, and
  `PermissionPageView` remain in core. Core imports none of UserNotifications /
  AVFoundation / Photos / Contacts / CoreLocation / AppTrackingTransparency.

### VXWalkthroughPermissions (traits-gated)

- Hosts `SystemPermissionRequester`, split so each backend compiles only under
  its trait: `PermissionsNotifications`, `PermissionsCamera`,
  `PermissionsMicrophone`, `PermissionsPhotos`, `PermissionsLocation`,
  `PermissionsContacts`, `PermissionsTracking` (default: none enabled).
- Kinds whose trait is disabled (and all kinds on non-iOS) return
  `.unavailable`.

### Aspect-fit images

- Add additive `WalkthroughTheme.ImageStyle.fit` (full-width, aspect-fit, no
  clipping/crop). Existing `.round` / `.card` / `.fullBleed` unchanged.

## Consumer usage

```swift
// Package.swift
.package(url: "…/VXWalkthroughViewController-Swift", from: "2.1.0",
         traits: ["PermissionsNotifications", "PermissionsCamera"])

// app
import VXWalkthroughPermissions
WalkthroughView(walkthrough)
    .walkthroughPermissionRequester(SystemPermissionRequester())
```

## Risks / dependencies

- Requires `swift-tools-version: 6.1`. Toolchain confirmed (Swift 6.3).
- Trait selection in `.xcodeproj` consumers can be fiddly; the demo therefore
  injects a tiny inline notifications requester instead of depending on the
  permissions product, keeping the demo build trait-free and CI green.
- Behavioral change for current `PermissionPage` users (documented migration).

## Checklist

- [ ] Package: tools-version 6.1, traits, `VXWalkthroughPermissions`
      target/product + test target.
- [ ] Core: `NoopPermissionRequester` + env default; remove
      `SystemPermissionRequester`; core references no permission frameworks.
- [ ] Permissions product: trait-gated `SystemPermissionRequester`.
- [ ] `ImageStyle.fit` + content-mode routing in `WalkthroughImageView`.
- [ ] Tests (core no-op/resolver, permissions traits-enabled, image fit).
- [ ] CI: default + traits-enabled build/test + core-clean source guard.
- [ ] Demo + README + migration guide + CHANGELOG (2.1.0).

## Acceptance criteria

- An app linking `VXWalkthrough` + `VXWalkthroughScanner` (camera only), not
  using `PermissionPage`, references no Contacts/Photos/Location/Tracking/
  Microphone APIs and needs only a camera usage string.
- Enabling a single trait links only that framework.
- A loose bundle PNG renders via `.named` with `.fit`, un-cropped.
- `swift test` green with traits off and on; iOS + Mac Catalyst builds green.
