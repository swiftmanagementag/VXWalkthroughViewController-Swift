# Phase 10 — Configurable, cross-page-uniform circular images

## Objectives

1. Make the circular image style (`ImageStyle.round`) configurable via
   `WalkthroughTheme` (max diameter, margin, border, shadow).
2. Size the circle to the largest diameter that fits on the most-constrained
   page, applied uniformly across all pages, leaving margins.
3. Recalculate the diameter on rotation / container size change (the SwiftUI
   analogue of the legacy `viewDidLayoutSubviews` recompute).
4. Make `.round` responsive/larger by default (intentional visual change).

## Legacy reference (1.x)

From git history (commit `290e42d`, removed in the 2.0 rewrite):

- `VXWalkthroughPageViewController.viewDidLayoutSubviews()` recomputed
  `cornerRadius = imageView.frame.size.width / 2` (with `clipsToBounds`) on every
  layout pass, so rotation/size changes kept the image circular.
- The storyboard image view used `contentMode = scaleAspectFill`, a 1:1
  aspect-ratio constraint, was pinned to the leading/trailing margins (priority
  800) and centered. Border: white, 3pt. Shadow: gray, radius 6, opacity 0.5.

`CircleStyle` defaults mirror that look; recalculation is driven by
`GeometryReader` so any size change re-fires it.

## Approach

- `WalkthroughTheme.CircleStyle` (Sendable, Equatable): `maxDiameter: CGFloat?`,
  `margin: CGFloat`, `borderWidth: CGFloat`, `borderColor: Color`,
  `showsShadow: Bool`. New `circleStyle` property on the theme (defaulted).
- Pure `CircleSizing.diameter(minLeftoverHeight:width:style:)` =
  `min(minLeftoverHeight - 2*margin, width - 2*margin, maxDiameter ?? .infinity)`
  clamped to a minimum. Unit-testable; this is the cross-page "max that fits
  everywhere" logic.
- Measure **content**, not a greedy image slot. An early greedy-slot prototype
  pushed the title/body to the bottom of the screen (the slot won the flexible
  split against the centering `Spacer`s). Instead each page measures the height
  of its non-image content (title / body / controls) and reports it through a
  `PageContentHeightPreferenceKey` (reduce = **max** → the most-constrained
  page). Because the image is sized independently of that measurement, there is
  no layout feedback loop, and the normal centered `Spacer`-based layout is
  preserved.
- `WalkthroughContainer`: `GeometryReader` for container width/height; eager
  `HStack` (was `LazyHStack`) so all pages report up front;
  `.onPreferenceChange` + `.onChange(of: size)` derive
  `leftover = height - maxContentHeight - chromeReserve`, resolve the diameter
  (animated), and inject it via `environment(\.walkthroughResolvedCircleDiameter)`.
  `chromeReserve` keeps the page indicator / nav buttons clear.
- `InfoPageView` / `PageScaffold`: the image renders at the resolved fixed
  diameter inside the centered layout; the non-image content is wrapped in a
  group tagged `measureWalkthroughContentHeight()`.
- `WalkthroughImageView` `.round`: render at the resolved uniform diameter with
  configurable border/shadow from `CircleStyle` (fallback diameter when
  unmeasured).

## Checklist

- [ ] `WalkthroughTheme.CircleStyle` + `circleStyle` property.
- [ ] `CircleSizing` pure helper.
- [ ] Container: GeometryReader, eager HStack, preference key, inject diameter.
- [ ] InfoPageView + PageScaffold measured slots.
- [ ] `WalkthroughImageView.round` rendering.
- [ ] Rotation / size-change recalculation.
- [ ] `CircleSizingTests` (incl. rotation case) + extended `ImageStyleTests`.
- [ ] README + migration guide + CHANGELOG (2.2.0).

## Acceptance criteria

- The circular image is the largest that fits across all pages, leaving margins.
- Rotating the device / resizing the window (iPad multitasking, Catalyst)
  recomputes the diameter and the image stays circular.
- `CircleStyle` knobs (max diameter, margin, border, shadow) take effect.
- `swift test` green (traits off and on); iOS + Mac Catalyst builds green.

## Risks

- Eager `HStack` renders all pages up front (fine for small onboarding flows).
- Flexible image slot shifts vertical centering; tune margins/Spacers.
- Preference/measurement timing: slot measurement is independent of the circle
  diameter, avoiding layout cycles.
