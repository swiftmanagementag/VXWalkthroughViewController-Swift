# Phase 8 — Legacy loose-image fallback

## Objective

Make `WalkthroughImage.named(_:)` resolve from **loose image files** (`.png`,
`.jpg`, `.jpeg`) shipped in a bundle, as a fallback when no asset-catalog entry
exists. This restores compatibility with legacy projects that ship the
`walkthrough_0…n` art (and similar) as loose files rather than in an
`Assets.xcassets` catalog.

## Background

- SwiftUI's `Image(_:bundle:)` resolves names **only through compiled asset
  catalogs**; it never finds a loose `walkthrough_0.png` in a bundle.
- UIKit's `UIImage(named:in:compatibleWith:)` (and AppKit's
  `Bundle.image(forResource:)`) search **both** catalogs and loose files, with
  `@2x`/`@3x` scale and `~ipad` idiom handling.
- Today `WalkthroughImageView` renders `.named` with `Image(name)` (no bundle),
  so loose-file projects render blank.

## Decisions (confirmed)

1. **Search order — app bundle has precedence:** `configured bundle (if any)` →
   `Bundle.main` → `VXWalkthrough.resourceBundle (.module)`.
2. **Supported loose formats:** `png`, `jpg`, `jpeg` only.

## Approach

Add a `@MainActor` `WalkthroughImageLoader` that resolves a name through an
ordered bundle cascade. For each bundle:

1. **Named lookup** — `UIImage(named:in:compatibleWith:)` (UIKit) /
   `Bundle.image(forResource:)` (AppKit). Covers catalogs *and*, on UIKit, loose
   files with scale/idiom.
2. **Explicit loose-file lookup** — `bundle.url(forResource:withExtension:)`
   over `{name, name@2x, name@3x, name~ipad[...]}` × `{png, jpg, jpeg}`, loaded
   via `UIImage(contentsOfFile:)` / `NSImage(contentsOf:)`.
3. Miss → `nil` → `Color.clear` (unchanged layout behavior).

Results are memoized in an `NSCache` keyed by bundle-order + name.

### API (additive, non-breaking)

- `EnvironmentValues.walkthroughImageBundle: Bundle?` + `View.walkthroughImageBundle(_:)`
  to prepend a host-provided bundle (e.g. `.main` or a resource bundle).
- `WalkthroughPlatformImage` typealias (`UIImage`/`NSImage`).
- Zero-config default already searches `Bundle.main` then `.module`, so most
  legacy apps need no changes.

## Risks / dependencies

- `UIImage`/`NSImage` are non-`Sendable`; resolution stays on `@MainActor`
  (view layer). Models remain `Sendable` — no `WalkthroughStep` changes.
- Behavioral change: previously-blank loose-image pages now render. Intended;
  noted in CHANGELOG.
- Catalog images keep precedence within each bundle (named lookup runs first),
  so existing apps are unaffected.

## Checklist

- [ ] `WalkthroughPlatformImage` typealias + `WalkthroughImageLoader` (cascade,
      candidate matrix, `NSCache`).
- [ ] `\.walkthroughImageBundle` environment key + `View.walkthroughImageBundle(_:)`.
- [ ] Rewire `WalkthroughImageView.named` to the loader (fallback `Color.clear`).
- [ ] Unit tests against a fixture bundle with loose `.png`/`.jpg` (incl. an
      `@2x`-only name and a miss) + bundle-order test.
- [ ] CHANGELOG entry (Unreleased).
- [ ] README/migration note for legacy loose-image projects.

## Acceptance criteria

- `.named("walkthrough_0")` backed by a loose PNG renders on iOS, iPadOS, and
  Mac Catalyst (and macOS where applicable).
- Asset-catalog, `.system`, `.remote`, and `.none` behavior unchanged.
- App (`main`) bundle resolves before the library `.module` bundle.
- `swift test` green (incl. new loader tests); no Swift 6 / `Sendable`
  regressions.
