# Phase 7 — Demo, Docs & Release

> Branch: `ios26_refactor`
> Status: In progress

## Objectives

- Rewrite `README.md` for the SwiftUI 2.0 API (features, install, usage,
  platforms, products).
- Add a DocC catalog for the `VXWalkthrough` target.
- Finalize the version: `VXWalkthrough.version = "2.0.0"`, stamp the CHANGELOG.
- Rewrite the `Demo/` app as a SwiftUI multiplatform sample using the new API;
  remove legacy UIKit/xib/storyboard files; migrate strings to a String Catalog.
- Full test suite green; iOS build of every product verified.

## Risks / dependencies

- The legacy demo Xcode project references xibs and a UIKit app delegate; the new
  SwiftUI sample needs the project updated to the SwiftUI lifecycle. Mitigation:
  regenerate a minimal SwiftUI app project referencing the local package, and
  verify with `xcodebuild`. If full project regeneration proves unreliable from
  the CLI, ship the demo as SwiftUI source + previews and document it (surfaced
  as a decision).

## Checklist

- [ ] Rewrite `README.md`.
- [ ] DocC catalog.
- [ ] Version bump + CHANGELOG stamp.
- [ ] SwiftUI demo sources + String Catalog; remove legacy demo files.
- [ ] Final `swift test`; iOS build of all products.

## Acceptance criteria

- README documents the SwiftUI API accurately.
- The package version is 2.0.0 and the CHANGELOG reflects the release.
- The full test suite passes; all products build for iOS Simulator.
