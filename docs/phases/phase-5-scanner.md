# Phase 5 — Optional Scanner Module

> Branch: `ios26_refactor`
> Status: In progress

## Objectives

- `VXWalkthroughScanner` target provides QR/barcode scanning that integrates with
  the core via the `walkthroughScanHandler` environment hook.
- `ScanResultParser` — pure, testable parsing of scanned strings, preserving the
  legacy behavior of extracting a `voucher` query item from URL payloads (and a
  `teacher` value).
- `QRScannerView` — AVFoundation (`AVCaptureMetadataOutput`) based scanner
  (`UIViewControllerRepresentable`), iOS / Catalyst only.
- `.walkthroughQRScanner()` view modifier that presents the scanner in a sheet
  and bridges the result to the async scan handler via a continuation.
- Core builds without this target; linking it adds scanning.

## Risks / dependencies

- Camera APIs cannot run headlessly. Mitigation: keep parsing pure/testable;
  gate camera UI behind `#if os(iOS)`; non-iOS shows an unsupported sheet.
- Continuation bridging for async presentation. Mitigation: a `@MainActor`
  coordinator owning a single continuation.

## Checklist

- [ ] Add `VXWalkthroughScannerTests` target to `Package.swift`.
- [ ] `ScanResultParser` (pure).
- [ ] `WalkthroughScannerCoordinator` (async scan via continuation).
- [ ] `QRScannerView` (AVFoundation, iOS).
- [ ] `.walkthroughQRScanner()` modifier.
- [ ] Tests for `ScanResultParser`.
- [ ] `swift build` + `swift test` + iOS build green.

## Acceptance criteria

- `ScanResultParser` extracts voucher/teacher from URL payloads and passes
  plain codes through unchanged.
- The core compiles and tests without the scanner; the scanner target compiles
  for iOS and macOS (camera UI gated to iOS).
