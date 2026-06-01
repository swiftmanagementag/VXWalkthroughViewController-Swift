# Phase 0 — Tooling & Package Skeleton

> Branch: `ios26_refactor`
> Status: In progress

## Objectives

- Move the package to `swift-tools-version: 6.0` with Swift 6 language mode.
- Declare platforms: iOS 17, Mac Catalyst 17, and macOS 14 (the last solely to
  enable fast `swift test` / CI on the command line; the shipping product remains
  iOS/iPadOS/Catalyst).
- Restructure into targets:
  - `VXWalkthrough` — core SwiftUI framework, zero external dependencies.
  - `VXWalkthroughScanner` — optional, iOS-only QR scanner (added as an empty
    skeleton in Phase 0, implemented in Phase 5).
  - `VXWalkthroughUIKit` — optional UIKit interop (skeleton in Phase 0,
    implemented in Phase 6).
  - `VXWalkthroughTests` — Swift Testing unit tests.
- Remove the `QRCodeReader.swift` dependency.
- Remove the legacy UIKit controllers and storyboard (preserved in git history
  and on `master`) so the package builds clean under Swift 6.
- Add a minimal GitHub Actions CI workflow (build + test).

## Risks / dependencies

- Removing all legacy sources means the package has no buildable code until the
  skeleton compiles. Mitigation: add a tiny placeholder in each target so the
  build is green at the end of Phase 0.
- `PageTabViewStyle` is iOS-only; the renderer (Phase 2) will use a custom
  `ScrollView`-based pager so the core builds on macOS for testing.
- ATT / camera / VisionKit APIs are iOS-only; isolate them behind
  `#if os(iOS)` / `#if canImport(...)` and in the scanner target.

## Checklist

- [ ] Rewrite `Package.swift` (tools 6.0, platforms, 4 targets, Swift 6 mode, no deps).
- [ ] Delete legacy sources: 6 UIKit controllers + `Resources/*.storyboard`.
- [ ] Remove `QRCodeReader` from dependencies; delete `Package.resolved` pin.
- [ ] Add skeleton files so each target compiles:
  - `Sources/VXWalkthrough/VXWalkthrough.swift` (module marker + version).
  - `Sources/VXWalkthroughScanner/VXWalkthroughScanner.swift` (placeholder).
  - `Sources/VXWalkthroughUIKit/VXWalkthroughUIKit.swift` (placeholder).
  - `Tests/VXWalkthroughTests/SmokeTests.swift` (one passing test).
- [ ] Keep the existing image assets in `Resources/` (re-used by SwiftUI later).
- [ ] Add `.github/workflows/ci.yml` (swift build + test on macOS runner).
- [ ] `swift build` and `swift test` succeed.

## Acceptance criteria

- `swift build` succeeds on macOS with no external dependencies resolved.
- `swift test` runs and the smoke test passes.
- No `import` of `QRCodeReader` remains; no `.storyboard`/legacy controller files
  remain in `Sources/`.
